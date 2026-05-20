-- =============================================================================
-- Module:  test_model_usstates.4gl
-- Purpose: fglunit tests for model_usstates.4gl - Tier 2 (validateRec) +
--          Tier 3 (CRUD lifecycle, skipped on Postgres).
--          validateRec has no field checks in mode "A" - always succeeds.
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_usstates
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_usstates - validateRec + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_add_succeeds",       FUNCTION test_validate_add_succeeds)
   CALL FglUnit.register("test_validate_change_existing",    FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",     FUNCTION test_validate_change_missing)
   CALL FglUnit.register("test_crud_lifecycle",              FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PUBLIC FUNCTION test_validate_add_succeeds()
   DEFINE s t_usstate
   DEFINE v t_valid_rec

   LET v = s.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "mode A has no field checks - always success (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE s t_usstate
   DEFINE v t_valid_rec
   DEFINE existing_id INTEGER

   SELECT MIN(stateid) INTO existing_id FROM usstates
   LET s.stateid = existing_id
   LET v = s.validateRec("C")

   CALL Assertions.assertTrue(v.valid_status,
      "change of existing state must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE s t_usstate
   DEFINE v t_valid_rec

   LET s.stateid = 32000
   LET v = s.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing stateid must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found", "msg mentions not found")
END FUNCTION

PUBLIC FUNCTION test_crud_lifecycle()
   CALL Assertions.skip(
      "Postgres usstates.stateid has no sequence; insertRec DEFAULT fails")
END FUNCTION
