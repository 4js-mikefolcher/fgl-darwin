IMPORT os
IMPORT util

DATABASE northwind
DEFINE arr_max INTEGER

FUNCTION init_pgm()

    OPTIONS MESSAGE LINE LAST - 2
    OPTIONS PROMPT LINE FIRST + 4
    OPTIONS ERROR LINE LAST - 1

    LET arr_max = 1000

    -- Load generic stylesheet for all windows
    CALL ui.Interface.loadStyles("generic.4st")

    -- Register form initializer to auto-load action defaults
    CALL ui.Form.setDefaultInitializer("form_initializer")

END FUNCTION

FUNCTION get_arr_max()

   IF arr_max == 0 THEN
      LET arr_max = 1000
   END IF
   RETURN arr_max

END FUNCTION

FUNCTION form_initializer(frm ui.Form)

    CALL frm.loadActionDefaults("generic.4ad")

END FUNCTION #form_initializer

FUNCTION confirm_delete()

   MENU "Confirm Deletion"
      ATTRIBUTES(COMMENT="Are you sure you want to delete this record?", STYLE="dialog")
      COMMAND "Yes"
         RETURN TRUE
      COMMAND "No"
         EXIT MENU
   END MENU
   RETURN FALSE

END FUNCTION #confirm_delete

-- =====================================================================
-- Function: generate_temp_filename
-- Purpose : Generate a unique temporary file path that works across
--           Windows, macOS, and Linux using os.Path.
-- Params  : prefix - a short prefix for the filename (e.g. "rpt_cust")
--           extension - file extension without dot (e.g. "txt")
-- Returns : Fully qualified path to a temp file in the OS temp directory.
-- =====================================================================
FUNCTION generate_temp_filename(prefix, extension)
   DEFINE prefix STRING
   DEFINE extension STRING
   DEFINE temp_dir STRING
   DEFINE temp_file STRING
   DEFINE pid INTEGER
   DEFINE ts_str STRING
   DEFINE basename STRING

   -- Determine the OS temporary directory
   LET temp_dir = fgl_getenv("TMPDIR")       -- macOS / Linux
   IF temp_dir IS NULL OR temp_dir.getLength() == 0 THEN
      LET temp_dir = fgl_getenv("TMP")       -- Windows
   END IF
   IF temp_dir IS NULL OR temp_dir.getLength() == 0 THEN
      LET temp_dir = fgl_getenv("TEMP")      -- Windows alternate
   END IF
   IF temp_dir IS NULL OR temp_dir.getLength() == 0 THEN
      LET temp_dir = os.Path.join("/", "tmp") -- Fallback
   END IF

   -- Build a unique filename from prefix + PID + formatted timestamp
   LET ts_str = util.Datetime.format(CURRENT, "%Y%m%d_%H%M%S")
   LET pid = fgl_getpid()
   LET basename = SFMT("%1_%2_%3.%4", prefix, pid USING "&&&&&&", ts_str, extension)

   LET temp_file = os.Path.join(temp_dir, basename)

   RETURN temp_file

END FUNCTION #generate_temp_filename
