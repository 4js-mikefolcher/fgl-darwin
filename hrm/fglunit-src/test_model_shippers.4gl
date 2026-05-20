-- =============================================================================
-- Module:  test_model_shippers.4gl
-- Purpose: fglunit tests for model_shippers.4gl - Tier 2 (validateRec,
--          validate_shipvia) + Tier 3 (CRUD lifecycle, skipped on Postgres).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_shippers
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_shippers - validateRec + validate_shipvia + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_add_valid",        FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_null_company", FUNCTION test_validate_add_null_company)
   CALL FglUnit.register("test_validate_add_null_phone",   FUNCTION test_validate_add_null_phone)
   CALL FglUnit.register("test_validate_change_existing",  FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",   FUNCTION test_validate_change_missing)

   CALL FglUnit.register("test_validate_shipvia_valid",    FUNCTION test_validate_shipvia_valid)
   CALL FglUnit.register("test_validate_shipvia_missing",  FUNCTION test_validate_shipvia_missing)
   CALL FglUnit.register("test_validate_shipvia_null",     FUNCTION test_validate_shipvia_null)

   CALL FglUnit.register("test_crud_lifecycle",            FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE s t_shipper
   DEFINE v t_valid_rec

   LET s.companyname = "Fast Ship"
   LET s.phone       = "555-1234"
   LET v = s.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid add must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_company()
   DEFINE s t_shipper
   DEFINE v t_valid_rec

   LET s.companyname = NULL
   LET s.phone       = "555-1234"
   LET v = s.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL company must fail")
   CALL Assertions.assertContains(v.valid_msg, "Company Name", "msg mentions Company Name")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_phone()
   DEFINE s t_shipper
   DEFINE v t_valid_rec

   LET s.companyname = "Fast Ship"
   LET s.phone       = NULL
   LET v = s.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL phone must fail")
   CALL Assertions.assertContains(v.valid_msg, "Phone", "msg mentions Phone")
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE s t_shipper
   DEFINE v t_valid_rec
   DEFINE existing_id SMALLINT

   SELECT MIN(shipperid) INTO existing_id FROM shippers
   LET s.shipperid   = existing_id
   LET s.companyname = "anything"
   LET s.phone       = "555-1234"
   LET v = s.validateRec("C")

   CALL Assertions.assertTrue(v.valid_status,
      "change of existing shipper must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE s t_shipper
   DEFINE v t_valid_rec

   LET s.shipperid   = 32000
   LET s.companyname = "anything"
   LET s.phone       = "555-1234"
   LET v = s.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing shipper in change must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found", "msg mentions not found")
END FUNCTION

PUBLIC FUNCTION test_validate_shipvia_valid()
   DEFINE v t_valid_rec
   DEFINE existing_id SMALLINT

   SELECT MIN(shipperid) INTO existing_id FROM shippers
   LET v = model_shippers.validate_shipvia(existing_id)

   CALL Assertions.assertTrue(v.valid_status, "valid shipperid must succeed")
END FUNCTION

PUBLIC FUNCTION test_validate_shipvia_missing()
   DEFINE v t_valid_rec

   LET v = model_shippers.validate_shipvia(32000)

   CALL Assertions.assertFalse(v.valid_status, "non-existent shipperid must fail")
END FUNCTION

PUBLIC FUNCTION test_validate_shipvia_null()
   DEFINE v t_valid_rec

   LET v = model_shippers.validate_shipvia(NULL)

   CALL Assertions.assertTrue(v.valid_status, "NULL shipperid must short-circuit to success")
END FUNCTION

PUBLIC FUNCTION test_crud_lifecycle()
   CALL Assertions.skip(
      "Postgres shippers.shipperid has no sequence; insertRec DEFAULT fails")
END FUNCTION
