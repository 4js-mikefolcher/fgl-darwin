-- =============================================================================
-- Module:  test_model_cust_cust_demo.4gl
-- Purpose: fglunit tests for model_cust_cust_demo.4gl - Tier 2 (validateRec,
--          validateCustomer, validateCustomerType) + Tier 3 (insert + delete
--          lifecycle - no updateRec defined in the model).
--          Requires at least one customerdemographics row to test the link.
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_cust_cust_demo
IMPORT FGL model_cust_demo
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_cust_cust_demo - validateRec + helpers + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION suite_setup)
   CALL FglUnit.setTeardownSuite(FUNCTION suite_teardown)

   CALL FglUnit.register("test_validate_null_customerid", FUNCTION test_validate_null_customerid)
   CALL FglUnit.register("test_validate_null_typeid",     FUNCTION test_validate_null_typeid)
   CALL FglUnit.register("test_validate_duplicate",       FUNCTION test_validate_duplicate)
   CALL FglUnit.register("test_validate_valid_new",       FUNCTION test_validate_valid_new)

   CALL FglUnit.register("test_validate_customer_valid",  FUNCTION test_validate_customer_valid)
   CALL FglUnit.register("test_validate_customer_missing",FUNCTION test_validate_customer_missing)
   CALL FglUnit.register("test_validate_type_valid",      FUNCTION test_validate_type_valid)
   CALL FglUnit.register("test_validate_type_missing",    FUNCTION test_validate_type_missing)

   CALL FglUnit.register("test_crud_lifecycle",           FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PRIVATE CONSTANT cTestType = "FGTST"

PRIVATE FUNCTION suite_setup()
   DEFINE seed_demo t_cust_demo
   DEFINE rec t_valid_rec

   CALL test_db_helper.connect_northwind()

   -- Make sure a known customer-type row exists for the helper tests.
   DELETE FROM customercustomerdemo WHERE customertypeid = cTestType
   DELETE FROM customerdemographics WHERE customertypeid = cTestType
   LET seed_demo.customertypeid = cTestType
   LET seed_demo.customerdesc   = "fglunit seed"
   LET rec = seed_demo.insertRec()
END FUNCTION

PRIVATE FUNCTION suite_teardown()
   DEFINE seed_demo t_cust_demo
   DEFINE rec t_valid_rec

   DELETE FROM customercustomerdemo WHERE customertypeid = cTestType
   LET seed_demo.customertypeid = cTestType
   LET rec = seed_demo.deleteRec()
   CALL test_db_helper.disconnect_northwind()
END FUNCTION

-- =============================================================================
-- validateRec
-- =============================================================================

PUBLIC FUNCTION test_validate_null_customerid()
   DEFINE c t_cust_cust_demo
   DEFINE v t_valid_rec

   LET c.customerid     = NULL
   LET c.customertypeid = cTestType
   LET v = c.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL customerid must fail")
   CALL Assertions.assertContains(v.valid_msg, "Customer ID is required",
      "msg mentions Customer ID required")
END FUNCTION

PUBLIC FUNCTION test_validate_null_typeid()
   DEFINE c t_cust_cust_demo
   DEFINE v t_valid_rec

   LET c.customerid     = "ALFKI"
   LET c.customertypeid = NULL
   LET v = c.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL customertypeid must fail")
   CALL Assertions.assertContains(v.valid_msg, "Customer Type ID is required",
      "msg mentions Customer Type ID required")
END FUNCTION

PUBLIC FUNCTION test_validate_duplicate()
   DEFINE c t_cust_cust_demo
   DEFINE v t_valid_rec

   -- Seed a duplicate row to detect.
   DELETE FROM customercustomerdemo WHERE customerid = "ALFKI" AND customertypeid = cTestType
   INSERT INTO customercustomerdemo (customerid, customertypeid) VALUES ("ALFKI", cTestType)

   LET c.customerid     = "ALFKI"
   LET c.customertypeid = cTestType
   LET v = c.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "duplicate assignment must fail")
   CALL Assertions.assertContains(v.valid_msg, "already assigned", "msg mentions already assigned")

   DELETE FROM customercustomerdemo WHERE customerid = "ALFKI" AND customertypeid = cTestType
END FUNCTION

PUBLIC FUNCTION test_validate_valid_new()
   DEFINE c t_cust_cust_demo
   DEFINE v t_valid_rec

   DELETE FROM customercustomerdemo WHERE customerid = "ALFKI" AND customertypeid = cTestType

   LET c.customerid     = "ALFKI"
   LET c.customertypeid = cTestType
   LET v = c.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid new assignment must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

-- =============================================================================
-- validateCustomer / validateCustomerType
-- =============================================================================

PUBLIC FUNCTION test_validate_customer_valid()
   DEFINE c t_cust_cust_demo
   DEFINE v t_valid_rec

   LET c.customerid = "ALFKI"
   LET v = c.validateCustomer()

   CALL Assertions.assertTrue(v.valid_status, "valid customerid must succeed")
   CALL Assertions.assertNotNull(c.companyname, "companyname must be populated")
END FUNCTION

PUBLIC FUNCTION test_validate_customer_missing()
   DEFINE c t_cust_cust_demo
   DEFINE v t_valid_rec

   LET c.customerid = "NOPE!"
   LET v = c.validateCustomer()

   CALL Assertions.assertFalse(v.valid_status, "missing customerid must fail")
END FUNCTION

PUBLIC FUNCTION test_validate_type_valid()
   DEFINE c t_cust_cust_demo
   DEFINE v t_valid_rec

   LET c.customertypeid = cTestType
   LET v = c.validateCustomerType()

   CALL Assertions.assertTrue(v.valid_status, "valid customertypeid must succeed")
   CALL Assertions.assertNotNull(c.customerdesc, "customerdesc must be populated")
END FUNCTION

PUBLIC FUNCTION test_validate_type_missing()
   DEFINE c t_cust_cust_demo
   DEFINE v t_valid_rec

   LET c.customertypeid = "ZZZZZ"
   LET v = c.validateCustomerType()

   CALL Assertions.assertFalse(v.valid_status, "missing customertypeid must fail")
END FUNCTION

-- =============================================================================
-- CRUD (insert + delete only - no update on cross-ref tables)
-- =============================================================================

PUBLIC FUNCTION test_crud_lifecycle()
   DEFINE c t_cust_cust_demo
   DEFINE ins_status t_valid_rec
   DEFINE del_status t_valid_rec
   DEFINE check_count INTEGER

   DELETE FROM customercustomerdemo WHERE customerid = "ALFKI" AND customertypeid = cTestType

   LET c.customerid     = "ALFKI"
   LET c.customertypeid = cTestType

   LET ins_status = c.insertRec()
   CALL Assertions.assertTrue(ins_status.valid_status,
      "insertRec must succeed (sqlcode=" || sqlca.sqlcode || ")")

   SELECT COUNT(*) INTO check_count FROM customercustomerdemo
    WHERE customerid = "ALFKI" AND customertypeid = cTestType
   CALL Assertions.assertEqualsInt(1, check_count, "row must exist after insert")

   LET del_status = c.deleteRec()
   CALL Assertions.assertTrue(del_status.valid_status, "deleteRec must succeed")

   SELECT COUNT(*) INTO check_count FROM customercustomerdemo
    WHERE customerid = "ALFKI" AND customertypeid = cTestType
   CALL Assertions.assertEqualsInt(0, check_count, "row must be gone after delete")
END FUNCTION
