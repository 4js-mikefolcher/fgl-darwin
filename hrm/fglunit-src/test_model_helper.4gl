-- =============================================================================
-- Module:  test_model_helper.4gl
-- Purpose: fglunit tests for model_helper.4gl and module-level constants in
--          md_helper.4gl and list_view_helper.4gl.
--          No database connection required - pure logic tests.
-- Usage:   fglrun test_model_helper.42m
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL model_helper
IMPORT FGL md_helper
IMPORT FGL list_view_helper

-- =============================================================================
-- MAIN - register and run all tests
-- =============================================================================

MAIN
   CALL FglUnit.suite("model_helper - t_valid_rec + Tier 1 constants")

   -- init()
   CALL FglUnit.register("test_init_sets_status_false",    FUNCTION test_init_sets_status_false)
   CALL FglUnit.register("test_init_clears_message",       FUNCTION test_init_clears_message)

   -- success()
   CALL FglUnit.register("test_success_sets_status_true",            FUNCTION test_success_sets_status_true)
   CALL FglUnit.register("test_success_stores_message",              FUNCTION test_success_stores_message)
   CALL FglUnit.register("test_success_with_empty_message",          FUNCTION test_success_with_empty_message)
   CALL FglUnit.register("test_success_overwrites_previous_failure", FUNCTION test_success_overwrites_previous_failure)

   -- failed()
   CALL FglUnit.register("test_failed_sets_status_false",             FUNCTION test_failed_sets_status_false)
   CALL FglUnit.register("test_failed_stores_message",                FUNCTION test_failed_stores_message)
   CALL FglUnit.register("test_failed_with_empty_message",            FUNCTION test_failed_with_empty_message)
   CALL FglUnit.register("test_failed_overwrites_previous_success",   FUNCTION test_failed_overwrites_previous_success)

   -- round-trips
   CALL FglUnit.register("test_init_after_success_resets", FUNCTION test_init_after_success_resets)
   CALL FglUnit.register("test_init_after_failed_resets",  FUNCTION test_init_after_failed_resets)

   -- md_helper constants
   CALL FglUnit.register("test_md_helper_action_constants", FUNCTION test_md_helper_action_constants)
   CALL FglUnit.register("test_md_helper_image_constants",  FUNCTION test_md_helper_image_constants)

   -- list_view_helper constants
   CALL FglUnit.register("test_list_view_helper_constants", FUNCTION test_list_view_helper_constants)

   EXIT PROGRAM FglUnit.run()
END MAIN

-- =============================================================================
-- t_valid_rec.init()
-- =============================================================================

PUBLIC FUNCTION test_init_sets_status_false()
   DEFINE rec t_valid_rec
   -- Give it non-default values first so we know init actually resets them
   LET rec.valid_status = TRUE
   LET rec.valid_msg    = "something"

   CALL rec.init()

   CALL Assertions.assertFalse(rec.valid_status, "init() must set valid_status to FALSE")
END FUNCTION

PUBLIC FUNCTION test_init_clears_message()
   DEFINE rec t_valid_rec
   LET rec.valid_msg = "leftover"

   CALL rec.init()

   CALL Assertions.assertEquals("", rec.valid_msg, "init() must clear valid_msg to empty string")
END FUNCTION

-- =============================================================================
-- t_valid_rec.success()
-- =============================================================================

PUBLIC FUNCTION test_success_sets_status_true()
   DEFINE rec t_valid_rec

   CALL rec.success("all good")

   CALL Assertions.assertTrue(rec.valid_status, "success() must set valid_status to TRUE")
END FUNCTION

PUBLIC FUNCTION test_success_stores_message()
   DEFINE rec t_valid_rec

   CALL rec.success("Record saved")

   CALL Assertions.assertEquals("Record saved", rec.valid_msg,
      "success() must store the supplied message")
END FUNCTION

PUBLIC FUNCTION test_success_with_empty_message()
   DEFINE rec t_valid_rec

   CALL rec.success("")

   CALL Assertions.assertTrue(rec.valid_status,
      "success('') must still set valid_status to TRUE")
   CALL Assertions.assertEquals("", rec.valid_msg,
      "success('') must store an empty message")
END FUNCTION

PUBLIC FUNCTION test_success_overwrites_previous_failure()
   DEFINE rec t_valid_rec

   CALL rec.failed("oops")
   CALL rec.success("recovered")

   CALL Assertions.assertTrue(rec.valid_status,
      "success() after failed() must flip valid_status to TRUE")
   CALL Assertions.assertEquals("recovered", rec.valid_msg,
      "success() after failed() must replace the message")
END FUNCTION

-- =============================================================================
-- t_valid_rec.failed()
-- =============================================================================

PUBLIC FUNCTION test_failed_sets_status_false()
   DEFINE rec t_valid_rec

   CALL rec.failed("something went wrong")

   CALL Assertions.assertFalse(rec.valid_status, "failed() must set valid_status to FALSE")
END FUNCTION

PUBLIC FUNCTION test_failed_stores_message()
   DEFINE rec t_valid_rec

   CALL rec.failed("Customer ID is required")

   CALL Assertions.assertEquals("Customer ID is required", rec.valid_msg,
      "failed() must store the supplied error message")
END FUNCTION

PUBLIC FUNCTION test_failed_with_empty_message()
   DEFINE rec t_valid_rec

   CALL rec.failed("")

   CALL Assertions.assertFalse(rec.valid_status,
      "failed('') must still set valid_status to FALSE")
   CALL Assertions.assertEquals("", rec.valid_msg,
      "failed('') must store an empty message")
END FUNCTION

PUBLIC FUNCTION test_failed_overwrites_previous_success()
   DEFINE rec t_valid_rec

   CALL rec.success("Okay")
   CALL rec.failed("actually broken")

   CALL Assertions.assertFalse(rec.valid_status,
      "failed() after success() must flip valid_status to FALSE")
   CALL Assertions.assertEquals("actually broken", rec.valid_msg,
      "failed() after success() must replace the message")
END FUNCTION

-- =============================================================================
-- Round-trip: init -> success/failed -> init resets again
-- =============================================================================

PUBLIC FUNCTION test_init_after_success_resets()
   DEFINE rec t_valid_rec

   CALL rec.success("was good")
   CALL rec.init()

   CALL Assertions.assertFalse(rec.valid_status,
      "init() after success() must reset valid_status to FALSE")
   CALL Assertions.assertEquals("", rec.valid_msg,
      "init() after success() must clear the message")
END FUNCTION

PUBLIC FUNCTION test_init_after_failed_resets()
   DEFINE rec t_valid_rec

   CALL rec.failed("was bad")
   CALL rec.init()

   CALL Assertions.assertFalse(rec.valid_status,
      "init() after failed() must reset valid_status to FALSE")
   CALL Assertions.assertEquals("", rec.valid_msg,
      "init() after failed() must clear the message")
END FUNCTION

-- =============================================================================
-- md_helper module constants
-- =============================================================================

PUBLIC FUNCTION test_md_helper_action_constants()
   CALL Assertions.assertEqualsInt(0, md_helper.cQuit,      "cQuit == 0")
   CALL Assertions.assertEqualsInt(1, md_helper.cSearch,    "cSearch == 1")
   CALL Assertions.assertEqualsInt(2, md_helper.cAdd,       "cAdd == 2")
   CALL Assertions.assertEqualsInt(3, md_helper.cEdit,      "cEdit == 3")
   CALL Assertions.assertEqualsInt(4, md_helper.cDelete,    "cDelete == 4")
   CALL Assertions.assertEqualsInt(5, md_helper.cView,      "cView == 5")
   CALL Assertions.assertEqualsInt(6, md_helper.cAdvSearch, "cAdvSearch == 6")
   CALL Assertions.assertEqualsInt(7, md_helper.cExport,    "cExport == 7")
   CALL Assertions.assertEqualsInt(8, md_helper.cAppend,    "cAppend == 8")
END FUNCTION

PUBLIC FUNCTION test_md_helper_image_constants()
   CALL Assertions.assertEquals("fa-eye",    md_helper.cViewImage,   "cViewImage")
   CALL Assertions.assertEquals("fa-pencil", md_helper.cEditImage,   "cEditImage")
   CALL Assertions.assertEquals("fa-trash",  md_helper.cDeleteImage, "cDeleteImage")
END FUNCTION

-- =============================================================================
-- list_view_helper module constants
-- =============================================================================

PUBLIC FUNCTION test_list_view_helper_constants()
   CALL Assertions.assertEqualsInt(1, list_view_helper.cAddRecord,     "cAddRecord == 1")
   CALL Assertions.assertEqualsInt(2, list_view_helper.cEditRecord,    "cEditRecord == 2")
   CALL Assertions.assertEqualsInt(3, list_view_helper.cDeleteRecord,  "cDeleteRecord == 3")
   CALL Assertions.assertEqualsInt(4, list_view_helper.cViewRecord,    "cViewRecord == 4")
   CALL Assertions.assertEqualsInt(5, list_view_helper.cRefreshList,   "cRefreshList == 5")
   CALL Assertions.assertEqualsInt(6, list_view_helper.cExportToExcel, "cExportToExcel == 6")
END FUNCTION
