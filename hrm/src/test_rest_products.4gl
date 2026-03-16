-- =============================================================================
-- Module: test_rest_products.4gl
-- Purpose: REST client to test the rest_products web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_products.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_product RECORD
   productid       INTEGER,
   productname     STRING,
   supplierid      INTEGER,
   categoryid      INTEGER,
   quantityperunit STRING,
   unitprice       FLOAT,
   unitsinstock    INTEGER,
   unitsonorder    INTEGER,
   reorderlevel    INTEGER,
   discontinued    INTEGER
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/prod/products"
   END IF
   CALL test_rest_lib.init_test_suite("REST Products Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_product()
   CALL test_update_product()
   CALL test_delete_product()
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
-- Test: GET /products — returns a list of products
-- =============================================================================
FUNCTION test_get_all()
   DEFINE products DYNAMIC ARRAY OF t_product
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /products (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, products)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   IF products.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one product, got 0")
      RETURN
   END IF

   IF products[1].productname IS NULL OR products[1].productname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("First product has NULL/empty productname")
      RETURN
   END IF

   -- DB validation: compare REST count with database count
   SELECT COUNT(*) INTO db_count FROM products
   IF db_count != products.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 products but DB has %2",
         products.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 products (matches DB)", products.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /products/{id} — returns a single product
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE prod t_product
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_name STRING

   DISPLAY "TEST: GET /products/1 (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/1", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, prod)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF prod.productid != 1 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected productid=1, got %1", prod.productid))
      RETURN
   END IF

   IF prod.productname IS NULL OR prod.productname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Product productname is NULL/empty")
      RETURN
   END IF

   -- DB validation: compare REST response with database record
   SELECT productname INTO db_name
      FROM products WHERE productid = 1
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Product ID=1 not found in database")
      RETURN
   END IF
   IF prod.productname != db_name THEN
      CALL test_rest_lib.test_fail(SFMT("REST name '%1' != DB name '%2'",
         prod.productname, db_name))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got product: %1 (matches DB)", prod.productname))
END FUNCTION

-- =============================================================================
-- Test: GET /products/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /products/99999 (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /products — create a new product
-- =============================================================================
FUNCTION test_create_product()
   DEFINE new_prod t_product
   DEFINE created_prod t_product
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_name STRING

   DISPLAY "TEST: POST /products (create) ..."

   LET new_prod.productname = "Test Product"
   LET new_prod.discontinued = 0
   LET new_prod.unitprice = 9.99
   LET new_prod.unitsinstock = 10
   LET new_prod.reorderlevel = 5

   LET json_body = util.JSON.stringify(new_prod)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_prod)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   IF created_prod.productid IS NULL OR created_prod.productid = 0 THEN
      CALL test_rest_lib.test_fail("Created product has no ID assigned")
      RETURN
   END IF

   IF created_prod.productname != "Test Product" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Test Product', got '%1'", created_prod.productname))
      RETURN
   END IF

   -- DB validation: verify record exists in database
   SELECT productname INTO db_name
      FROM products WHERE productid = created_prod.productid
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created product ID=%1 not found in database",
         created_prod.productid))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_prod.productid))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Test Product" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Test Product'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_prod.productid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_prod.productid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Created product ID=%1, verified in DB, cleaned up",
      created_prod.productid))
END FUNCTION

-- =============================================================================
-- Test: POST /products — 400 for missing product name
-- =============================================================================
FUNCTION test_create_missing_name()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created t_product

   DISPLAY "TEST: POST /products (invalid - missing name) ..."

   LET json_body = '{"productname":"","discontinued":0}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created)
            IF created.productid > 0 THEN
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created.productid))
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
-- Test: PUT /products/{id} — update an existing product
-- =============================================================================
FUNCTION test_update_product()
   DEFINE new_prod t_product
   DEFINE updated_prod t_product
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING

   DISPLAY "TEST: PUT /products/{id} (update) ..."

   -- Create a record to update
   LET new_prod.productname = "Update Test Product"
   LET new_prod.discontinued = 0
   LET new_prod.unitprice = 19.99
   LET json_body = util.JSON.stringify(new_prod)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create product, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_prod)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created product")
      RETURN
   END TRY
   LET created_id = new_prod.productid

   -- Update it
   LET new_prod.productname = "Updated Product"
   LET new_prod.unitprice = 29.99
   LET new_prod.discontinued = 1
   LET json_body = util.JSON.stringify(new_prod)

   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_prod)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_prod.productname != "Updated Product" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Updated Product', got '%1'", updated_prod.productname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT productname INTO db_name
      FROM products WHERE productid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Updated product ID=%1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Updated Product" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Updated Product'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Updated product ID=%1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: PUT /products/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /products/99999 (not found) ..."

   LET json_body = '{"productname":"Ghost Product","discontinued":0}'
   CALL test_rest_lib.http_put(SFMT("%1/99999", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /products/{id} — delete a product
-- =============================================================================
FUNCTION test_delete_product()
   DEFINE new_prod t_product
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /products/{id} (delete) ..."

   -- Create a record to delete
   LET new_prod.productname = "Delete Test Product"
   LET new_prod.discontinued = 0
   LET json_body = util.JSON.stringify(new_prod)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create product, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_prod)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created product")
      RETURN
   END TRY

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, new_prod.productid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, new_prod.productid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM products
      WHERE productid = new_prod.productid
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Product ID=%1 still exists in DB after delete",
         new_prod.productid))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Deleted product ID=%1, verified 404 and gone from DB",
      new_prod.productid))
END FUNCTION

-- =============================================================================
-- Test: DELETE /products/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /products/99999 (not found) ..."

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
   DEFINE prod t_product
   DEFINE verified t_product
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET prod.productname = "Lifecycle Product"
   LET prod.discontinued = 0
   LET prod.unitprice = 15.50
   LET prod.unitsinstock = 25
   LET json_body = util.JSON.stringify(prod)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, prod)
   LET created_id = prod.productid

   IF created_id IS NULL OR created_id = 0 THEN
      CALL test_rest_lib.test_fail("CREATE returned no ID")
      RETURN
   END IF

   -- DB validation: verify created record in database
   SELECT productname INTO db_name
      FROM products WHERE productid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created product ID=%1 not found in DB", created_id))
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
   IF verified.productname != "Lifecycle Product" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong name: '%1'", verified.productname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET prod.productname = "Lifecycle Updated"
   LET prod.unitprice = 25.00
   LET prod.discontinued = 1
   LET json_body = util.JSON.stringify(prod)
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
   IF verified.productname != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, name='%1', expected 'Lifecycle Updated'", verified.productname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT productname INTO db_name
      FROM products WHERE productid = created_id
   IF db_name != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Updated'", db_name))
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
   SELECT COUNT(*) INTO db_count FROM products
      WHERE productid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Product ID=%1 still in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Full lifecycle passed for ID=%1 (all DB checks passed)", created_id))
END FUNCTION
