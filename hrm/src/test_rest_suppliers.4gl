-- =============================================================================
-- Module: test_rest_suppliers.4gl
-- Purpose: REST client to test the rest_suppliers web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_suppliers.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_supplier RECORD
   supplierid   INTEGER,
   companyname  STRING,
   contactname  STRING,
   contacttitle STRING,
   address      STRING,
   city         STRING,
   region       STRING,
   postalcode   STRING,
   country      STRING,
   phone        STRING,
   fax          STRING,
   homepage     STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/supp/suppliers"
   END IF
   CALL test_rest_lib.init_test_suite("REST Suppliers Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_supplier()
   CALL test_update_supplier()
   CALL test_delete_supplier()
   CALL test_full_lifecycle()

   -- Negative/error tests last
   CALL test_update_not_found()
   CALL test_delete_not_found()
   CALL test_create_missing_name()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Test: GET /suppliers — returns a list of suppliers
-- =============================================================================
FUNCTION test_get_all()
   DEFINE suppliers DYNAMIC ARRAY OF t_supplier
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /suppliers (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, suppliers)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   IF suppliers.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one supplier, got 0")
      RETURN
   END IF

   IF suppliers[1].companyname IS NULL OR suppliers[1].companyname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("First supplier has NULL/empty companyname")
      RETURN
   END IF

   -- DB validation: compare REST count with database count
   SELECT COUNT(*) INTO db_count FROM suppliers
   IF db_count != suppliers.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 suppliers but DB has %2",
         suppliers.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 suppliers (matches DB)", suppliers.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /suppliers/{id} — returns a single supplier
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE supp t_supplier
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_name STRING
   DEFINE db_contact STRING

   DISPLAY "TEST: GET /suppliers/1 (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/1", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, supp)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF supp.supplierid != 1 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected supplierid=1, got %1", supp.supplierid))
      RETURN
   END IF

   IF supp.companyname IS NULL OR supp.companyname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Supplier companyname is NULL/empty")
      RETURN
   END IF

   -- DB validation: compare REST response with database record
   SELECT companyname, contactname INTO db_name, db_contact
      FROM suppliers WHERE supplierid = 1
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Supplier ID=1 not found in database")
      RETURN
   END IF
   IF supp.companyname != db_name THEN
      CALL test_rest_lib.test_fail(SFMT("REST name '%1' != DB name '%2'",
         supp.companyname, db_name))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got supplier: %1, contact: %2 (matches DB)",
      supp.companyname, db_contact))
END FUNCTION

-- =============================================================================
-- Test: GET /suppliers/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /suppliers/99999 (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /suppliers — create a new supplier
-- =============================================================================
FUNCTION test_create_supplier()
   DEFINE new_supp t_supplier
   DEFINE created_supp t_supplier
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_name STRING
   DEFINE db_contact STRING

   DISPLAY "TEST: POST /suppliers (create) ..."

   LET new_supp.companyname = "Test Supplier Co"
   LET new_supp.contactname = "John Test"
   LET new_supp.contacttitle = "Sales Rep"
   LET new_supp.phone = "(555) 100-0001"

   LET json_body = util.JSON.stringify(new_supp)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_supp)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   IF created_supp.supplierid IS NULL OR created_supp.supplierid = 0 THEN
      CALL test_rest_lib.test_fail("Created supplier has no ID assigned")
      RETURN
   END IF

   IF created_supp.companyname != "Test Supplier Co" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Test Supplier Co', got '%1'", created_supp.companyname))
      RETURN
   END IF

   -- DB validation: verify record exists in database
   SELECT companyname, contactname INTO db_name, db_contact
      FROM suppliers WHERE supplierid = created_supp.supplierid
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created supplier ID=%1 not found in database",
         created_supp.supplierid))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_supp.supplierid))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Test Supplier Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Test Supplier Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_supp.supplierid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_supp.supplierid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Created supplier ID=%1, verified in DB, cleaned up",
      created_supp.supplierid))
END FUNCTION

-- =============================================================================
-- Test: POST /suppliers — 400 for missing company name
-- =============================================================================
FUNCTION test_create_missing_name()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created t_supplier

   DISPLAY "TEST: POST /suppliers (invalid - missing name) ..."

   LET json_body = '{"companyname":"","contactname":"Nobody"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created)
            IF created.supplierid > 0 THEN
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created.supplierid))
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
-- Test: PUT /suppliers/{id} — update an existing supplier
-- =============================================================================
FUNCTION test_update_supplier()
   DEFINE new_supp t_supplier
   DEFINE updated_supp t_supplier
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING
   DEFINE db_contact STRING

   DISPLAY "TEST: PUT /suppliers/{id} (update) ..."

   -- Create a record to update
   LET new_supp.companyname = "Update Test Supply"
   LET new_supp.contactname = "Jane Original"
   LET new_supp.phone = "(555) 200-0001"
   LET json_body = util.JSON.stringify(new_supp)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create supplier, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_supp)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created supplier")
      RETURN
   END TRY
   LET created_id = new_supp.supplierid

   -- Update it
   LET new_supp.companyname = "Updated Supply Co"
   LET new_supp.contactname = "Jane Updated"
   LET new_supp.phone = "(555) 200-9999"
   LET json_body = util.JSON.stringify(new_supp)

   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_supp)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_supp.companyname != "Updated Supply Co" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Updated Supply Co', got '%1'", updated_supp.companyname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   IF updated_supp.contactname != "Jane Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected contact 'Jane Updated', got '%1'", updated_supp.contactname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT companyname, contactname INTO db_name, db_contact
      FROM suppliers WHERE supplierid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Updated supplier ID=%1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Updated Supply Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Updated Supply Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_contact != "Jane Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("DB contact '%1' != expected 'Jane Updated'", db_contact))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Updated supplier ID=%1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: PUT /suppliers/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /suppliers/99999 (not found) ..."

   LET json_body = '{"companyname":"Ghost Supply Co","contactname":"Nobody"}'
   CALL test_rest_lib.http_put(SFMT("%1/99999", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /suppliers/{id} — delete a supplier
-- =============================================================================
FUNCTION test_delete_supplier()
   DEFINE new_supp t_supplier
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /suppliers/{id} (delete) ..."

   -- Create a record to delete
   LET new_supp.companyname = "Delete Test Supply"
   LET new_supp.contactname = "To Be Deleted"
   LET new_supp.phone = "(555) 300-0001"
   LET json_body = util.JSON.stringify(new_supp)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create supplier, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_supp)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created supplier")
      RETURN
   END TRY

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, new_supp.supplierid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, new_supp.supplierid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM suppliers
      WHERE supplierid = new_supp.supplierid
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Supplier ID=%1 still exists in DB after delete",
         new_supp.supplierid))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Deleted supplier ID=%1, verified 404 and gone from DB",
      new_supp.supplierid))
END FUNCTION

-- =============================================================================
-- Test: DELETE /suppliers/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /suppliers/99999 (not found) ..."

   CALL test_rest_lib.http_delete(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

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
   DEFINE supp t_supplier
   DEFINE verified t_supplier
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING
   DEFINE db_contact STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET supp.companyname = "Lifecycle Supply Co"
   LET supp.contactname = "Lifecycle Contact"
   LET supp.contacttitle = "Manager"
   LET supp.city = "Test City"
   LET supp.country = "Testland"
   LET supp.phone = "(555) 400-0001"
   LET json_body = util.JSON.stringify(supp)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, supp)
   LET created_id = supp.supplierid

   IF created_id IS NULL OR created_id = 0 THEN
      CALL test_rest_lib.test_fail("CREATE returned no ID")
      RETURN
   END IF

   -- DB validation: verify created record in database
   SELECT companyname, contactname INTO db_name, db_contact
      FROM suppliers WHERE supplierid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created supplier ID=%1 not found in DB", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Lifecycle Supply Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Supply Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 2. READ — verify it exists
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, created_id)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after CREATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.companyname != "Lifecycle Supply Co" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong name: '%1'", verified.companyname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   IF verified.contactname != "Lifecycle Contact" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong contact: '%1'", verified.contactname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET supp.companyname = "Lifecycle Updated Co"
   LET supp.contactname = "Updated Contact"
   LET supp.phone = "(555) 400-9999"
   LET json_body = util.JSON.stringify(supp)
   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 4. READ — verify update took effect
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, created_id)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.companyname != "Lifecycle Updated Co" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, name='%1', expected 'Lifecycle Updated Co'", verified.companyname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   IF verified.contactname != "Updated Contact" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, contact='%1', expected 'Updated Contact'", verified.contactname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT companyname, contactname INTO db_name, db_contact
      FROM suppliers WHERE supplierid = created_id
   IF db_name != "Lifecycle Updated Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Updated Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_contact != "Updated Contact" THEN
      CALL test_rest_lib.test_fail(SFMT("DB contact '%1' != expected 'Updated Contact'", db_contact))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 5. DELETE
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("DELETE failed: status=%1", status_code))
      RETURN
   END IF

   -- 6. READ — verify it's gone
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, created_id)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After DELETE, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM suppliers
      WHERE supplierid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Supplier ID=%1 still in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Full lifecycle passed for ID=%1 (all DB checks passed)", created_id))
END FUNCTION
