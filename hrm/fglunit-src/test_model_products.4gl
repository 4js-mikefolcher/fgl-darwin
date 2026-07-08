-- =============================================================================
-- Module:  test_model_products.4gl
-- Purpose: fglunit tests for model_products.4gl - Tier 2 (validateRec) +
--          Tier 3 (CRUD lifecycle, skipped on Postgres).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_products
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_products - validateRec + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_add_valid",            FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_null_name",        FUNCTION test_validate_add_null_name)
   CALL FglUnit.register("test_validate_add_empty_name",       FUNCTION test_validate_add_empty_name)
   CALL FglUnit.register("test_validate_add_null_disc",        FUNCTION test_validate_add_null_disc)
   CALL FglUnit.register("test_validate_change_existing",      FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",       FUNCTION test_validate_change_missing)
   CALL FglUnit.register("test_crud_lifecycle",                FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE p t_product
   DEFINE v t_valid_rec

   LET p.productname  = "fglunit prod"
   LET p.discontinued = 0
   LET v = p.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid add must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_name()
   DEFINE p t_product
   DEFINE v t_valid_rec

   LET p.productname  = NULL
   LET p.discontinued = 0
   LET v = p.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL name must fail")
   CALL Assertions.assertContains(v.valid_msg, "required", "msg mentions required")
END FUNCTION

PUBLIC FUNCTION test_validate_add_empty_name()
   DEFINE p t_product
   DEFINE v t_valid_rec

   LET p.productname  = ""
   LET p.discontinued = 0
   LET v = p.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "empty name must fail")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_disc()
   DEFINE p t_product
   DEFINE v t_valid_rec

   LET p.productname  = "fglunit prod"
   LET p.discontinued = NULL
   LET v = p.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL discontinued must fail")
   CALL Assertions.assertContains(v.valid_msg, "Discontinued", "msg mentions Discontinued")
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE p t_product
   DEFINE v t_valid_rec
   DEFINE existing_id SMALLINT

   SELECT MIN(productid) INTO existing_id FROM products
   LET p.productid    = existing_id
   LET p.productname  = "anything"
   LET p.discontinued = 0
   LET v = p.validateRec("C")

   CALL Assertions.assertTrue(v.valid_status,
      "change of existing product must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE p t_product
   DEFINE v t_valid_rec

   LET p.productid    = 32000
   LET p.productname  = "anything"
   LET p.discontinued = 0
   LET v = p.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing product in change must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found", "msg mentions not found")
END FUNCTION

PUBLIC FUNCTION test_crud_lifecycle()
   DEFINE p t_product
   DEFINE ins_status, upd_status, del_status t_valid_rec
   DEFINE check_name STRING
   DEFINE check_count INTEGER

   LET p.productname  = "FGTST Product"
   LET p.discontinued = 0
   SELECT MIN(supplierid)  INTO p.supplierid FROM suppliers
   SELECT MIN(categoryid)  INTO p.categoryid FROM categories

   LET ins_status = p.insertRec()
   CALL Assertions.assertTrue(ins_status.valid_status,
      "insertRec must succeed (sqlcode=" || sqlca.sqlcode || ")")
   CALL Assertions.assertTrue(p.productid > 0, "productid must be populated")

   LET p.productname = "FGTST Product2"
   LET upd_status = p.updateRec()
   CALL Assertions.assertTrue(upd_status.valid_status, "updateRec must succeed")

   SELECT productname INTO check_name FROM products WHERE productid = p.productid
   CALL Assertions.assertEquals("FGTST Product2", check_name, "productname must be updated")

   LET del_status = p.deleteRec()
   CALL Assertions.assertTrue(del_status.valid_status, "deleteRec must succeed")

   SELECT COUNT(*) INTO check_count FROM products WHERE productid = p.productid
   CALL Assertions.assertEqualsInt(0, check_count, "row must be gone after deleteRec")
END FUNCTION
