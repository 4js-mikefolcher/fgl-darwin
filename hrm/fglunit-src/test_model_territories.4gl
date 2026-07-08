-- =============================================================================
-- Module:  test_model_territories.4gl
-- Purpose: fglunit tests for model_territories.4gl - Tier 2 (validateRec) +
--          Tier 3 (CRUD lifecycle - uses explicit territoryid).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_territories
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_territories - validateRec + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_add_valid",            FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_duplicate",        FUNCTION test_validate_add_duplicate)
   CALL FglUnit.register("test_validate_add_null_id",          FUNCTION test_validate_add_null_id)
   CALL FglUnit.register("test_validate_add_null_desc",        FUNCTION test_validate_add_null_desc)
   CALL FglUnit.register("test_validate_add_null_region",      FUNCTION test_validate_add_null_region)
   CALL FglUnit.register("test_validate_change_existing",      FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",       FUNCTION test_validate_change_missing)
   CALL FglUnit.register("test_crud_lifecycle",                FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PRIVATE CONSTANT cTestId = "FGTST"

PRIVATE FUNCTION existing_regionid() RETURNS (SMALLINT)
   DEFINE rid SMALLINT
   SELECT MIN(regionid) INTO rid FROM region
   RETURN rid
END FUNCTION

-- BDL static SQL has no LIMIT clause; use a cursor to grab any existing row.
PRIVATE FUNCTION first_existing_territory_id() RETURNS (VARCHAR(20))
   DEFINE id VARCHAR(20)
   DECLARE c_first_terr CURSOR FOR SELECT territoryid FROM territories
   FOREACH c_first_terr INTO id
      EXIT FOREACH
   END FOREACH
   RETURN id
END FUNCTION

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE t t_territory
   DEFINE v t_valid_rec

   DELETE FROM territories WHERE territoryid = cTestId

   LET t.territoryid           = cTestId
   LET t.territorydescription  = "fglunit"
   LET t.regionid              = existing_regionid()
   LET v = t.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid add must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_duplicate()
   DEFINE t t_territory
   DEFINE v t_valid_rec

   LET t.territoryid          = first_existing_territory_id()
   LET t.territorydescription = "x"
   LET t.regionid             = existing_regionid()
   LET v = t.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "duplicate ID in add mode must fail")
   CALL Assertions.assertContains(v.valid_msg, "already exists", "msg mentions already exists")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_id()
   DEFINE t t_territory
   DEFINE v t_valid_rec

   LET t.territoryid          = NULL
   LET t.territorydescription = "x"
   LET t.regionid             = existing_regionid()
   LET v = t.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL territoryid must fail")
   CALL Assertions.assertContains(v.valid_msg, "Territory ID", "msg mentions Territory ID")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_desc()
   DEFINE t t_territory
   DEFINE v t_valid_rec

   DELETE FROM territories WHERE territoryid = cTestId

   LET t.territoryid          = cTestId
   LET t.territorydescription = NULL
   LET t.regionid             = existing_regionid()
   LET v = t.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL description must fail")
   CALL Assertions.assertContains(v.valid_msg, "Description", "msg mentions Description")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_region()
   DEFINE t t_territory
   DEFINE v t_valid_rec

   DELETE FROM territories WHERE territoryid = cTestId

   LET t.territoryid          = cTestId
   LET t.territorydescription = "x"
   LET t.regionid             = NULL
   LET v = t.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL region must fail")
   CALL Assertions.assertContains(v.valid_msg, "Region", "msg mentions Region")
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE t t_territory
   DEFINE v t_valid_rec

   LET t.territoryid          = first_existing_territory_id()
   LET t.territorydescription = "x"
   LET t.regionid             = existing_regionid()
   LET v = t.validateRec("C")

   CALL Assertions.assertTrue(v.valid_status,
      "change of existing territory must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE t t_territory
   DEFINE v t_valid_rec

   LET t.territoryid          = "FGNOPE"
   LET t.territorydescription = "x"
   LET t.regionid             = existing_regionid()
   LET v = t.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing territory in change must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found", "msg mentions not found")
END FUNCTION

PUBLIC FUNCTION test_crud_lifecycle()
   DEFINE t t_territory
   DEFINE ins_status t_valid_rec
   DEFINE upd_status t_valid_rec
   DEFINE del_status t_valid_rec
   DEFINE check_desc STRING
   DEFINE check_count INTEGER

   DELETE FROM territories WHERE territoryid = cTestId

   LET t.territoryid          = cTestId
   LET t.territorydescription = "fglunit"
   LET t.regionid             = existing_regionid()

   LET ins_status = t.insertRec()
   CALL Assertions.assertTrue(ins_status.valid_status,
      "insertRec must succeed (sqlcode=" || sqlca.sqlcode || ")")

   LET t.territorydescription = "fglunit2"
   LET upd_status = t.updateRec()
   CALL Assertions.assertTrue(upd_status.valid_status, "updateRec must succeed")

   SELECT territorydescription INTO check_desc FROM territories WHERE territoryid = cTestId
   CALL Assertions.assertEquals("fglunit2", check_desc, "description must be updated")

   LET del_status = t.deleteRec()
   CALL Assertions.assertTrue(del_status.valid_status, "deleteRec must succeed")

   SELECT COUNT(*) INTO check_count FROM territories WHERE territoryid = cTestId
   CALL Assertions.assertEqualsInt(0, check_count, "row must be gone after deleteRec")
END FUNCTION
