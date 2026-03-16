-- =============================================================================
-- Module: test_rest_orders.4gl
-- Purpose: REST client to test the rest_orders web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_orders.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_order RECORD
   orderid        STRING,
   customerid     STRING,
   customername   STRING,
   employeeid     STRING,
   employeename   STRING,
   orderdate      STRING,
   requireddate   STRING,
   shippeddate    STRING,
   shipvia        STRING,
   freight        STRING,
   shipname       STRING,
   shipaddress    STRING,
   shipcity       STRING,
   shipregion     STRING,
   shippostalcode STRING,
   shipcountry    STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/ord/orders"
   END IF
   CALL test_rest_lib.init_test_suite("REST Orders Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_order()
   CALL test_update_order()
   CALL test_delete_order()
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
-- Test: GET /orders — returns a list of orders
-- =============================================================================
FUNCTION test_get_all()
   DEFINE orders DYNAMIC ARRAY OF t_order
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /orders (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, orders)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body.subString(1, 200)))
      RETURN
   END TRY

   IF orders.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one order, got 0")
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM orders
   IF db_count != orders.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 orders but DB has %2",
         orders.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 orders (matches DB)", orders.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /orders/{id} — returns a single order
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE l_order t_order
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_customerid STRING

   DISPLAY "TEST: GET /orders/10248 (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/10248", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, l_order)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF l_order.orderid IS NULL OR l_order.orderid.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Order orderid is NULL/empty")
      RETURN
   END IF

   -- DB validation
   SELECT customerid INTO db_customerid
      FROM orders WHERE orderid = 10248
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Order 10248 not found in database")
      RETURN
   END IF
   IF l_order.customerid != db_customerid THEN
      CALL test_rest_lib.test_fail(SFMT("REST customerid '%1' != DB '%2'", l_order.customerid, db_customerid))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got order: %1 customer=%2 (matches DB)", l_order.orderid, l_order.customerid))
END FUNCTION

-- =============================================================================
-- Test: GET /orders/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /orders/99999 (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /orders — create a new order
-- =============================================================================
FUNCTION test_create_order()
   DEFINE new_ord t_order
   DEFINE created_ord t_order
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_customerid STRING
   DEFINE created_id INTEGER

   DISPLAY "TEST: POST /orders (create) ..."

   LET new_ord.customerid = "VINET"
   LET new_ord.employeeid = "5"
   LET new_ord.orderdate = "2024-07-01"
   LET new_ord.requireddate = "2024-07-15"
   LET new_ord.shipvia = "1"
   LET new_ord.freight = "10.50"
   LET new_ord.shipname = "Test Ship"
   LET new_ord.shipcity = "Test City"
   LET new_ord.shipcountry = "USA"

   LET json_body = '{"customerid":"VINET","employeeid":5,"orderdate":"2024-07-01","requireddate":"2024-07-15","shipvia":1,"freight":10.50,"shipname":"Test Ship","shipcity":"Test City","shipcountry":"USA"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_ord)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   LET created_id = created_ord.orderid
   IF created_id IS NULL OR created_id = 0 THEN
      CALL test_rest_lib.test_fail("Created order has NULL/0 orderid")
      RETURN
   END IF

   -- DB validation
   SELECT customerid INTO db_customerid
      FROM orders WHERE orderid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created order %1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_customerid != "VINET" THEN
      CALL test_rest_lib.test_fail(SFMT("DB customerid '%1' != expected 'VINET'", db_customerid))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Created order %1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: POST /orders — 400 for missing required fields
-- =============================================================================
FUNCTION test_create_missing_fields()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_ord t_order

   DISPLAY "TEST: POST /orders (invalid - missing orderdate) ..."

   -- Missing orderdate (required)
   LET json_body = '{"customerid":"VINET","employeeid":5,"orderdate":""}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created_ord)
            IF created_ord.orderid IS NOT NULL THEN
               LET json_body = created_ord.orderid
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, json_body))
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
-- Test: PUT /orders/{id} — update an existing order
-- =============================================================================
FUNCTION test_update_order()
   DEFINE new_ord t_order
   DEFINE updated_ord t_order
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_shipname STRING
   DEFINE created_id INTEGER

   DISPLAY "TEST: PUT /orders/{id} (update) ..."

   -- Create a record to update
   LET new_ord.customerid = "VINET"
   LET new_ord.employeeid = "5"
   LET new_ord.orderdate = "2024-08-01"
   LET new_ord.requireddate = "2024-08-15"
   LET new_ord.shipvia = "1"
   LET new_ord.freight = "5.00"
   LET new_ord.shipname = "Original Ship"
   LET new_ord.shipcity = "Paris"
   LET new_ord.shipcountry = "France"
   LET json_body = '{"customerid":"VINET","employeeid":5,"orderdate":"2024-08-01","requireddate":"2024-08-15","shipvia":1,"freight":5.00,"shipname":"Original Ship","shipcity":"Paris","shipcountry":"France"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create order, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_ord)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created order")
      RETURN
   END TRY
   LET created_id = new_ord.orderid

   -- Update it
   LET new_ord.shipname = "Updated Ship"
   LET new_ord.shipcity = "Lyon"
   LET json_body = SFMT('{"orderid":%1,"customerid":"VINET","employeeid":5,"orderdate":"2024-08-01","requireddate":"2024-08-15","shipvia":1,"freight":5.00,"shipname":"Updated Ship","shipcity":"Lyon","shipcountry":"France"}', created_id)

   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_ord)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_ord.shipname != "Updated Ship" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected shipname 'Updated Ship', got '%1'", updated_ord.shipname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation
   SELECT shipname INTO db_shipname
      FROM orders WHERE orderid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Updated order %1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_shipname != "Updated Ship" THEN
      CALL test_rest_lib.test_fail(SFMT("DB shipname '%1' != expected 'Updated Ship'", db_shipname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Updated order %1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: PUT /orders/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /orders/99999 (not found) ..."

   LET json_body = '{"orderid":99999,"customerid":"VINET","employeeid":5,"orderdate":"2024-01-01"}'
   CALL test_rest_lib.http_put(SFMT("%1/99999", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /orders/{id} — delete an order
-- =============================================================================
FUNCTION test_delete_order()
   DEFINE new_ord t_order
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER
   DEFINE created_id INTEGER

   DISPLAY "TEST: DELETE /orders/{id} (delete) ..."

   -- Create a record to delete
   LET new_ord.customerid = "VINET"
   LET new_ord.employeeid = "5"
   LET new_ord.orderdate = "2024-09-01"
   LET new_ord.shipvia = "1"
   LET new_ord.freight = "0"
   LET json_body = '{"customerid":"VINET","employeeid":5,"orderdate":"2024-09-01","shipvia":1,"freight":0,"shipname":"","shipcity":"","shipcountry":""}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create order, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_ord)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created order")
      RETURN
   END TRY
   LET created_id = new_ord.orderid

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM orders
      WHERE orderid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Order %1 still exists in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Deleted order %1, verified 404 and gone from DB", created_id))
END FUNCTION

-- =============================================================================
-- Test: DELETE /orders/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /orders/99999 (not found) ..."

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
   DEFINE l_order t_order
   DEFINE verified t_order
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_shipname STRING
   DEFINE db_count INTEGER
   DEFINE created_id INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET l_order.customerid = "VINET"
   LET l_order.employeeid = "5"
   LET l_order.orderdate = "2024-10-01"
   LET l_order.requireddate = "2024-10-15"
   LET l_order.shipvia = "2"
   LET l_order.freight = "25.00"
   LET l_order.shipname = "Lifecycle Ship"
   LET l_order.shipcity = "Reims"
   LET l_order.shipcountry = "France"
   LET json_body = '{"customerid":"VINET","employeeid":5,"orderdate":"2024-10-01","requireddate":"2024-10-15","shipvia":2,"freight":25.00,"shipname":"Lifecycle Ship","shipcity":"Reims","shipcountry":"France"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, l_order)
   LET created_id = l_order.orderid

   -- DB validation: verify created
   SELECT shipname INTO db_shipname
      FROM orders WHERE orderid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created order %1 not found in DB", created_id))
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
   IF verified.shipname != "Lifecycle Ship" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong shipname: '%1'", verified.shipname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET l_order.shipname = "Lifecycle Updated"
   LET json_body = SFMT('{"orderid":%1,"customerid":"VINET","employeeid":5,"orderdate":"2024-10-01","requireddate":"2024-10-15","shipvia":2,"freight":25.00,"shipname":"Lifecycle Updated","shipcity":"Reims","shipcountry":"France"}', created_id)
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
   IF verified.shipname != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, shipname='%1', expected 'Lifecycle Updated'", verified.shipname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify update
   SELECT shipname INTO db_shipname
      FROM orders WHERE orderid = created_id
   IF db_shipname != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("DB shipname '%1' != expected 'Lifecycle Updated'", db_shipname))
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

   -- DB validation: verify record gone
   SELECT COUNT(*) INTO db_count FROM orders
      WHERE orderid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Order %1 still in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Full lifecycle passed for order %1 (all DB checks passed)", created_id))
END FUNCTION
