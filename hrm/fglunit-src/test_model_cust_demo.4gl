-- =============================================================================
-- Module:  test_model_cust_demo.4gl
-- Purpose: fglunit tests for model_cust_demo.4gl - Tier 2 (validateRec) +
--          Tier 3 (CRUD lifecycle, uses explicit customertypeid).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_cust_demo
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_cust_demo - validateRec + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_add_valid",      FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_null_id",    FUNCTION test_validate_add_null_id)
   CALL FglUnit.register("test_validate_add_duplicate",  FUNCTION test_validate_add_duplicate)
   CALL FglUnit.register("test_crud_lifecycle",          FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PRIVATE CONSTANT cTestId = "FGTST"

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE c t_cust_demo
   DEFINE v t_valid_rec

   DELETE FROM customerdemographics WHERE customertypeid = cTestId

   LET c.customertypeid = cTestId
   LET c.customerdesc   = "fglunit"
   LET v = c.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid add must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_id()
   DEFINE c t_cust_demo
   DEFINE v t_valid_rec

   LET c.customertypeid = NULL
   LET v = c.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL customertypeid must fail")
   CALL Assertions.assertContains(v.valid_msg, "required", "msg mentions required")
END FUNCTION

PUBLIC FUNCTION test_validate_add_duplicate()
   DEFINE c t_cust_demo
   DEFINE v t_valid_rec
   DEFINE existing_id VARCHAR(10)
   DEFINE row_count INTEGER

   SELECT COUNT(*) INTO row_count FROM customerdemographics
   IF row_count = 0 THEN
      CALL Assertions.skip("customerdemographics table is empty in seed data")
      RETURN
   END IF

   DECLARE c_first_demo CURSOR FOR SELECT customertypeid FROM customerdemographics
   FOREACH c_first_demo INTO existing_id
      EXIT FOREACH
   END FOREACH
   LET c.customertypeid = existing_id
   LET v = c.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "duplicate ID must fail")
   CALL Assertions.assertContains(v.valid_msg, "already exists", "msg mentions already exists")
END FUNCTION

PUBLIC FUNCTION test_crud_lifecycle()
   DEFINE c t_cust_demo
   DEFINE ins_status t_valid_rec
   DEFINE upd_status t_valid_rec
   DEFINE del_status t_valid_rec
   DEFINE check_desc STRING
   DEFINE check_count INTEGER

   DELETE FROM customerdemographics WHERE customertypeid = cTestId

   LET c.customertypeid = cTestId
   LET c.customerdesc   = "fglunit insert"

   LET ins_status = c.insertRec()
   CALL Assertions.assertTrue(ins_status.valid_status,
      "insertRec must succeed (sqlcode=" || sqlca.sqlcode || ")")

   LET c.customerdesc = "fglunit updated"
   LET upd_status = c.updateRec()
   CALL Assertions.assertTrue(upd_status.valid_status, "updateRec must succeed")

   SELECT customerdesc INTO check_desc FROM customerdemographics WHERE customertypeid = cTestId
   CALL Assertions.assertEquals("fglunit updated", check_desc, "description must be updated")

   LET del_status = c.deleteRec()
   CALL Assertions.assertTrue(del_status.valid_status, "deleteRec must succeed")

   SELECT COUNT(*) INTO check_count FROM customerdemographics WHERE customertypeid = cTestId
   CALL Assertions.assertEqualsInt(0, check_count, "row must be gone after deleteRec")
END FUNCTION
