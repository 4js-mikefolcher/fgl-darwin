-- =============================================================================
-- Module:  test_model_orders.4gl
-- Purpose: fglunit tests for model_orders.4gl - Tier 2 (validateRec) +
--          Tier 3 (CRUD lifecycle, skipped on Postgres - orderid has no
--          sequence).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_orders
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_orders - validateRec + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_add_valid",            FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_null_orderdate",   FUNCTION test_validate_add_null_orderdate)
   CALL FglUnit.register("test_validate_add_null_customerid",  FUNCTION test_validate_add_null_customerid)
   CALL FglUnit.register("test_validate_add_empty_customerid", FUNCTION test_validate_add_empty_customerid)
   CALL FglUnit.register("test_validate_add_missing_customer", FUNCTION test_validate_add_missing_customer)
   CALL FglUnit.register("test_validate_add_null_employeeid",  FUNCTION test_validate_add_null_employeeid)
   CALL FglUnit.register("test_validate_add_missing_employee", FUNCTION test_validate_add_missing_employee)
   CALL FglUnit.register("test_validate_change_existing",      FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",       FUNCTION test_validate_change_missing)

   -- validate_orderid (FK existence)
   CALL FglUnit.register("test_validate_orderid_valid",   FUNCTION test_validate_orderid_valid)
   CALL FglUnit.register("test_validate_orderid_missing", FUNCTION test_validate_orderid_missing)
   CALL FglUnit.register("test_validate_orderid_null",    FUNCTION test_validate_orderid_null)
   CALL FglUnit.register("test_validate_orderid_zero",    FUNCTION test_validate_orderid_zero)

   CALL FglUnit.register("test_crud_lifecycle",                FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PRIVATE FUNCTION valid_order_rec() RETURNS (t_order)
   DEFINE o t_order
   LET o.orderdate  = MDY(1, 1, 2024)
   LET o.customerid = "ALFKI"
   LET o.employeeid = 1
   RETURN o
END FUNCTION

-- =============================================================================
-- validateRec
-- =============================================================================

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE o t_order
   DEFINE v t_valid_rec

   LET o = valid_order_rec()
   LET v = o.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid add should succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_orderdate()
   DEFINE o t_order
   DEFINE v t_valid_rec

   LET o = valid_order_rec()
   LET o.orderdate = NULL
   LET v = o.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL orderdate must fail")
   CALL Assertions.assertContains(v.valid_msg, "Order Date", "msg mentions Order Date")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_customerid()
   DEFINE o t_order
   DEFINE v t_valid_rec

   LET o = valid_order_rec()
   LET o.customerid = NULL
   LET v = o.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL customerid must fail")
   CALL Assertions.assertContains(v.valid_msg, "Customer ID is missing", "msg mentions missing customer")
END FUNCTION

PUBLIC FUNCTION test_validate_add_empty_customerid()
   DEFINE o t_order
   DEFINE v t_valid_rec

   LET o = valid_order_rec()
   LET o.customerid = ""
   LET v = o.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "empty customerid must fail")
END FUNCTION

PUBLIC FUNCTION test_validate_add_missing_customer()
   DEFINE o t_order
   DEFINE v t_valid_rec

   LET o = valid_order_rec()
   LET o.customerid = "NOPE!"
   LET v = o.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "non-existent customer must fail")
   CALL Assertions.assertContains(v.valid_msg, "does not exist in customers",
      "msg mentions customer does not exist")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_employeeid()
   DEFINE o t_order
   DEFINE v t_valid_rec

   LET o = valid_order_rec()
   LET o.employeeid = NULL
   LET v = o.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL employeeid must fail")
   CALL Assertions.assertContains(v.valid_msg, "Employee ID is missing",
      "msg mentions missing employee")
END FUNCTION

PUBLIC FUNCTION test_validate_add_missing_employee()
   DEFINE o t_order
   DEFINE v t_valid_rec

   LET o = valid_order_rec()
   LET o.employeeid = 99999
   LET v = o.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "non-existent employee must fail")
   CALL Assertions.assertContains(v.valid_msg, "does not exist in employees",
      "msg mentions employee does not exist")
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE o t_order
   DEFINE v t_valid_rec
   DEFINE existing_id INTEGER

   -- Pick any order present in the seed data
   SELECT MIN(orderid) INTO existing_id FROM orders

   LET o = valid_order_rec()
   LET o.orderid = existing_id
   LET v = o.validateRec("C")

   CALL Assertions.assertTrue(v.valid_status,
      "change of existing order must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE o t_order
   DEFINE v t_valid_rec

   LET o = valid_order_rec()
   LET o.orderid = 999999
   LET v = o.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing order in change mode must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found", "msg mentions not found")
END FUNCTION

-- =============================================================================
-- validate_orderid - FK existence helper used by both validateRec and the UI
-- =============================================================================

PUBLIC FUNCTION test_validate_orderid_valid()
   DEFINE v t_valid_rec
   DEFINE existing_id INTEGER

   SELECT MIN(orderid) INTO existing_id FROM orders
   LET v = model_orders.validate_orderid(existing_id)

   CALL Assertions.assertTrue(v.valid_status,
      "valid orderid must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_orderid_missing()
   DEFINE v t_valid_rec

   LET v = model_orders.validate_orderid(999999)

   CALL Assertions.assertFalse(v.valid_status, "non-existent orderid must fail")
   CALL Assertions.assertContains(v.valid_msg, "does not exist in orders",
      "msg must mention orders")
END FUNCTION

PUBLIC FUNCTION test_validate_orderid_null()
   DEFINE v t_valid_rec

   LET v = model_orders.validate_orderid(NULL)

   CALL Assertions.assertTrue(v.valid_status,
      "NULL orderid must short-circuit to success (UI hasn't entered a value yet)")
END FUNCTION

PUBLIC FUNCTION test_validate_orderid_zero()
   DEFINE v t_valid_rec

   LET v = model_orders.validate_orderid(0)

   CALL Assertions.assertTrue(v.valid_status,
      "orderid=0 must short-circuit to success (sentinel 'unset' value)")
END FUNCTION

-- =============================================================================
-- Tier 3
-- =============================================================================

PUBLIC FUNCTION test_crud_lifecycle()
   DEFINE o t_order
   DEFINE ins_status, upd_status, del_status t_valid_rec
   DEFINE check_freight DECIMAL(10,2)
   DEFINE check_count INTEGER

   LET o = valid_order_rec()
   LET o.freight = 1.23

   LET ins_status = o.insertRec()
   CALL Assertions.assertTrue(ins_status.valid_status,
      "insertRec must succeed (sqlcode=" || sqlca.sqlcode || ")")
   CALL Assertions.assertTrue(o.orderid > 0, "orderid must be populated")

   LET o.freight = 4.56
   LET upd_status = o.updateRec()
   CALL Assertions.assertTrue(upd_status.valid_status, "updateRec must succeed")

   SELECT freight INTO check_freight FROM orders WHERE orderid = o.orderid
   CALL Assertions.assertEqualsDec(4.56, check_freight, 0.001,
      "freight must be updated in the database")

   LET del_status = o.deleteRec()
   CALL Assertions.assertTrue(del_status.valid_status, "deleteRec must succeed")

   SELECT COUNT(*) INTO check_count FROM orders WHERE orderid = o.orderid
   CALL Assertions.assertEqualsInt(0, check_count, "row must be gone after deleteRec")
END FUNCTION
