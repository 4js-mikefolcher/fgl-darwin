-- =============================================================================
-- Module: test_rest_customers.4gl
-- Purpose: REST client to test the rest_customers web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_customers.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_customer RECORD
   customerid   STRING,
   companyname  STRING,
   contactname  STRING,
   contacttitle STRING,
   address      STRING,
   city         STRING,
   region       STRING,
   postalcode   STRING,
   country      STRING,
   phone        STRING,
   fax          STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/cust/customers"
   END IF
   CALL test_rest_lib.init_test_suite("REST Customers Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_customer()
   CALL test_update_customer()
   CALL test_delete_customer()
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
-- Test: GET /customers — returns a list of customers
-- =============================================================================
FUNCTION test_get_all()
   DEFINE customers DYNAMIC ARRAY OF t_customer
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /customers (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, customers)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   IF customers.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one customer, got 0")
      RETURN
   END IF

   IF customers[1].companyname IS NULL OR customers[1].companyname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("First customer has NULL/empty companyname")
      RETURN
   END IF

   -- DB validation: compare REST count with database count
   SELECT COUNT(*) INTO db_count FROM customers
   IF db_count != customers.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 customers but DB has %2",
         customers.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 customers (matches DB)", customers.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /customers/{id} — returns a single customer
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE cust t_customer
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_name STRING
   DEFINE db_contact STRING

   DISPLAY "TEST: GET /customers/ALFKI (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/ALFKI", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, cust)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF cust.customerid != "ALFKI" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected customerid='ALFKI', got '%1'", cust.customerid))
      RETURN
   END IF

   IF cust.companyname IS NULL OR cust.companyname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Customer companyname is NULL/empty")
      RETURN
   END IF

   -- DB validation: compare REST response with database record
   SELECT companyname, contactname INTO db_name, db_contact
      FROM customers WHERE customerid = "ALFKI"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Customer ALFKI not found in database")
      RETURN
   END IF
   IF cust.companyname != db_name THEN
      CALL test_rest_lib.test_fail(SFMT("REST name '%1' != DB name '%2'",
         cust.companyname, db_name))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got customer: %1, contact: %2 (matches DB)",
      cust.companyname, db_contact))
END FUNCTION

-- =============================================================================
-- Test: GET /customers/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /customers/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/ZZZZZ", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /customers — create a new customer
-- =============================================================================
FUNCTION test_create_customer()
   DEFINE new_cust t_customer
   DEFINE created_cust t_customer
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_name STRING
   DEFINE db_contact STRING

   DISPLAY "TEST: POST /customers (create) ..."

   LET new_cust.customerid = "TSTCO"
   LET new_cust.companyname = "Test Customer Co"
   LET new_cust.contactname = "John Test"
   LET new_cust.contacttitle = "Owner"
   LET new_cust.city = "Test City"
   LET new_cust.country = "USA"
   LET new_cust.phone = "(555) 100-0001"

   LET json_body = util.JSON.stringify(new_cust)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_cust)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   IF created_cust.customerid IS NULL OR created_cust.customerid.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Created customer has no ID assigned")
      RETURN
   END IF

   IF created_cust.companyname != "Test Customer Co" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Test Customer Co', got '%1'", created_cust.companyname))
      RETURN
   END IF

   -- DB validation: verify record exists in database
   SELECT companyname, contactname INTO db_name, db_contact
      FROM customers WHERE customerid = "TSTCO"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Created customer TSTCO not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/TSTCO", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Test Customer Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Test Customer Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/TSTCO", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/TSTCO", m_base_url))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Created customer TSTCO, verified in DB, cleaned up")
END FUNCTION

-- =============================================================================
-- Test: POST /customers — 400 for missing required fields
-- =============================================================================
FUNCTION test_create_missing_fields()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created t_customer

   DISPLAY "TEST: POST /customers (invalid - missing companyname) ..."

   LET json_body = '{"customerid":"BADCO","companyname":"","contactname":"Nobody"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created)
            IF created.customerid IS NOT NULL AND created.customerid.getLength() > 0 THEN
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created.customerid))
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
-- Test: PUT /customers/{id} — update an existing customer
-- =============================================================================
FUNCTION test_update_customer()
   DEFINE new_cust t_customer
   DEFINE updated_cust t_customer
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_name STRING
   DEFINE db_contact STRING

   DISPLAY "TEST: PUT /customers/{id} (update) ..."

   -- Create a record to update
   LET new_cust.customerid = "UPDCO"
   LET new_cust.companyname = "Update Test Customer"
   LET new_cust.contactname = "Jane Original"
   LET new_cust.phone = "(555) 200-0001"
   LET json_body = util.JSON.stringify(new_cust)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create customer, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_cust)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created customer")
      RETURN
   END TRY

   -- Update it
   LET new_cust.companyname = "Updated Customer Co"
   LET new_cust.contactname = "Jane Updated"
   LET new_cust.phone = "(555) 200-9999"
   LET json_body = util.JSON.stringify(new_cust)

   CALL test_rest_lib.http_put(SFMT("%1/UPDCO", m_base_url), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCO", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_cust)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCO", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_cust.companyname != "Updated Customer Co" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Updated Customer Co', got '%1'", updated_cust.companyname))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCO", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT companyname, contactname INTO db_name, db_contact
      FROM customers WHERE customerid = "UPDCO"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Updated customer UPDCO not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCO", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Updated Customer Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Updated Customer Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCO", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_contact != "Jane Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("DB contact '%1' != expected 'Jane Updated'", db_contact))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDCO", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/UPDCO", m_base_url))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Updated customer UPDCO, verified in DB, cleaned up")
END FUNCTION

-- =============================================================================
-- Test: PUT /customers/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /customers/ZZZZZ (not found) ..."

   LET json_body = '{"companyname":"Ghost Customer Co","contactname":"Nobody"}'
   CALL test_rest_lib.http_put(SFMT("%1/ZZZZZ", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /customers/{id} — delete a customer
-- =============================================================================
FUNCTION test_delete_customer()
   DEFINE new_cust t_customer
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /customers/{id} (delete) ..."

   -- Create a record to delete
   LET new_cust.customerid = "DELCO"
   LET new_cust.companyname = "Delete Test Customer"
   LET new_cust.contactname = "To Be Deleted"
   LET new_cust.phone = "(555) 300-0001"
   LET json_body = util.JSON.stringify(new_cust)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create customer, status=%1", status_code))
      RETURN
   END IF

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/DELCO", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/DELCO", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM customers
      WHERE customerid = "DELCO"
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Customer DELCO still exists in DB after delete")
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Deleted customer DELCO, verified 404 and gone from DB")
END FUNCTION

-- =============================================================================
-- Test: DELETE /customers/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /customers/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_delete(SFMT("%1/ZZZZZ", m_base_url)) RETURNING status_code, response_body

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
   DEFINE cust t_customer
   DEFINE verified t_customer
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_name STRING
   DEFINE db_contact STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET cust.customerid = "LFTST"
   LET cust.companyname = "Lifecycle Customer Co"
   LET cust.contactname = "Lifecycle Contact"
   LET cust.contacttitle = "Manager"
   LET cust.city = "Test City"
   LET cust.country = "Testland"
   LET cust.phone = "(555) 400-0001"
   LET json_body = util.JSON.stringify(cust)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, cust)

   IF cust.customerid IS NULL OR cust.customerid.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("CREATE returned no ID")
      RETURN
   END IF

   -- DB validation: verify created record in database
   SELECT companyname, contactname INTO db_name, db_contact
      FROM customers WHERE customerid = "LFTST"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Created customer LFTST not found in DB")
      CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Lifecycle Customer Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Customer Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 2. READ — verify it exists
   CALL test_rest_lib.http_get(SFMT("%1/LFTST", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after CREATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.companyname != "Lifecycle Customer Co" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong name: '%1'", verified.companyname))
      CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET cust.companyname = "Lifecycle Updated Co"
   LET cust.contactname = "Updated Contact"
   LET cust.phone = "(555) 400-9999"
   LET json_body = util.JSON.stringify(cust)
   CALL test_rest_lib.http_put(SFMT("%1/LFTST", m_base_url), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 4. READ — verify update took effect
   CALL test_rest_lib.http_get(SFMT("%1/LFTST", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.companyname != "Lifecycle Updated Co" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, name='%1', expected 'Lifecycle Updated Co'", verified.companyname))
      CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT companyname, contactname INTO db_name, db_contact
      FROM customers WHERE customerid = "LFTST"
   IF db_name != "Lifecycle Updated Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Updated Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_contact != "Updated Contact" THEN
      CALL test_rest_lib.test_fail(SFMT("DB contact '%1' != expected 'Updated Contact'", db_contact))
      CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 5. DELETE
   CALL test_rest_lib.http_delete(SFMT("%1/LFTST", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("DELETE failed: status=%1", status_code))
      RETURN
   END IF

   -- 6. READ — verify it's gone
   CALL test_rest_lib.http_get(SFMT("%1/LFTST", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After DELETE, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM customers
      WHERE customerid = "LFTST"
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Customer LFTST still in DB after delete")
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Full lifecycle passed for LFTST (all DB checks passed)")
END FUNCTION
