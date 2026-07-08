-- =============================================================================
-- Module:  test_model_customers.4gl
-- Purpose: fglunit tests for model_customers.4gl - Tier 2 (validateRec,
--          validate_customer) and Tier 3 (insert/update/delete lifecycle).
--          Requires a connection to the northwind database.
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL model_customers
IMPORT FGL test_db_helper

SCHEMA northwind

MAIN
   CALL FglUnit.suite("model_customers - validateRec + validate_customer + CRUD")
   CALL FglUnit.setSetupSuite(FUNCTION test_db_helper.connect_northwind)
   CALL FglUnit.setTeardownSuite(FUNCTION test_db_helper.disconnect_northwind)

   -- Tier 2: validateRec
   CALL FglUnit.register("test_validate_add_valid",          FUNCTION test_validate_add_valid)
   CALL FglUnit.register("test_validate_add_duplicate_id",   FUNCTION test_validate_add_duplicate_id)
   CALL FglUnit.register("test_validate_add_null_id",        FUNCTION test_validate_add_null_id)
   CALL FglUnit.register("test_validate_add_null_company",   FUNCTION test_validate_add_null_company)
   CALL FglUnit.register("test_validate_change_existing",    FUNCTION test_validate_change_existing)
   CALL FglUnit.register("test_validate_change_missing",     FUNCTION test_validate_change_missing)

   -- Tier 2: validate_customer
   CALL FglUnit.register("test_validate_customer_valid",     FUNCTION test_validate_customer_valid)
   CALL FglUnit.register("test_validate_customer_missing",   FUNCTION test_validate_customer_missing)
   CALL FglUnit.register("test_validate_customer_null",      FUNCTION test_validate_customer_null)
   CALL FglUnit.register("test_validate_customer_empty",     FUNCTION test_validate_customer_empty)

   -- Tier 3: CRUD lifecycle
   CALL FglUnit.register("test_crud_lifecycle",              FUNCTION test_crud_lifecycle)

   EXIT PROGRAM FglUnit.run()
END MAIN

-- Use an obviously synthetic ID prefix that won't clash with seed data.
PRIVATE CONSTANT cTestId = "ZZZFG"

-- =============================================================================
-- Tier 2 - validateRec
-- =============================================================================

PUBLIC FUNCTION test_validate_add_valid()
   DEFINE c t_customer
   DEFINE v t_valid_rec

   LET c.customerid  = cTestId
   LET c.companyname = "fglunit test customer"
   LET v = c.validateRec("A")

   CALL Assertions.assertTrue(v.valid_status,
      "add with valid fields should succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_add_duplicate_id()
   DEFINE c t_customer
   DEFINE v t_valid_rec

   -- ALFKI is the canonical first customer in the Northwind seed data.
   LET c.customerid  = "ALFKI"
   LET c.companyname = "Some Name"
   LET v = c.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "duplicate ID in add mode must fail")
   CALL Assertions.assertContains(v.valid_msg, "already exists",
      "error must mention 'already exists'")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_id()
   DEFINE c t_customer
   DEFINE v t_valid_rec

   LET c.customerid  = NULL
   LET c.companyname = "Some Name"
   LET v = c.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL customerid must fail")
   CALL Assertions.assertContains(v.valid_msg, "required",
      "error must mention 'required'")
END FUNCTION

PUBLIC FUNCTION test_validate_add_null_company()
   DEFINE c t_customer
   DEFINE v t_valid_rec

   LET c.customerid  = cTestId
   LET c.companyname = NULL
   LET v = c.validateRec("A")

   CALL Assertions.assertFalse(v.valid_status, "NULL companyname must fail")
   CALL Assertions.assertContains(v.valid_msg, "required",
      "error must mention 'required'")
END FUNCTION

PUBLIC FUNCTION test_validate_change_existing()
   DEFINE c t_customer
   DEFINE v t_valid_rec

   LET c.customerid  = "ALFKI"
   LET c.companyname = "Anything"
   LET v = c.validateRec("C")

   CALL Assertions.assertTrue(v.valid_status,
      "change of existing customer should succeed (msg='" || NVL(v.valid_msg, "") || "')")
END FUNCTION

PUBLIC FUNCTION test_validate_change_missing()
   DEFINE c t_customer
   DEFINE v t_valid_rec

   LET c.customerid  = "NOPE!"
   LET c.companyname = "Anything"
   LET v = c.validateRec("C")

   CALL Assertions.assertFalse(v.valid_status, "missing customer in change mode must fail")
   CALL Assertions.assertContains(v.valid_msg, "not found",
      "error must mention 'not found'")
END FUNCTION

-- =============================================================================
-- Tier 2 - validate_customer
-- =============================================================================

PUBLIC FUNCTION test_validate_customer_valid()
   DEFINE v t_valid_rec

   LET v = model_customers.validate_customer("ALFKI")

   CALL Assertions.assertTrue(v.valid_status, "valid customerid must succeed")
   CALL Assertions.assertTrue(v.valid_msg.getLength() > 0,
      "valid customerid must return a non-empty company name")
END FUNCTION

PUBLIC FUNCTION test_validate_customer_missing()
   DEFINE v t_valid_rec

   LET v = model_customers.validate_customer("NOPE!")

   CALL Assertions.assertFalse(v.valid_status, "non-existent customerid must fail")
END FUNCTION

PUBLIC FUNCTION test_validate_customer_null()
   DEFINE v t_valid_rec

   LET v = model_customers.validate_customer(NULL)

   CALL Assertions.assertTrue(v.valid_status, "NULL customerid must short-circuit to success")
   CALL Assertions.assertEquals("", v.valid_msg, "NULL customerid must return empty msg")
END FUNCTION

PUBLIC FUNCTION test_validate_customer_empty()
   DEFINE v t_valid_rec

   LET v = model_customers.validate_customer("")

   CALL Assertions.assertTrue(v.valid_status, "empty customerid must short-circuit to success")
   CALL Assertions.assertEquals("", v.valid_msg, "empty customerid must return empty msg")
END FUNCTION

-- =============================================================================
-- Tier 3 - CRUD lifecycle (uses explicit customerid)
-- =============================================================================

PUBLIC FUNCTION test_crud_lifecycle()
   DEFINE c t_customer
   DEFINE ins_status t_valid_rec
   DEFINE upd_status t_valid_rec
   DEFINE del_status t_valid_rec
   DEFINE check_name STRING
   DEFINE check_count INTEGER

   -- Clean any leftover row from a previous run before starting
   DELETE FROM customers WHERE customerid = cTestId

   LET c.customerid  = cTestId
   LET c.companyname = "fglunit insert"
   LET c.contactname = "tester"
   LET c.country     = "USA"

   -- INSERT
   LET ins_status = c.insertRec()
   CALL Assertions.assertTrue(ins_status.valid_status,
      "insertRec must succeed (sqlcode=" || sqlca.sqlcode || ")")

   -- UPDATE
   LET c.companyname = "fglunit updated"
   LET upd_status = c.updateRec()
   CALL Assertions.assertTrue(upd_status.valid_status, "updateRec must succeed")

   SELECT companyname INTO check_name FROM customers WHERE customerid = cTestId
   CALL Assertions.assertEquals("fglunit updated", check_name,
      "companyname must be updated in the database")

   -- DELETE
   LET del_status = c.deleteRec()
   CALL Assertions.assertTrue(del_status.valid_status, "deleteRec must succeed")

   SELECT COUNT(*) INTO check_count FROM customers WHERE customerid = cTestId
   CALL Assertions.assertEqualsInt(0, check_count,
      "customer row must be gone after deleteRec")
END FUNCTION
