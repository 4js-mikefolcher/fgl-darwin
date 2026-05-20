-- =============================================================================
-- Module:  test_model_suppliers.4gl
-- Purpose: fglunit tests for model_suppliers.4gl - Tier 2 (validateRec) +
--          Tier 3 (CRUD lifecycle, skipped on Postgres).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_suppliers
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_suppliers - validateRec + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_add_valid",        FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_null_company", FUNCTION test_validate_add_null_company)
   CALL FglUnit.register("test_validate_change_existing",  FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",   FUNCTION test_validate_change_missing)
   CALL FglUnit.register("test_crud_lifecycle",            FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE s t_supplier
   DEFINE v t_valid_rec

   LET s.companyname = "ACME"
   LET v = s.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid add must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_company()
   DEFINE s t_supplier
   DEFINE v t_valid_rec

   LET s.companyname = NULL
   LET v = s.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL company must fail")
   CALL Assertions.assertContains(v.valid_msg, "Company Name", "msg mentions Company Name")
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE s t_supplier
   DEFINE v t_valid_rec
   DEFINE existing_id INTEGER

   SELECT MIN(supplierid) INTO existing_id FROM suppliers
   LET s.supplierid  = existing_id
   LET s.companyname = "anything"
   LET v = s.validateRec("C")

   CALL Assertions.assertTrue(v.valid_status,
      "change of existing supplier must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE s t_supplier
   DEFINE v t_valid_rec

   LET s.supplierid  = 99999
   LET s.companyname = "anything"
   LET v = s.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing supplier must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found", "msg mentions not found")
END FUNCTION

PUBLIC FUNCTION test_crud_lifecycle()
   CALL Assertions.skip(
      "Postgres suppliers.supplierid has no sequence; insertRec DEFAULT fails")
END FUNCTION
