-- =============================================================================
-- Module:  test_model_order_details.4gl
-- Purpose: fglunit tests for model_order_details.4gl - Tier 2 (validateRec,
--          validate_product) + Tier 3 (CRUD lifecycle).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_order_details
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_order_details - validateRec + validate_product + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_add_valid",          FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_null_orderid",   FUNCTION test_validate_add_null_orderid)
   CALL FglUnit.register("test_validate_add_null_productid", FUNCTION test_validate_add_null_productid)
   CALL FglUnit.register("test_validate_add_null_unitprice", FUNCTION test_validate_add_null_unitprice)
   CALL FglUnit.register("test_validate_add_null_quantity",  FUNCTION test_validate_add_null_quantity)
   CALL FglUnit.register("test_validate_add_null_discount",  FUNCTION test_validate_add_null_discount)
   CALL FglUnit.register("test_validate_add_negative_price", FUNCTION test_validate_add_negative_price)
   CALL FglUnit.register("test_validate_add_quantity_zero",  FUNCTION test_validate_add_quantity_zero)
   CALL FglUnit.register("test_validate_add_discount_low",   FUNCTION test_validate_add_discount_low)
   CALL FglUnit.register("test_validate_add_discount_high",  FUNCTION test_validate_add_discount_high)
   CALL FglUnit.register("test_validate_add_missing_product",FUNCTION test_validate_add_missing_product)
   CALL FglUnit.register("test_validate_change_existing",    FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",     FUNCTION test_validate_change_missing)
   CALL FglUnit.register("test_validate_add_duplicate",      FUNCTION test_validate_add_duplicate)

   CALL FglUnit.register("test_validate_product_valid",      FUNCTION test_validate_product_valid)
   CALL FglUnit.register("test_validate_product_missing",    FUNCTION test_validate_product_missing)
   CALL FglUnit.register("test_validate_product_null",       FUNCTION test_validate_product_null)

   -- calcLineTotal (canonical line-total formula)
   CALL FglUnit.register("test_calcLineTotal_basic",            FUNCTION test_calcLineTotal_basic)
   CALL FglUnit.register("test_calcLineTotal_zero_discount",    FUNCTION test_calcLineTotal_zero_discount)
   CALL FglUnit.register("test_calcLineTotal_null_discount",    FUNCTION test_calcLineTotal_null_discount)
   CALL FglUnit.register("test_calcLineTotal_null_unitprice",   FUNCTION test_calcLineTotal_null_unitprice)
   CALL FglUnit.register("test_calcLineTotal_null_quantity",    FUNCTION test_calcLineTotal_null_quantity)
   CALL FglUnit.register("test_calcLineTotal_full_discount",    FUNCTION test_calcLineTotal_full_discount)
   CALL FglUnit.register("test_calcLineTotal_matches_postgres", FUNCTION test_calcLineTotal_matches_postgres)

   CALL FglUnit.register("test_crud_lifecycle",              FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PRIVATE FUNCTION existing_orderid() RETURNS (INTEGER)
   DEFINE id INTEGER
   SELECT MIN(orderid) INTO id FROM orders
   RETURN id
END FUNCTION

PRIVATE FUNCTION existing_productid() RETURNS (INTEGER)
   DEFINE id INTEGER
   SELECT MIN(productid) INTO id FROM products
   RETURN id
END FUNCTION

PRIVATE FUNCTION valid_detail_rec() RETURNS (t_order_detail)
   DEFINE d t_order_detail
   LET d.orderid   = existing_orderid()
   LET d.productid = 99   -- unlikely to be already used for this order
   LET d.unitprice = 1.00
   LET d.quantity  = 1
   LET d.discount  = 0
   RETURN d
END FUNCTION

-- =============================================================================
-- validateRec
-- =============================================================================

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec
   DEFINE pid INTEGER

   LET pid = existing_productid()
   LET d = valid_detail_rec()
   LET d.productid = pid

   -- Free the (order, product) pair before the test to keep it idempotent.
   DELETE FROM order_details WHERE orderid = d.orderid AND productid = d.productid

   LET v = d.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid add must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_orderid()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.orderid = NULL
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL orderid must fail")
   CALL Assertions.assertContains(v.valid_msg, "Order ID is required", "msg mentions Order ID required")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_productid()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.productid = NULL
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL productid must fail")
   CALL Assertions.assertContains(v.valid_msg, "Product ID is required", "msg mentions Product ID required")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_unitprice()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.unitprice = NULL
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL unitprice must fail")
   CALL Assertions.assertContains(v.valid_msg, "Unit Price is required", "msg mentions Unit Price required")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_quantity()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.quantity = NULL
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL quantity must fail")
   CALL Assertions.assertContains(v.valid_msg, "Quantity is required", "msg mentions Quantity required")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_discount()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.discount = NULL
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL discount must fail")
   CALL Assertions.assertContains(v.valid_msg, "Discount is required", "msg mentions Discount required")
END FUNCTION

PUBLIC FUNCTION test_validate_add_negative_price()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.productid = existing_productid()
   LET d.unitprice = -1
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "negative unitprice must fail")
   CALL Assertions.assertContains(v.valid_msg, "cannot be negative", "msg mentions cannot be negative")
END FUNCTION

PUBLIC FUNCTION test_validate_add_quantity_zero()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.productid = existing_productid()
   LET d.quantity = 0
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "quantity < 1 must fail")
   CALL Assertions.assertContains(v.valid_msg, "at least 1", "msg mentions at least 1")
END FUNCTION

PUBLIC FUNCTION test_validate_add_discount_low()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.productid = existing_productid()
   LET d.discount = -0.5
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "discount < 0 must fail")
   CALL Assertions.assertContains(v.valid_msg, "between 0 and 1", "msg mentions discount range")
END FUNCTION

PUBLIC FUNCTION test_validate_add_discount_high()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.productid = existing_productid()
   LET d.discount = 1
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "discount >= 1 must fail")
   CALL Assertions.assertContains(v.valid_msg, "between 0 and 1", "msg mentions discount range")
END FUNCTION

PUBLIC FUNCTION test_validate_add_missing_product()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.productid = 99999
   LET v = d.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "non-existent product must fail")
   CALL Assertions.assertContains(v.valid_msg, "does not exist in products", "msg mentions product")
END FUNCTION

-- BDL's static SQL parser rejects `LIMIT 1`; use a cursor and grab the first row.
PRIVATE FUNCTION first_existing_detail() RETURNS (t_order_detail)
   DEFINE d t_order_detail

   DECLARE c_first_detail CURSOR FOR
      SELECT orderid, productid, unitprice, quantity, discount FROM order_details
   FOREACH c_first_detail INTO d.orderid, d.productid, d.unitprice, d.quantity, d.discount
      EXIT FOREACH
   END FOREACH

   RETURN d
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = first_existing_detail()
   LET v = d.validateRec("C")
   CALL Assertions.assertTrue(v.valid_status,
      "change of existing detail must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = valid_detail_rec()
   LET d.orderid   = 99999
   LET d.productid = 99999
   LET v = d.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing composite key must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found", "msg mentions not found")
END FUNCTION

PUBLIC FUNCTION test_validate_add_duplicate()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d = first_existing_detail()
   LET v = d.validateRec("A")
   CALL Assertions.assertFalse(v.valid_status, "duplicate composite key in add must fail")
   CALL Assertions.assertContains(v.valid_msg, "already exists", "msg mentions already exists")
END FUNCTION

-- =============================================================================
-- validate_product
-- =============================================================================

PUBLIC FUNCTION test_validate_product_valid()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d.productid = existing_productid()
   LET v = d.validate_product()

   CALL Assertions.assertTrue(v.valid_status, "valid productid must succeed")
   CALL Assertions.assertNotNull(d.productname, "productname must be populated")
END FUNCTION

PUBLIC FUNCTION test_validate_product_missing()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d.productid = 99999
   LET v = d.validate_product()

   CALL Assertions.assertFalse(v.valid_status, "non-existent productid must fail")
END FUNCTION

PUBLIC FUNCTION test_validate_product_null()
   DEFINE d t_order_detail
   DEFINE v t_valid_rec

   LET d.productid = NULL
   LET v = d.validate_product()

   CALL Assertions.assertTrue(v.valid_status, "NULL productid must short-circuit to success")
END FUNCTION

-- =============================================================================
-- calcLineTotal - canonical formula, NVL-tolerant on every input
-- =============================================================================

PUBLIC FUNCTION test_calcLineTotal_basic()
   DEFINE total DECIMAL(12,2)

   LET total = model_order_details.calcLineTotal(10.00, 2, 0.05)

   CALL Assertions.assertEqualsDec(19.00, total, 0.001,
      "10.00 * 2 * (1 - 0.05) must equal 19.00")
END FUNCTION

PUBLIC FUNCTION test_calcLineTotal_zero_discount()
   DEFINE total DECIMAL(12,2)

   LET total = model_order_details.calcLineTotal(12.50, 4, 0)

   CALL Assertions.assertEqualsDec(50.00, total, 0.001,
      "discount=0 must give full price")
END FUNCTION

PUBLIC FUNCTION test_calcLineTotal_null_discount()
   DEFINE total DECIMAL(12,2)

   LET total = model_order_details.calcLineTotal(12.50, 4, NULL)

   CALL Assertions.assertEqualsDec(50.00, total, 0.001,
      "NULL discount must be treated as 0")
END FUNCTION

PUBLIC FUNCTION test_calcLineTotal_null_unitprice()
   DEFINE total DECIMAL(12,2)

   LET total = model_order_details.calcLineTotal(NULL, 4, 0.10)

   CALL Assertions.assertEqualsDec(0, total, 0.001,
      "NULL unitprice must yield 0, not NULL")
END FUNCTION

PUBLIC FUNCTION test_calcLineTotal_null_quantity()
   DEFINE total DECIMAL(12,2)

   LET total = model_order_details.calcLineTotal(12.50, NULL, 0.10)

   CALL Assertions.assertEqualsDec(0, total, 0.001,
      "NULL quantity must yield 0, not NULL")
END FUNCTION

PUBLIC FUNCTION test_calcLineTotal_full_discount()
   DEFINE total DECIMAL(12,2)

   -- discount of 1.0 is rejected by validateRec, but the formula should
   -- still produce a sane value if it's invoked anyway.
   LET total = model_order_details.calcLineTotal(99.99, 3, 1.0)

   CALL Assertions.assertEqualsDec(0, total, 0.001,
      "discount=1 must zero out the line total")
END FUNCTION

-- BDL <-> SQL parity. rest_order_details.4gl computes the same formula
-- inline in its SQL projections. If those drift from calcLineTotal,
-- this test catches it.
PUBLIC FUNCTION test_calcLineTotal_matches_postgres()
   DEFINE pg_total DECIMAL(12,2)
   DEFINE bdl_total DECIMAL(12,2)
   DEFINE up LIKE order_details.unitprice
   DEFINE qty LIKE order_details.quantity
   DEFINE disc LIKE order_details.discount

   -- Grab a real seeded row; compute the line total both ways.
   DECLARE c_one_detail CURSOR FOR
      SELECT unitprice, quantity, discount,
             unitprice * quantity * (1 - discount) AS pg_calc
        FROM order_details
   FOREACH c_one_detail INTO up, qty, disc, pg_total
      EXIT FOREACH
   END FOREACH

   LET bdl_total = model_order_details.calcLineTotal(up, qty, disc)

   CALL Assertions.assertEqualsDec(pg_total, bdl_total, 0.01,
      "BDL calcLineTotal must agree with Postgres for a real order_details row")
END FUNCTION

-- =============================================================================
-- Tier 3 - CRUD lifecycle
-- =============================================================================

PUBLIC FUNCTION test_crud_lifecycle()
   DEFINE d t_order_detail
   DEFINE ins_status t_valid_rec
   DEFINE upd_status t_valid_rec
   DEFINE del_status t_valid_rec
   DEFINE check_qty SMALLINT
   DEFINE check_count INTEGER
   DEFINE pid INTEGER

   LET pid = existing_productid()
   LET d.orderid   = existing_orderid()
   LET d.productid = pid
   LET d.unitprice = 1.00
   LET d.quantity  = 1
   LET d.discount  = 0

   -- Idempotent: clear the (order, product) pair before insert
   DELETE FROM order_details WHERE orderid = d.orderid AND productid = d.productid

   LET ins_status = d.insertRec()
   CALL Assertions.assertTrue(ins_status.valid_status,
      "insertRec must succeed (sqlcode=" || sqlca.sqlcode || ")")

   LET d.quantity = 5
   LET upd_status = d.updateRec()
   CALL Assertions.assertTrue(upd_status.valid_status, "updateRec must succeed")

   SELECT quantity INTO check_qty FROM order_details
    WHERE orderid = d.orderid AND productid = d.productid
   CALL Assertions.assertEqualsInt(5, check_qty, "quantity must be updated in DB")

   LET del_status = d.deleteRec()
   CALL Assertions.assertTrue(del_status.valid_status, "deleteRec must succeed")

   SELECT COUNT(*) INTO check_count FROM order_details
    WHERE orderid = d.orderid AND productid = d.productid
   CALL Assertions.assertEqualsInt(0, check_count, "row must be gone after deleteRec")
END FUNCTION
