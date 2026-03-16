-- =============================================================================
-- Module: test_rest_empl_terr.4gl
-- Purpose: REST client to test the rest_empl_terr web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_empl_terr.42m
-- Server: Expects REST server running at http://localhost:8899
-- Note:   This is a junction table — no UPDATE endpoint
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_empl_terr RECORD
   employeeid           STRING,
   fullname             STRING,
   territoryid          STRING,
   territorydescription STRING,
   regiondescription    STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/empt/employee-territories"
   END IF
   CALL test_rest_lib.init_test_suite("REST Employee Territories Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_by_employee()
   CALL test_get_not_found()

   -- Create/Delete tests (no update for junction table)
   CALL test_create_empl_terr()
   CALL test_delete_empl_terr()
   CALL test_full_lifecycle()

   -- Negative/error tests last
   CALL test_delete_not_found()
   CALL test_create_duplicate()
   CALL test_create_missing_fields()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Test: GET /employee-territories — returns a list of all assignments
-- =============================================================================
FUNCTION test_get_all()
   DEFINE records DYNAMIC ARRAY OF t_empl_terr
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /employee-territories (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, records)
   CATCH
      CALL test_rest_lib.test_fail("Failed to parse JSON response")
      RETURN
   END TRY

   IF records.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one assignment, got 0")
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM employeeterritories
   IF db_count != records.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 records but DB has %2",
         records.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 employee-territory assignments (matches DB)", records.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /employee-territories/{empid}/{terrid} — returns a single assignment
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE rec t_empl_terr
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /employee-territories/1/06897 (get by composite ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/1/06897", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, rec)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF rec.employeeid IS NULL OR rec.employeeid.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("employeeid is NULL/empty")
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM employeeterritories
      WHERE employeeid = 1 AND territoryid = "06897"
   IF db_count = 0 THEN
      CALL test_rest_lib.test_fail("Assignment 1/06897 not found in database")
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got assignment: emp=%1 terr=%2 (matches DB)", rec.employeeid, rec.territoryid))
END FUNCTION

-- =============================================================================
-- Test: GET /employee-territories/employee/{empid} — returns all for an employee
-- =============================================================================
FUNCTION test_get_by_employee()
   DEFINE records DYNAMIC ARRAY OF t_empl_terr
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /employee-territories/employee/1 (get by employee) ..."

   CALL test_rest_lib.http_get(SFMT("%1/employee/1", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, records)
   CATCH
      CALL test_rest_lib.test_fail("Failed to parse JSON response")
      RETURN
   END TRY

   IF records.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one territory for employee 1")
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM employeeterritories WHERE employeeid = 1
   IF db_count != records.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 territories for emp 1 but DB has %2",
         records.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 territories for employee 1 (matches DB)", records.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /employee-territories/{empid}/{terrid} — 404 for non-existent
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /employee-territories/99999/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999/ZZZZZ", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /employee-territories — create a new assignment
-- We need a territory that employee 1 is NOT already assigned to.
-- First create a temp territory, then assign employee 1 to it.
-- =============================================================================
FUNCTION test_create_empl_terr()
   DEFINE new_rec t_empl_terr
   DEFINE created_rec t_empl_terr
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: POST /employee-territories (create) ..."

   -- Create a temp territory
   LET json_body = '{"territoryid":"TSTET","territorydescription":"Test ET Territory","regionid":1}'
   CALL test_rest_lib.http_post("http://localhost:8899/terr/territories", json_body)
      RETURNING status_code, response_body
   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create temp territory, status=%1", status_code))
      RETURN
   END IF

   -- Create the assignment
   LET new_rec.employeeid = "1"
   LET new_rec.territoryid = "TSTET"
   LET json_body = '{"employeeid":1,"territoryid":"TSTET"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/TSTET")
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_rec)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/1/TSTET", m_base_url))
         RETURNING status_code, response_body
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/TSTET")
         RETURNING status_code, response_body
      RETURN
   END TRY

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM employeeterritories
      WHERE employeeid = 1 AND territoryid = "TSTET"
   IF db_count = 0 THEN
      CALL test_rest_lib.test_fail("Created assignment not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/1/TSTET", m_base_url))
         RETURNING status_code, response_body
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/TSTET")
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up: delete assignment then territory
   CALL test_rest_lib.http_delete(SFMT("%1/1/TSTET", m_base_url))
      RETURNING status_code, response_body
   CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/TSTET")
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Created assignment 1/TSTET, verified in DB, cleaned up")
END FUNCTION

-- =============================================================================
-- Test: POST /employee-territories — 400 for duplicate assignment
-- =============================================================================
FUNCTION test_create_duplicate()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: POST /employee-territories (duplicate) ..."

   -- Try to create an assignment that already exists (1/06897)
   LET json_body = '{"employeeid":1,"territoryid":"06897"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         -- Clean up if somehow created
         CALL test_rest_lib.http_delete(SFMT("%1/1/06897", m_base_url))
            RETURNING status_code, response_body
      END IF
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 for duplicate, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 400 for duplicate assignment as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /employee-territories — 400 for missing fields
-- =============================================================================
FUNCTION test_create_missing_fields()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: POST /employee-territories (invalid - missing fields) ..."

   LET json_body = '{"employeeid":0,"territoryid":""}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 400 validation error as expected")
END FUNCTION

-- =============================================================================
-- Test: DELETE /employee-territories/{empid}/{terrid} — delete an assignment
-- =============================================================================
FUNCTION test_delete_empl_terr()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /employee-territories/{empid}/{terrid} (delete) ..."

   -- Create a temp territory
   LET json_body = '{"territoryid":"DELET","territorydescription":"Delete ET Territory","regionid":1}'
   CALL test_rest_lib.http_post("http://localhost:8899/terr/territories", json_body)
      RETURNING status_code, response_body
   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create temp territory, status=%1", status_code))
      RETURN
   END IF

   -- Create an assignment to delete
   LET json_body = '{"employeeid":1,"territoryid":"DELET"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create assignment, status=%1", status_code))
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/DELET")
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Delete the assignment
   CALL test_rest_lib.http_delete(SFMT("%1/1/DELET", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/DELET")
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/1/DELET", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/DELET")
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM employeeterritories
      WHERE employeeid = 1 AND territoryid = "DELET"
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Assignment still exists in DB after delete")
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/DELET")
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up territory
   CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/DELET")
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Deleted assignment 1/DELET, verified 404 and gone from DB")
END FUNCTION

-- =============================================================================
-- Test: DELETE /employee-territories/{empid}/{terrid} — 404 for non-existent
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /employee-territories/99999/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_delete(SFMT("%1/99999/ZZZZZ", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: Full lifecycle — create territory, assign, read, delete, verify gone
-- =============================================================================
FUNCTION test_full_lifecycle()
   DEFINE rec t_empl_terr
   DEFINE verified t_empl_terr
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full Create-Read-Delete lifecycle ..."

   -- 0. Create a temp territory
   LET json_body = '{"territoryid":"LFCET","territorydescription":"Lifecycle ET Territory","regionid":1}'
   CALL test_rest_lib.http_post("http://localhost:8899/terr/territories", json_body)
      RETURNING status_code, response_body
   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create temp territory, status=%1", status_code))
      RETURN
   END IF

   -- 1. CREATE assignment
   LET rec.employeeid = "1"
   LET rec.territoryid = "LFCET"
   LET json_body = '{"employeeid":1,"territoryid":"LFCET"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/LFCET")
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, rec)

   -- DB validation: verify created
   SELECT COUNT(*) INTO db_count FROM employeeterritories
      WHERE employeeid = 1 AND territoryid = "LFCET"
   IF db_count = 0 THEN
      CALL test_rest_lib.test_fail("Created assignment not found in DB")
      CALL test_rest_lib.http_delete(SFMT("%1/1/LFCET", m_base_url))
         RETURNING status_code, response_body
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/LFCET")
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 2. READ — verify it exists
   CALL test_rest_lib.http_get(SFMT("%1/1/LFCET", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after CREATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/1/LFCET", m_base_url))
         RETURNING status_code, response_body
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/LFCET")
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)

   -- 3. DELETE
   CALL test_rest_lib.http_delete(SFMT("%1/1/LFCET", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("DELETE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/LFCET")
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 4. READ — verify it's gone
   CALL test_rest_lib.http_get(SFMT("%1/1/LFCET", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After DELETE, expected 404, got %1", status_code))
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/LFCET")
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify gone
   SELECT COUNT(*) INTO db_count FROM employeeterritories
      WHERE employeeid = 1 AND territoryid = "LFCET"
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Assignment still in DB after delete")
      CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/LFCET")
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up territory
   CALL test_rest_lib.http_delete("http://localhost:8899/terr/territories/LFCET")
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Full lifecycle passed for 1/LFCET (all DB checks passed)")
END FUNCTION
