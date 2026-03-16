-- =============================================================================
-- Module: test_rest_order_details.4gl
-- Purpose: REST client to test the rest_order_details web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_order_details.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING
DEFINE m_orders_url STRING

TYPE t_order_detail RECORD
   orderid     STRING,
   productid   STRING,
   productname STRING,
   unitprice   STRING,
   quantity    STRING,
   discount    STRING,
   totalprice  STRING
END RECORD

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
      LET m_base_url = "http://localhost:8899/odtl/order-details"
   END IF
   LET m_orders_url = "http://localhost:8899/ord/orders"
   CALL test_rest_lib.init_test_suite("REST Order Details Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_by_order_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_order_detail()
   CALL test_update_order_detail()
   CALL test_delete_order_detail()
   CALL test_full_lifecycle()

   -- Negative/error tests last
   CALL test_update_not_found()
   CALL test_create_invalid()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Test: GET /order-details — returns a list of all order details
-- =============================================================================
FUNCTION test_get_all()
   DEFINE details DYNAMIC ARRAY OF t_order_detail
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /order-details (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, details)
   CATCH
      CALL test_rest_lib.test_fail("Failed to parse JSON response")
      RETURN
   END TRY

   IF details.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one order detail, got 0")
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM order_details
   IF db_count != details.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 details but DB has %2",
         details.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 order details (matches DB)", details.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /order-details/{orderid}/{productid} — returns a single detail
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE detail t_order_detail
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_unitprice DECIMAL(10,2)

   DISPLAY "TEST: GET /order-details/10248/11 (get by composite ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/10248/11", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, detail)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF detail.orderid IS NULL OR detail.orderid.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Order detail orderid is NULL/empty")
      RETURN
   END IF

   -- DB validation
   SELECT unitprice INTO db_unitprice
      FROM order_details WHERE orderid = 10248 AND productid = 11
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Order detail 10248/11 not found in database")
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got order detail: order=%1 product=%2 (matches DB)", detail.orderid, detail.productid))
END FUNCTION

-- =============================================================================
-- Test: GET /order-details/order/{orderid} — returns all details for an order
-- =============================================================================
FUNCTION test_get_by_order_id()
   DEFINE details DYNAMIC ARRAY OF t_order_detail
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /order-details/order/10248 (get by order ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/order/10248", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, details)
   CATCH
      CALL test_rest_lib.test_fail("Failed to parse JSON response")
      RETURN
   END TRY

   IF details.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one detail for order 10248")
      RETURN
   END IF

   -- DB validation: compare count
   SELECT COUNT(*) INTO db_count FROM order_details WHERE orderid = 10248
   IF db_count != details.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 details for order 10248 but DB has %2",
         details.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 details for order 10248 (matches DB)", details.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /order-details/{orderid}/{productid} — 404 for non-existent
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /order-details/99999/99999 (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Helper: Create a temporary order for use by detail tests
-- Returns the created order ID (0 on failure)
-- =============================================================================
FUNCTION create_temp_order() RETURNS INTEGER
   DEFINE new_ord t_order
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   LET new_ord.customerid = "VINET"
   LET new_ord.employeeid = "5"
   LET new_ord.orderdate = "2024-11-01"
   LET new_ord.shipvia = "1"
   LET new_ord.freight = "0"
   LET json_body = '{"customerid":"VINET","employeeid":5,"orderdate":"2024-11-01","shipvia":1,"freight":0}'
   CALL test_rest_lib.http_post(m_orders_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      RETURN 0
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_ord)
   CATCH
      RETURN 0
   END TRY

   RETURN new_ord.orderid
END FUNCTION

-- =============================================================================
-- Helper: Delete a temporary order
-- =============================================================================
FUNCTION delete_temp_order(p_orderid INTEGER)
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_orders_url, p_orderid))
      RETURNING status_code, response_body
END FUNCTION

-- =============================================================================
-- Test: POST /order-details — create a new order detail
-- =============================================================================
FUNCTION test_create_order_detail()
   DEFINE new_detail t_order_detail
   DEFINE created_detail t_order_detail
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_qty INTEGER
   DEFINE temp_orderid INTEGER

   DISPLAY "TEST: POST /order-details (create) ..."

   -- Create a temp order first
   LET temp_orderid = create_temp_order()
   IF temp_orderid = 0 THEN
      CALL test_rest_lib.test_fail("Setup failed: could not create temp order")
      RETURN
   END IF

   LET new_detail.orderid = temp_orderid
   LET new_detail.productid = "1"
   LET new_detail.unitprice = "18.00"
   LET new_detail.quantity = "5"
   LET new_detail.discount = "0"

   LET json_body = SFMT('{"orderid":%1,"productid":1,"unitprice":18.00,"quantity":5,"discount":0}', temp_orderid)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_detail)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2/1", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END TRY

   -- DB validation
   SELECT quantity INTO db_qty
      FROM order_details WHERE orderid = temp_orderid AND productid = 1
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Created order detail not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/%2/1", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF
   IF db_qty != 5 THEN
      CALL test_rest_lib.test_fail(SFMT("DB quantity %1 != expected 5", db_qty))
      CALL test_rest_lib.http_delete(SFMT("%1/%2/1", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- Clean up detail then order
   CALL test_rest_lib.http_delete(SFMT("%1/%2/1", m_base_url, temp_orderid))
      RETURNING status_code, response_body
   CALL delete_temp_order(temp_orderid)

   CALL test_rest_lib.test_pass(SFMT("Created order detail %1/1, verified in DB, cleaned up", temp_orderid))
END FUNCTION

-- =============================================================================
-- Test: POST /order-details — 400 for invalid data
-- =============================================================================
FUNCTION test_create_invalid()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: POST /order-details (invalid - bad quantity) ..."

   -- quantity < 1 should fail validation
   LET json_body = '{"orderid":10248,"productid":99,"unitprice":10.00,"quantity":0,"discount":0}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         -- Clean up if created
         CALL test_rest_lib.http_delete(SFMT("%1/10248/99", m_base_url))
            RETURNING status_code, response_body
      END IF
      CALL test_rest_lib.test_fail(SFMT("Expected status 400, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 400 validation error as expected")
END FUNCTION

-- =============================================================================
-- Test: PUT /order-details/{orderid}/{productid} — update an existing detail
-- =============================================================================
FUNCTION test_update_order_detail()
   DEFINE new_detail t_order_detail
   DEFINE updated_detail t_order_detail
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_qty INTEGER
   DEFINE temp_orderid INTEGER

   DISPLAY "TEST: PUT /order-details/{orderid}/{productid} (update) ..."

   -- Create a temp order and detail
   LET temp_orderid = create_temp_order()
   IF temp_orderid = 0 THEN
      CALL test_rest_lib.test_fail("Setup failed: could not create temp order")
      RETURN
   END IF

   LET new_detail.orderid = temp_orderid
   LET new_detail.productid = "2"
   LET new_detail.unitprice = "19.00"
   LET new_detail.quantity = "3"
   LET new_detail.discount = "0"
   LET json_body = SFMT('{"orderid":%1,"productid":2,"unitprice":19.00,"quantity":3,"discount":0}', temp_orderid)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create detail, status=%1", status_code))
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- Update it
   LET new_detail.quantity = "10"
   LET new_detail.discount = "0.1"
   LET json_body = SFMT('{"orderid":%1,"productid":2,"unitprice":19.00,"quantity":10,"discount":0.1}', temp_orderid)

   CALL test_rest_lib.http_put(SFMT("%1/%2/2", m_base_url, temp_orderid), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2/2", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_detail)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2/2", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END TRY

   -- DB validation
   SELECT quantity INTO db_qty
      FROM order_details WHERE orderid = temp_orderid AND productid = 2
   IF db_qty != 10 THEN
      CALL test_rest_lib.test_fail(SFMT("DB quantity %1 != expected 10", db_qty))
      CALL test_rest_lib.http_delete(SFMT("%1/%2/2", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2/2", m_base_url, temp_orderid))
      RETURNING status_code, response_body
   CALL delete_temp_order(temp_orderid)

   CALL test_rest_lib.test_pass(SFMT("Updated order detail %1/2, verified in DB, cleaned up", temp_orderid))
END FUNCTION

-- =============================================================================
-- Test: PUT /order-details/{orderid}/{productid} — 400/404 for non-existent
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /order-details/99999/99999 (not found) ..."

   LET json_body = '{"orderid":99999,"productid":99999,"unitprice":10.00,"quantity":1,"discount":0}'
   CALL test_rest_lib.http_put(SFMT("%1/99999/99999", m_base_url), json_body)
      RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /order-details/{orderid}/{productid} — delete an order detail
-- =============================================================================
FUNCTION test_delete_order_detail()
   DEFINE new_detail t_order_detail
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER
   DEFINE temp_orderid INTEGER

   DISPLAY "TEST: DELETE /order-details/{orderid}/{productid} (delete) ..."

   -- Create a temp order and detail
   LET temp_orderid = create_temp_order()
   IF temp_orderid = 0 THEN
      CALL test_rest_lib.test_fail("Setup failed: could not create temp order")
      RETURN
   END IF

   LET new_detail.orderid = temp_orderid
   LET new_detail.productid = "3"
   LET new_detail.unitprice = "10.00"
   LET new_detail.quantity = "1"
   LET new_detail.discount = "0"
   LET json_body = SFMT('{"orderid":%1,"productid":3,"unitprice":10.00,"quantity":1,"discount":0}', temp_orderid)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create detail, status=%1", status_code))
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- Delete the detail
   CALL test_rest_lib.http_delete(SFMT("%1/%2/3", m_base_url, temp_orderid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/%2/3", m_base_url, temp_orderid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM order_details
      WHERE orderid = temp_orderid AND productid = 3
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Order detail still exists in DB after delete")
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- Clean up order
   CALL delete_temp_order(temp_orderid)

   CALL test_rest_lib.test_pass(SFMT("Deleted order detail %1/3, verified 404 and gone from DB", temp_orderid))
END FUNCTION

-- =============================================================================
-- Test: Full lifecycle — create order+detail, read, update, verify, delete
-- =============================================================================
FUNCTION test_full_lifecycle()
   DEFINE detail t_order_detail
   DEFINE verified t_order_detail
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_qty INTEGER
   DEFINE db_count INTEGER
   DEFINE temp_orderid INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 0. Create temp order
   LET temp_orderid = create_temp_order()
   IF temp_orderid = 0 THEN
      CALL test_rest_lib.test_fail("Setup failed: could not create temp order")
      RETURN
   END IF

   -- 1. CREATE detail
   LET detail.orderid = temp_orderid
   LET detail.productid = "4"
   LET detail.unitprice = "22.00"
   LET detail.quantity = "7"
   LET detail.discount = "0.05"
   LET json_body = SFMT('{"orderid":%1,"productid":4,"unitprice":22.00,"quantity":7,"discount":0.05}', temp_orderid)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   CALL util.JSON.parse(response_body, detail)

   -- DB validation: verify created
   SELECT quantity INTO db_qty
      FROM order_details WHERE orderid = temp_orderid AND productid = 4
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Created order detail not found in DB")
      CALL test_rest_lib.http_delete(SFMT("%1/%2/4", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- 2. READ — verify it exists
   CALL test_rest_lib.http_get(SFMT("%1/%2/4", m_base_url, temp_orderid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after CREATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/%2/4", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)

   -- 3. UPDATE
   LET detail.quantity = "15"
   LET detail.discount = "0.1"
   LET json_body = SFMT('{"orderid":%1,"productid":4,"unitprice":22.00,"quantity":15,"discount":0.1}', temp_orderid)
   CALL test_rest_lib.http_put(SFMT("%1/%2/4", m_base_url, temp_orderid), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/%2/4", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- 4. READ — verify update took effect
   CALL test_rest_lib.http_get(SFMT("%1/%2/4", m_base_url, temp_orderid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/%2/4", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- DB validation: verify update
   SELECT quantity INTO db_qty
      FROM order_details WHERE orderid = temp_orderid AND productid = 4
   IF db_qty != 15 THEN
      CALL test_rest_lib.test_fail(SFMT("DB quantity %1 != expected 15", db_qty))
      CALL test_rest_lib.http_delete(SFMT("%1/%2/4", m_base_url, temp_orderid))
         RETURNING status_code, response_body
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- 5. DELETE
   CALL test_rest_lib.http_delete(SFMT("%1/%2/4", m_base_url, temp_orderid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("DELETE failed: status=%1", status_code))
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- 6. READ — verify it's gone
   CALL test_rest_lib.http_get(SFMT("%1/%2/4", m_base_url, temp_orderid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After DELETE, expected 404, got %1", status_code))
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- DB validation: verify gone
   SELECT COUNT(*) INTO db_count FROM order_details
      WHERE orderid = temp_orderid AND productid = 4
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Order detail still in DB after delete")
      CALL delete_temp_order(temp_orderid)
      RETURN
   END IF

   -- Clean up temp order
   CALL delete_temp_order(temp_orderid)

   CALL test_rest_lib.test_pass(SFMT("Full lifecycle passed for detail %1/4 (all DB checks passed)", temp_orderid))
END FUNCTION
