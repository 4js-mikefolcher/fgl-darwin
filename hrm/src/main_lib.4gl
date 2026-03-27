IMPORT os
IMPORT util

DATABASE northwind
DEFINE arr_max INTEGER
DEFINE m_program_icons DYNAMIC ARRAY OF RECORD
    program_name STRING,
    icon_name    STRING
END RECORD

DEFINE first_form BOOLEAN = TRUE

FUNCTION init_pgm()

    OPTIONS MESSAGE LINE LAST - 2
    OPTIONS PROMPT LINE FIRST + 4
    OPTIONS ERROR LINE LAST - 1
    OPTIONS INPUT WRAP

    LET arr_max = 1000

    -- Load generic stylesheet for all windows
    CALL ui.Interface.loadStyles("generic.4st")

    -- Build program-to-icon mapping from action defaults
    CALL build_program_icons()

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
    DEFINE win ui.Window
    DEFINE pgm_name STRING
    DEFINE icon STRING
    DEFINE doc om.DomNode
    DEFINE toolbar_file STRING

    CALL frm.loadActionDefaults("generic.4ad")

    -- Load toolbar from TAG attribute on the form's LAYOUT element
    LET doc = frm.getNode()
    LET toolbar_file = doc.getAttribute("tag")
    IF toolbar_file IS NOT NULL AND toolbar_file.getLength() > 0 THEN
        CALL frm.loadToolBar(toolbar_file)
    END IF

    -- Set the window icon based on the running program
    LET win = ui.Window.getCurrent()
    IF win IS NOT NULL THEN
        LET pgm_name = base.Application.getProgramName()
        LET icon = get_program_icon(pgm_name)
        IF icon IS NOT NULL AND icon.getLength() > 0 THEN
            CALL win.setImage(icon)
            IF first_form THEN
                 CALL ui.Interface.setImage(icon) -- Also set as default for the application
                 LET first_form = FALSE
            END IF
        END IF
    END IF

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

-- =====================================================================
-- Function: build_program_icons
-- Purpose : Populate the module-level m_program_icons array with a
--           mapping from each program name to its font-awesome icon
--           as defined in the generic.4ad action defaults file.
-- =====================================================================
FUNCTION build_program_icons()

    CALL m_program_icons.clear()

    CALL add_program_icon("main_employees",    "fa-id-card")
    CALL add_program_icon("main_empl_terr",    "fa-map-marker")
    CALL add_program_icon("main_customers",    "fa-user")
    CALL add_program_icon("main_orders",       "fa-shopping-cart")
    CALL add_program_icon("main_order_details","fa-list-alt")
    CALL add_program_icon("main_shippers",     "fa-ship")
    CALL add_program_icon("main_products",     "fa-cube")
    CALL add_program_icon("main_categories",   "fa-tag")
    CALL add_program_icon("main_suppliers",    "fa-truck")
    CALL add_program_icon("main_region",       "fa-globe")
    CALL add_program_icon("main_territories",  "fa-map-marker")
    CALL add_program_icon("main_usstates",     "fa-flag")
    CALL add_program_icon("main_cust_demo",    "fa-id-badge")
    CALL add_program_icon("main_cust_cust_demo","fa-tags")
    CALL add_program_icon("bdl_menu",          "fa-rocket")
    CALL add_program_icon("main_rpt_orders_by_customer",  "fa-file-text")
    CALL add_program_icon("main_rpt_orders_by_employee",  "fa-file-text")
    CALL add_program_icon("main_rpt_orders_by_product",   "fa-file-text")
    CALL add_program_icon("main_rpt_orders_by_daterange", "fa-file-text")
    CALL add_program_icon("main_rpt_orders_generic",      "fa-file-code-o")
    CALL add_program_icon("main_rpt_org_chart",            "fa-sitemap")
    CALL add_program_icon("main_rpt_products_by_category","fa-file-text")
    CALL add_program_icon("mstr_dtl_order","fa-clipboard")

END FUNCTION #build_program_icons

-- =====================================================================
-- Function: add_program_icon
-- Purpose : Helper to append one program/icon pair to m_program_icons.
-- =====================================================================
FUNCTION add_program_icon(pgm_name STRING, icon_name STRING)
    DEFINE idx INTEGER

    LET idx = m_program_icons.getLength() + 1
    LET m_program_icons[idx].program_name = pgm_name
    LET m_program_icons[idx].icon_name    = icon_name

END FUNCTION #add_program_icon

-- =====================================================================
-- Function: get_program_icon
-- Purpose : Look up the font-awesome icon for a given program name.
-- Returns : The icon name string, or NULL if not found.
-- =====================================================================
FUNCTION get_program_icon(pgm_name STRING) RETURNS STRING
    DEFINE i INTEGER
    DEFINE base_name STRING

    -- Strip any path prefix to get just the program name
    LET base_name = os.Path.baseName(pgm_name)

    FOR i = 1 TO m_program_icons.getLength()
        IF m_program_icons[i].program_name == base_name THEN
            RETURN m_program_icons[i].icon_name
        END IF
    END FOR

    RETURN NULL

END FUNCTION #get_program_icon
