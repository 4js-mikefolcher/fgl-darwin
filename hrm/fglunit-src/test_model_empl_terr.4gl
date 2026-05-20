-- =============================================================================
-- Module:  test_model_empl_terr.4gl
-- Purpose: fglunit tests for model_empl_terr.4gl - Tier 2 (validateRec,
--          validateEmployee, validateTerritory) + Tier 3 (insert + delete
--          lifecycle - no updateRec defined in the model).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_empl_terr
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_empl_terr - validateRec + helpers + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   CALL FglUnit.register("test_validate_null_employee",   FUNCTION test_validate_null_employee)
   CALL FglUnit.register("test_validate_null_territory",  FUNCTION test_validate_null_territory)
   CALL FglUnit.register("test_validate_duplicate",       FUNCTION test_validate_duplicate)
   CALL FglUnit.register("test_validate_valid_new",       FUNCTION test_validate_valid_new)

   CALL FglUnit.register("test_validate_employee_valid",  FUNCTION test_validate_employee_valid)
   CALL FglUnit.register("test_validate_employee_missing",FUNCTION test_validate_employee_missing)
   CALL FglUnit.register("test_validate_territory_valid", FUNCTION test_validate_territory_valid)
   CALL FglUnit.register("test_validate_territory_missing",FUNCTION test_validate_territory_missing)

   CALL FglUnit.register("test_crud_lifecycle",           FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PRIVATE FUNCTION existing_employeeid() RETURNS (INTEGER)
   DEFINE id INTEGER
   SELECT MIN(employeeid) INTO id FROM employees
   RETURN id
END FUNCTION

PRIVATE FUNCTION existing_territoryid() RETURNS (STRING)
   DEFINE id STRING
   DECLARE c_first_terr CURSOR FOR SELECT territoryid FROM territories
   FOREACH c_first_terr INTO id
      EXIT FOREACH
   END FOREACH
   RETURN id
END FUNCTION

-- A territoryid we can safely insert/delete without clobbering data. We pick
-- one that already exists in seed data for validateRec/lookup tests, and a
-- separate territoryid we don't expect any employee to own for CRUD.
PRIVATE FUNCTION free_territoryid() RETURNS (STRING)
   DEFINE id STRING
   -- Find a (employee, territory) pair that does NOT exist yet.
   DECLARE c_free_terr CURSOR FOR
      SELECT t.territoryid
        FROM territories t
        WHERE NOT EXISTS (
          SELECT 1 FROM employeeterritories et
           WHERE et.territoryid = t.territoryid
             AND et.employeeid  = (SELECT MIN(employeeid) FROM employees))
   FOREACH c_free_terr INTO id
      EXIT FOREACH
   END FOREACH
   RETURN id
END FUNCTION

-- =============================================================================
-- validateRec
-- =============================================================================

PUBLIC FUNCTION test_validate_null_employee()
   DEFINE e t_empl_terr
   DEFINE v t_valid_rec

   LET e.employeeid  = NULL
   LET e.territoryid = existing_territoryid()
   LET v = e.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL employeeid must fail")
   CALL Assertions.assertContains(v.valid_msg, "Employee ID", "msg mentions Employee ID")
END FUNCTION

PUBLIC FUNCTION test_validate_null_territory()
   DEFINE e t_empl_terr
   DEFINE v t_valid_rec

   LET e.employeeid  = existing_employeeid()
   LET e.territoryid = NULL
   LET v = e.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL territoryid must fail")
   CALL Assertions.assertContains(v.valid_msg, "Territory ID", "msg mentions Territory ID")
END FUNCTION

PUBLIC FUNCTION test_validate_duplicate()
   DEFINE e t_empl_terr
   DEFINE v t_valid_rec

   DECLARE c_first_et CURSOR FOR SELECT employeeid, territoryid FROM employeeterritories
   FOREACH c_first_et INTO e.employeeid, e.territoryid
      EXIT FOREACH
   END FOREACH

   LET v = e.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "duplicate assignment must fail")
   CALL Assertions.assertContains(v.valid_msg, "already assigned", "msg mentions already assigned")
END FUNCTION

PUBLIC FUNCTION test_validate_valid_new()
   DEFINE e t_empl_terr
   DEFINE v t_valid_rec

   LET e.employeeid  = existing_employeeid()
   LET e.territoryid = free_territoryid()
   IF e.territoryid IS NULL THEN
      CALL Assertions.skip("no unassigned territory for employee in seed data")
      RETURN
   END IF

   -- Pre-clean to be sure
   DELETE FROM employeeterritories WHERE employeeid = e.employeeid AND territoryid = e.territoryid

   LET v = e.validateRec("A")
   CALL Assertions.assertTrue(v.valid_status,
      "valid new assignment must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

-- =============================================================================
-- validateEmployee / validateTerritory
-- =============================================================================

PUBLIC FUNCTION test_validate_employee_valid()
   DEFINE e t_empl_terr
   DEFINE v t_valid_rec

   LET e.employeeid = existing_employeeid()
   LET v = e.validateEmployee()

   CALL Assertions.assertTrue(v.valid_status, "valid employeeid must succeed")
   CALL Assertions.assertNotNull(e.fullname, "fullname must be populated")
END FUNCTION

PUBLIC FUNCTION test_validate_employee_missing()
   DEFINE e t_empl_terr
   DEFINE v t_valid_rec

   LET e.employeeid = 99999
   LET v = e.validateEmployee()

   CALL Assertions.assertFalse(v.valid_status, "missing employeeid must fail")
END FUNCTION

PUBLIC FUNCTION test_validate_territory_valid()
   DEFINE e t_empl_terr
   DEFINE v t_valid_rec

   LET e.territoryid = existing_territoryid()
   LET v = e.validateTerritory()

   CALL Assertions.assertTrue(v.valid_status, "valid territoryid must succeed")
   CALL Assertions.assertNotNull(e.territorydescription, "description must be populated")
   CALL Assertions.assertNotNull(e.regiondescription,    "region must be populated")
END FUNCTION

PUBLIC FUNCTION test_validate_territory_missing()
   DEFINE e t_empl_terr
   DEFINE v t_valid_rec

   LET e.territoryid = "NOPE-FG"
   LET v = e.validateTerritory()

   CALL Assertions.assertFalse(v.valid_status, "missing territoryid must fail")
END FUNCTION

-- =============================================================================
-- CRUD (insert + delete only)
-- =============================================================================

PUBLIC FUNCTION test_crud_lifecycle()
   DEFINE e t_empl_terr
   DEFINE ins_status t_valid_rec
   DEFINE del_status t_valid_rec
   DEFINE check_count INTEGER

   LET e.employeeid  = existing_employeeid()
   LET e.territoryid = free_territoryid()
   IF e.territoryid IS NULL THEN
      CALL Assertions.skip("no unassigned territory for employee in seed data")
      RETURN
   END IF

   DELETE FROM employeeterritories WHERE employeeid = e.employeeid AND territoryid = e.territoryid

   LET ins_status = e.insertRec()
   CALL Assertions.assertTrue(ins_status.valid_status,
      "insertRec must succeed (sqlcode=" || sqlca.sqlcode || ")")

   SELECT COUNT(*) INTO check_count FROM employeeterritories
    WHERE employeeid = e.employeeid AND territoryid = e.territoryid
   CALL Assertions.assertEqualsInt(1, check_count, "row must exist after insert")

   LET del_status = e.deleteRec()
   CALL Assertions.assertTrue(del_status.valid_status, "deleteRec must succeed")

   SELECT COUNT(*) INTO check_count FROM employeeterritories
    WHERE employeeid = e.employeeid AND territoryid = e.territoryid
   CALL Assertions.assertEqualsInt(0, check_count, "row must be gone after delete")
END FUNCTION
