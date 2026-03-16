-- =============================================================================
-- Module: test_rest_cust_cust_demo.4gl
-- Purpose: REST client to test the rest_cust_cust_demo web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_cust_cust_demo.42m
-- Server: Expects REST server running at http://localhost:8899
-- Note:   This is a junction table — no UPDATE endpoint
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING
DEFINE m_demo_url STRING   -- customer-demographics API for temp records
DEFINE m_temp_typeid STRING -- temp customertypeid for FK references

TYPE t_cust_cust_demo RECORD
   customerid     STRING,
   companyname    STRING,
   customertypeid STRING,
   customerdesc   STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/cust_demo/customer-customer-demo"
   END IF
   LET m_demo_url = "http://localhost:8899/demo/customer-demographics"
   CALL test_rest_lib.init_test_suite("REST Customer-Customer-Demo Service Test Suite", m_base_url)

   -- Setup: create a temp customer demographic type for FK references
   CALL create_temp_demo_type()

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_by_customer()
   CALL test_get_not_found()

   -- Create/Delete tests (no update for junction table)
   CALL test_create_cust_cust_demo()
   CALL test_delete_cust_cust_demo()
   CALL test_full_lifecycle()

   -- Negative/error tests last
   CALL test_delete_not_found()
   CALL test_create_duplicate()
   CALL test_create_missing_fields()

   -- Teardown: delete temp demographic type
   CALL delete_temp_demo_type()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Helper: create a temp customerdemographics record for FK references
-- =============================================================================
FUNCTION create_temp_demo_type()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   LET m_temp_typeid = "CCDT1"
   LET json_body = SFMT('{"customertypeid":"%1","customerdesc":"Temp type for CCD test"}', m_temp_typeid)
   CALL test_rest_lib.http_post(m_demo_url, json_body)
      RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      DISPLAY SFMT("WARNING: Could not create temp demo type %1, status=%2 body=%3",
         m_temp_typeid, status_code, response_body)
      DISPLAY "Some tests may fail if customerdemographics table has no suitable records"
   END IF
END FUNCTION

-- =============================================================================
-- Helper: delete the temp customerdemographics record
-- =============================================================================
FUNCTION delete_temp_demo_type()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_demo_url, m_temp_typeid))
      RETURNING status_code, response_body
END FUNCTION

-- =============================================================================
-- Test: GET /customer-customer-demo — returns a list of all assignments
-- =============================================================================
FUNCTION test_get_all()
   DEFINE records DYNAMIC ARRAY OF t_cust_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /customer-customer-demo (get all) ..."

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

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM customercustomerdemo
   IF db_count != records.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 records but DB has %2",
         records.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 customer-customer-demo records (matches DB)", records.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /customer-customer-demo/{custid}/{typeid} — returns a single record
-- We create a temp assignment so we know for sure one exists.
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE rec t_cust_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /customer-customer-demo/ALFKI/<typeid> (get by composite ID) ..."

   -- Create a temp assignment using existing customer ALFKI and our temp type
   LET json_body = SFMT('{"customerid":"ALFKI","customertypeid":"%1"}', m_temp_typeid)
   CALL test_rest_lib.http_post(m_base_url, json_body)
      RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create temp assignment, status=%1", status_code))
      RETURN
   END IF

   -- Now GET it
   CALL test_rest_lib.http_get(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, rec)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF rec.customerid IS NULL OR rec.customerid.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("customerid is NULL/empty")
      CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM customercustomerdemo
      WHERE customerid = "ALFKI" AND customertypeid = m_temp_typeid
   IF db_count = 0 THEN
      CALL test_rest_lib.test_fail("Assignment not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Got assignment: cust=%1 type=%2 (matches DB)", rec.customerid, rec.customertypeid))
END FUNCTION

-- =============================================================================
-- Test: GET /customer-customer-demo/customer/{custid} — returns all for a customer
-- =============================================================================
FUNCTION test_get_by_customer()
   DEFINE records DYNAMIC ARRAY OF t_cust_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /customer-customer-demo/customer/ALFKI (get by customer) ..."

   -- Create a temp assignment so we know ALFKI has at least one
   LET json_body = SFMT('{"customerid":"ALFKI","customertypeid":"%1"}', m_temp_typeid)
   CALL test_rest_lib.http_post(m_base_url, json_body)
      RETURNING status_code, response_body

   -- GET by customer
   CALL test_rest_lib.http_get(SFMT("%1/customer/ALFKI", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, records)
   CATCH
      CALL test_rest_lib.test_fail("Failed to parse JSON response")
      CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF records.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one record for ALFKI")
      CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM customercustomerdemo WHERE customerid = "ALFKI"
   IF db_count != records.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 records for ALFKI but DB has %2",
         records.getLength(), db_count))
      CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/ALFKI/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Returned %1 records for customer ALFKI (matches DB)", records.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /customer-customer-demo/{custid}/{typeid} — 404 for non-existent
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /customer-customer-demo/ZZZZZ/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/ZZZZZ/ZZZZZ", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /customer-customer-demo — create a new assignment
-- =============================================================================
FUNCTION test_create_cust_cust_demo()
   DEFINE created_rec t_cust_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: POST /customer-customer-demo (create) ..."

   -- Create assignment: ANATR + our temp type
   LET json_body = SFMT('{"customerid":"ANATR","customertypeid":"%1"}', m_temp_typeid)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_rec)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/ANATR/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END TRY

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM customercustomerdemo
      WHERE customerid = "ANATR" AND customertypeid = m_temp_typeid
   IF db_count = 0 THEN
      CALL test_rest_lib.test_fail("Created assignment not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/ANATR/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/ANATR/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Created assignment ANATR/" || m_temp_typeid || ", verified in DB, cleaned up")
END FUNCTION

-- =============================================================================
-- Test: POST /customer-customer-demo — 400 for duplicate
-- =============================================================================
FUNCTION test_create_duplicate()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: POST /customer-customer-demo (duplicate) ..."

   -- Create a temp assignment first
   LET json_body = SFMT('{"customerid":"ANTON","customertypeid":"%1"}', m_temp_typeid)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create initial assignment, status=%1", status_code))
      RETURN
   END IF

   -- Try to create the same assignment again
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 for duplicate, got %1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/ANTON/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/ANTON/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Got 400 for duplicate assignment as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /customer-customer-demo — 400 for missing fields
-- =============================================================================
FUNCTION test_create_missing_fields()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: POST /customer-customer-demo (invalid - missing fields) ..."

   LET json_body = '{"customerid":"","customertypeid":""}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 400 validation error as expected")
END FUNCTION

-- =============================================================================
-- Test: DELETE /customer-customer-demo/{custid}/{typeid} — delete an assignment
-- =============================================================================
FUNCTION test_delete_cust_cust_demo()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /customer-customer-demo/{custid}/{typeid} (delete) ..."

   -- Create an assignment to delete
   LET json_body = SFMT('{"customerid":"AROUT","customertypeid":"%1"}', m_temp_typeid)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create assignment, status=%1", status_code))
      RETURN
   END IF

   -- Delete the assignment
   CALL test_rest_lib.http_delete(SFMT("%1/AROUT/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/AROUT/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM customercustomerdemo
      WHERE customerid = "AROUT" AND customertypeid = m_temp_typeid
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Assignment still exists in DB after delete")
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Deleted assignment AROUT/" || m_temp_typeid || ", verified 404 and gone from DB")
END FUNCTION

-- =============================================================================
-- Test: DELETE /customer-customer-demo/{custid}/{typeid} — 404 for non-existent
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /customer-customer-demo/ZZZZZ/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_delete(SFMT("%1/ZZZZZ/ZZZZZ", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: Full lifecycle — assign, read, delete, verify gone
-- =============================================================================
FUNCTION test_full_lifecycle()
   DEFINE rec t_cust_cust_demo
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full Create-Read-Delete lifecycle ..."

   -- 1. CREATE assignment: BERGS + temp type
   LET json_body = SFMT('{"customerid":"BERGS","customertypeid":"%1"}', m_temp_typeid)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, rec)

   -- DB validation: verify created
   SELECT COUNT(*) INTO db_count FROM customercustomerdemo
      WHERE customerid = "BERGS" AND customertypeid = m_temp_typeid
   IF db_count = 0 THEN
      CALL test_rest_lib.test_fail("Created assignment not found in DB")
      CALL test_rest_lib.http_delete(SFMT("%1/BERGS/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 2. READ — verify it exists
   CALL test_rest_lib.http_get(SFMT("%1/BERGS/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after CREATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/BERGS/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, rec)

   IF rec.customerid IS NULL OR rec.customerid.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("READ returned NULL/empty customerid")
      CALL test_rest_lib.http_delete(SFMT("%1/BERGS/%2", m_base_url, m_temp_typeid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. DELETE
   CALL test_rest_lib.http_delete(SFMT("%1/BERGS/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("DELETE failed: status=%1", status_code))
      RETURN
   END IF

   -- 4. READ — verify it's gone
   CALL test_rest_lib.http_get(SFMT("%1/BERGS/%2", m_base_url, m_temp_typeid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After DELETE, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify gone
   SELECT COUNT(*) INTO db_count FROM customercustomerdemo
      WHERE customerid = "BERGS" AND customertypeid = m_temp_typeid
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Assignment still in DB after delete")
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Full lifecycle passed for BERGS/" || m_temp_typeid || " (all DB checks passed)")
END FUNCTION
