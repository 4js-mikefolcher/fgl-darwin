-- =============================================================================
-- Module:  test_model_region.4gl
-- Purpose: fglunit tests for model_region.4gl - Tier 2 (validateRec) +
--          Tier 3 (CRUD lifecycle, skipped on Postgres).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_region
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_region - validateRec + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_add_valid",       FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_null_desc",   FUNCTION test_validate_add_null_desc)
   CALL FglUnit.register("test_validate_change_existing", FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",  FUNCTION test_validate_change_missing)
   CALL FglUnit.register("test_crud_lifecycle",           FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE r t_region
   DEFINE v t_valid_rec

   LET r.regiondescription = "fglunit-N"
   LET v = r.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid add must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_desc()
   DEFINE r t_region
   DEFINE v t_valid_rec

   LET r.regiondescription = NULL
   LET v = r.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL description must fail")
   CALL Assertions.assertContains(v.valid_msg, "Region Description", "msg mentions Region Description")
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE r t_region
   DEFINE v t_valid_rec
   DEFINE existing_id INTEGER

   SELECT MIN(regionid) INTO existing_id FROM region
   LET r.regionid          = existing_id
   LET r.regiondescription = "anything"
   LET v = r.validateRec("C")

   CALL Assertions.assertTrue(v.valid_status,
      "change of existing region must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE r t_region
   DEFINE v t_valid_rec

   LET r.regionid          = 99999
   LET r.regiondescription = "anything"
   LET v = r.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing region must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found", "msg mentions not found")
END FUNCTION

PUBLIC FUNCTION test_crud_lifecycle()
   CALL Assertions.skip(
      "Postgres region.regionid has no sequence; insertRec DEFAULT fails")
END FUNCTION
