-- =============================================================================
-- Module:  test_model_employees.4gl
-- Purpose: fglunit tests for model_employees.4gl - Tier 2 (validateRec,
--          validate_employee) + Tier 3 (CRUD lifecycle, skipped on Postgres
--          because employees.employeeid has no sequence).
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_employees
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_employees - validateRec + validate_employee + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   -- validateRec
   CALL FglUnit.register("test_validate_add_valid",            FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_null_firstname",   FUNCTION test_validate_add_null_firstname)
   CALL FglUnit.register("test_validate_add_null_lastname",    FUNCTION test_validate_add_null_lastname)
   CALL FglUnit.register("test_validate_add_null_birthdate",   FUNCTION test_validate_add_null_birthdate)
   CALL FglUnit.register("test_validate_add_null_hiredate",    FUNCTION test_validate_add_null_hiredate)
   CALL FglUnit.register("test_validate_hire_before_birth",    FUNCTION test_validate_hire_before_birth)
   CALL FglUnit.register("test_validate_reportsto_valid",      FUNCTION test_validate_reportsto_valid)
   CALL FglUnit.register("test_validate_reportsto_missing",    FUNCTION test_validate_reportsto_missing)
   CALL FglUnit.register("test_validate_change_existing",      FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",       FUNCTION test_validate_change_missing)

   -- validate_employee
   CALL FglUnit.register("test_validate_employee_valid",       FUNCTION test_validate_employee_valid)
   CALL FglUnit.register("test_validate_employee_missing",     FUNCTION test_validate_employee_missing)
   CALL FglUnit.register("test_validate_employee_null",        FUNCTION test_validate_employee_null)

   -- Tier 3
   CALL FglUnit.register("test_crud_lifecycle",                FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

PRIVATE FUNCTION valid_employee_rec() RETURNS (t_employee)
   DEFINE e t_employee
   LET e.firstname = "Test"
   LET e.lastname  = "fglunit"
   LET e.birthdate = MDY(1, 1, 1990)
   LET e.hiredate  = MDY(1, 1, 2020)
   RETURN e
END FUNCTION

-- =============================================================================
-- validateRec
-- =============================================================================

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET v = e.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid add should succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_firstname()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET e.firstname = NULL
   LET v = e.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL firstname must fail")
   CALL Assertions.assertContains(v.valid_msg, "First name", "msg mentions First name")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_lastname()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET e.lastname = NULL
   LET v = e.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL lastname must fail")
   CALL Assertions.assertContains(v.valid_msg, "Last name", "msg mentions Last name")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_birthdate()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET e.birthdate = NULL
   LET v = e.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL birthdate must fail")
   CALL Assertions.assertContains(v.valid_msg, "Birth date", "msg mentions Birth date")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_hiredate()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET e.hiredate = NULL
   LET v = e.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL hiredate must fail")
   CALL Assertions.assertContains(v.valid_msg, "Hire date", "msg mentions Hire date")
END FUNCTION

PUBLIC FUNCTION test_validate_hire_before_birth()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET e.birthdate = MDY(1, 1, 2020)
   LET e.hiredate  = MDY(1, 1, 1990)
   LET v = e.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "hire date before birth must fail")
   CALL Assertions.assertContains(v.valid_msg, "before birth", "msg mentions before birth")
END FUNCTION

PUBLIC FUNCTION test_validate_reportsto_valid()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET e.reportsto = 2  -- Andrew Fuller in seed data
   LET v = e.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "valid reportsto should succeed (msg='" || NVL(v.valid_msg, "") || "')")
   CALL Assertions.assertNotNull(e.fullname,
      "valid reportsto must populate fullname")
END FUNCTION

PUBLIC FUNCTION test_validate_reportsto_missing()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET e.reportsto = 99999
   LET v = e.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "missing reportsto must fail")
   CALL Assertions.assertContains(v.valid_msg, "Invalid reports to", "msg mentions reports to")
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET e.employeeid = 1
   LET v = e.validateRec("C")

   CALL Assertions.assertTrue(v.valid_status,
      "change of existing employee must succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE e t_employee
   DEFINE v t_valid_rec

   LET e = valid_employee_rec()
   LET e.employeeid = 99999
   LET v = e.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing employee in change must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found", "msg mentions not found")
END FUNCTION

-- =============================================================================
-- validate_employee
-- =============================================================================

PUBLIC FUNCTION test_validate_employee_valid()
   DEFINE v t_valid_rec

   LET v = model_employees.validate_employee(1)

   CALL Assertions.assertTrue(v.valid_status, "valid employeeid must succeed")
   CALL Assertions.assertTrue(v.valid_msg.getLength() > 0,
      "valid employeeid must return a non-empty name")
END FUNCTION

PUBLIC FUNCTION test_validate_employee_missing()
   DEFINE v t_valid_rec

   LET v = model_employees.validate_employee(99999)

   CALL Assertions.assertFalse(v.valid_status, "non-existent employeeid must fail")
END FUNCTION

PUBLIC FUNCTION test_validate_employee_null()
   DEFINE v t_valid_rec

   LET v = model_employees.validate_employee(NULL)

   CALL Assertions.assertTrue(v.valid_status, "NULL employeeid must short-circuit to success")
   CALL Assertions.assertEquals("", v.valid_msg, "NULL employeeid must return empty msg")
END FUNCTION

-- =============================================================================
-- Tier 3 - CRUD lifecycle (skipped on Postgres)
-- =============================================================================

PUBLIC FUNCTION test_crud_lifecycle()
   CALL Assertions.skip(
      "Postgres employees.employeeid has no sequence; insertRec DEFAULT fails")
END FUNCTION
