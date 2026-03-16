-- =============================================================================
-- Module: test_rest_cust_demo.4gl
-- Purpose: REST client to test the rest_cust_demo web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_cust_demo.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_cust_demo RECORD
   customertypeid STRING,
   customerdesc   STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/demo/customer-demographics"
   END IF
   CALL test_rest_lib.init_test_suite("REST Customer Demographics Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_cust_demo()
   CALL test_update_cust_demo()
   CALL test_delete_cust_demo()
   CALL test_full_lifecycle()

   -- Negative/error tests last
   CALL test_update_not_found()
   CALL test_delete_not_found()
   CALL test_create_missing_fields()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Test: GET /customer-demographics — returns a list
-- =============================================================================
FUNCTION test_get_all()
   DEFINE demos DYNAMIC ARRAY OF t_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /customer-demographics (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, demos)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM customerdemographics
   IF db_count != demos.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 records but DB has %2",
         demos.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 customer demographics (matches DB)", demos.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /customer-demographics/{id} — returns a single record
-- We need to create one first since the table may be empty
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE demo t_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: GET /customer-demographics/{id} (get by ID) ..."

   -- Create a record to look up
   LET demo.customertypeid = "GETID"
   LET demo.customerdesc = "Get By ID Test"
   LET json_body = util.JSON.stringify(demo)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create record, status=%1", status_code))
      RETURN
   END IF

   -- Now look it up
   CALL test_rest_lib.http_get(SFMT("%1/GETID", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/GETID", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, demo)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/GETID", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF demo.customertypeid IS NULL OR demo.customertypeid.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("customertypeid is NULL/empty")
      CALL test_rest_lib.http_delete(SFMT("%1/GETID", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation
   SELECT customerdesc INTO db_desc
      FROM customerdemographics WHERE customertypeid = "GETID"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Record GETID not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/GETID", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF demo.customerdesc != db_desc THEN
      CALL test_rest_lib.test_fail(SFMT("REST desc '%1' != DB desc '%2'", demo.customerdesc, db_desc))
      CALL test_rest_lib.http_delete(SFMT("%1/GETID", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/GETID", m_base_url))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Got customer demographic: %1 (matches DB)", demo.customertypeid))
END FUNCTION

-- =============================================================================
-- Test: GET /customer-demographics/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /customer-demographics/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/ZZZZZ", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /customer-demographics — create a new record
-- =============================================================================
FUNCTION test_create_cust_demo()
   DEFINE new_demo t_cust_demo
   DEFINE created_demo t_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: POST /customer-demographics (create) ..."

   LET new_demo.customertypeid = "TSTCD"
   LET new_demo.customerdesc = "Test Customer Demo"

   LET json_body = util.JSON.stringify(new_demo)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_demo)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   IF created_demo.customerdesc != "Test Customer Demo" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected desc 'Test Customer Demo', got '%1'", created_demo.customerdesc))
      CALL test_rest_lib.http_delete(SFMT("%1/TSTCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation
   SELECT customerdesc INTO db_desc
      FROM customerdemographics WHERE customertypeid = "TSTCD"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Created record TSTCD not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/TSTCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/TSTCD", m_base_url))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Created TSTCD, verified in DB, cleaned up")
END FUNCTION

-- =============================================================================
-- Test: POST /customer-demographics — 400 for missing required fields
-- =============================================================================
FUNCTION test_create_missing_fields()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created t_cust_demo

   DISPLAY "TEST: POST /customer-demographics (invalid - missing typeid) ..."

   LET json_body = '{"customertypeid":"","customerdesc":"No Type ID"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created)
            IF created.customertypeid IS NOT NULL AND created.customertypeid.getLength() > 0 THEN
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created.customertypeid))
                  RETURNING status_code, response_body
            END IF
         CATCH
         END TRY
      END IF
      CALL test_rest_lib.test_fail(SFMT("Expected status 400, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 400 validation error as expected")
END FUNCTION

-- =============================================================================
-- Test: PUT /customer-demographics/{id} — update an existing record
-- =============================================================================
FUNCTION test_update_cust_demo()
   DEFINE new_demo t_cust_demo
   DEFINE updated_demo t_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: PUT /customer-demographics/{id} (update) ..."

   -- Create a record to update
   LET new_demo.customertypeid = "UPDCD"
   LET new_demo.customerdesc = "Original Desc"
   LET json_body = util.JSON.stringify(new_demo)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create record, status=%1", status_code))
      RETURN
   END IF

   -- Update it
   LET new_demo.customerdesc = "Updated Desc"
   LET json_body = util.JSON.stringify(new_demo)

   CALL test_rest_lib.http_put(SFMT("%1/UPDCD", m_base_url), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_demo)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_demo.customerdesc != "Updated Desc" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected desc 'Updated Desc', got '%1'", updated_demo.customerdesc))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation
   SELECT customerdesc INTO db_desc
      FROM customerdemographics WHERE customertypeid = "UPDCD"
   IF db_desc != "Updated Desc" THEN
      CALL test_rest_lib.test_fail(SFMT("DB desc '%1' != expected 'Updated Desc'", db_desc))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/UPDCD", m_base_url))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Updated UPDCD, verified in DB, cleaned up")
END FUNCTION

-- =============================================================================
-- Test: PUT /customer-demographics/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /customer-demographics/ZZZZZ (not found) ..."

   LET json_body = '{"customertypeid":"ZZZZZ","customerdesc":"Ghost Desc"}'
   CALL test_rest_lib.http_put(SFMT("%1/ZZZZZ", m_base_url), json_body)
      RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 AND status_code != 500 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400, 404, or 500, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /customer-demographics/{id} — delete a record
-- =============================================================================
FUNCTION test_delete_cust_demo()
   DEFINE new_demo t_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /customer-demographics/{id} (delete) ..."

   -- Create a record to delete
   LET new_demo.customertypeid = "DELCD"
   LET new_demo.customerdesc = "Delete Test"
   LET json_body = util.JSON.stringify(new_demo)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create record, status=%1", status_code))
      RETURN
   END IF

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/DELCD", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/DELCD", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM customerdemographics
      WHERE customertypeid = "DELCD"
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Record DELCD still exists in DB after delete")
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Deleted DELCD, verified 404 and gone from DB")
END FUNCTION

-- =============================================================================
-- Test: DELETE /customer-demographics/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /customer-demographics/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_delete(SFMT("%1/ZZZZZ", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: Full lifecycle — create, read, update, verify, delete, verify gone
-- =============================================================================
FUNCTION test_full_lifecycle()
   DEFINE demo t_cust_demo
   DEFINE verified t_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_desc STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET demo.customertypeid = "LFCCD"
   LET demo.customerdesc = "Lifecycle Demo"
   LET json_body = util.JSON.stringify(demo)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, demo)

   -- DB validation: verify created
   SELECT customerdesc INTO db_desc
      FROM customerdemographics WHERE customertypeid = "LFCCD"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Created record LFCCD not found in DB")
      CALL test_rest_lib.http_delete(SFMT("%1/LFCCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 2. READ — verify it exists
   CALL test_rest_lib.http_get(SFMT("%1/LFCCD", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after CREATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.customerdesc != "Lifecycle Demo" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong desc: '%1'", verified.customerdesc))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET demo.customerdesc = "Lifecycle Updated"
   LET json_body = util.JSON.stringify(demo)
   CALL test_rest_lib.http_put(SFMT("%1/LFCCD", m_base_url), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 4. READ — verify update took effect
   CALL test_rest_lib.http_get(SFMT("%1/LFCCD", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.customerdesc != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, desc='%1', expected 'Lifecycle Updated'", verified.customerdesc))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify update
   SELECT customerdesc INTO db_desc
      FROM customerdemographics WHERE customertypeid = "LFCCD"
   IF db_desc != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("DB desc '%1' != expected 'Lifecycle Updated'", db_desc))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCCD", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 5. DELETE
   CALL test_rest_lib.http_delete(SFMT("%1/LFCCD", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("DELETE failed: status=%1", status_code))
      RETURN
   END IF

   -- 6. READ — verify it's gone
   CALL test_rest_lib.http_get(SFMT("%1/LFCCD", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After DELETE, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify gone
   SELECT COUNT(*) INTO db_count FROM customerdemographics
      WHERE customertypeid = "LFCCD"
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Record LFCCD still in DB after delete")
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Full lifecycle passed for LFCCD (all DB checks passed)")
END FUNCTION
