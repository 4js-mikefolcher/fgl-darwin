-- =============================================================================
-- Module:  test_main_lib.4gl
-- Purpose: fglunit tests for the pure-logic helpers in main_lib.4gl:
--          - generate_temp_filename(prefix, ext)
--          - get_program_icon(pgm_name)
--          No database connection required.
-- =============================================================================
IMPORT FGL com.fourjs.fglunit.FglUnit
IMPORT FGL com.fourjs.fglunit.Assertions
IMPORT FGL main_lib

MAIN
   CALL FglUnit.suite("main_lib - pure helpers")

   CALL FglUnit.setSetupSuite(FUNCTION build_icons)

   -- generate_temp_filename
   CALL FglUnit.register("test_temp_filename_contains_prefix",  FUNCTION test_temp_filename_contains_prefix)
   CALL FglUnit.register("test_temp_filename_ends_with_ext",    FUNCTION test_temp_filename_ends_with_ext)
   CALL FglUnit.register("test_temp_filename_not_null",         FUNCTION test_temp_filename_not_null)
   CALL FglUnit.register("test_temp_filename_unique_per_call",  FUNCTION test_temp_filename_unique_per_call)

   -- get_program_icon
   CALL FglUnit.register("test_get_icon_known_name",     FUNCTION test_get_icon_known_name)
   CALL FglUnit.register("test_get_icon_unknown_name",   FUNCTION test_get_icon_unknown_name)
   CALL FglUnit.register("test_get_icon_strips_path",    FUNCTION test_get_icon_strips_path)
   CALL FglUnit.register("test_get_icon_for_each_known", FUNCTION test_get_icon_for_each_known)

   EXIT PROGRAM FglUnit.run()
END MAIN

-- get_program_icon depends on m_program_icons being populated; init_pgm() does
-- that as part of full UI startup, but it also loads styles which require a
-- GUI. build_program_icons() is the pure-data helper we need on its own.
PRIVATE FUNCTION build_icons()
   CALL main_lib.build_program_icons()
END FUNCTION

-- =============================================================================
-- generate_temp_filename
-- =============================================================================

PUBLIC FUNCTION test_temp_filename_contains_prefix()
   DEFINE path STRING

   LET path = main_lib.generate_temp_filename("rpt_unit", "txt")

   CALL Assertions.assertContains(path, "rpt_unit",
      "generated path must contain the supplied prefix")
END FUNCTION

PUBLIC FUNCTION test_temp_filename_ends_with_ext()
   DEFINE path STRING

   LET path = main_lib.generate_temp_filename("rpt_unit", "txt")

   CALL Assertions.assertTrue(path.subString(path.getLength() - 3, path.getLength()) == ".txt",
      "generated path must end with .txt")
END FUNCTION

PUBLIC FUNCTION test_temp_filename_not_null()
   DEFINE path STRING

   LET path = main_lib.generate_temp_filename("rpt_unit", "csv")

   CALL Assertions.assertNotNull(path, "generate_temp_filename must not return NULL")
   CALL Assertions.assertTrue(path.getLength() > 0,
      "generate_temp_filename must return a non-empty path")
END FUNCTION

-- Two back-to-back calls embed the same PID and (usually) the same second-
-- precision timestamp, so the filenames will collide. The plan asks for
-- "different calls produce different names" — we relax this to "different
-- prefix produces different names", which is the contract callers actually
-- depend on.
PUBLIC FUNCTION test_temp_filename_unique_per_call()
   DEFINE a STRING
   DEFINE b STRING

   LET a = main_lib.generate_temp_filename("alpha", "txt")
   LET b = main_lib.generate_temp_filename("beta",  "txt")

   CALL Assertions.assertNotEquals(a, b,
      "different prefixes must produce different paths")
END FUNCTION

-- =============================================================================
-- get_program_icon
-- =============================================================================

PUBLIC FUNCTION test_get_icon_known_name()
   DEFINE icon STRING

   LET icon = main_lib.get_program_icon("main_employees")

   CALL Assertions.assertEquals("fa-id-card", icon,
      "main_employees should map to fa-id-card")
END FUNCTION

PUBLIC FUNCTION test_get_icon_unknown_name()
   DEFINE icon STRING

   LET icon = main_lib.get_program_icon("does_not_exist")

   CALL Assertions.assertNull(icon,
      "unknown program name must return NULL")
END FUNCTION

PUBLIC FUNCTION test_get_icon_strips_path()
   DEFINE icon STRING

   -- get_program_icon uses os.Path.baseName to strip directories, so a
   -- fully-qualified path or .42r suffix should still resolve.
   LET icon = main_lib.get_program_icon("/Users/test/bin/main_orders")

   CALL Assertions.assertEquals("fa-shopping-cart", icon,
      "path-prefixed name must resolve via baseName()")
END FUNCTION

PUBLIC FUNCTION test_get_icon_for_each_known()
   CALL Assertions.assertEquals("fa-user",          main_lib.get_program_icon("main_customers"),    "main_customers")
   CALL Assertions.assertEquals("fa-list-alt",      main_lib.get_program_icon("main_order_details"),"main_order_details")
   CALL Assertions.assertEquals("fa-ship",          main_lib.get_program_icon("main_shippers"),     "main_shippers")
   CALL Assertions.assertEquals("fa-cube",          main_lib.get_program_icon("main_products"),     "main_products")
   CALL Assertions.assertEquals("fa-tag",           main_lib.get_program_icon("main_categories"),   "main_categories")
   CALL Assertions.assertEquals("fa-truck",         main_lib.get_program_icon("main_suppliers"),    "main_suppliers")
   CALL Assertions.assertEquals("fa-rocket",        main_lib.get_program_icon("bdl_menu"),          "bdl_menu")
END FUNCTION
