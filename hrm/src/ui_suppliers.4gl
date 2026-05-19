IMPORT FGL main_lib
IMPORT FGL dialog_prompt
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_suppliers
IMPORT FGL ui_products
IMPORT FGL model_helper

DATABASE northwind

-- =====================================================================
-- Module Variables
-- =====================================================================
DEFINE suppliers_arr DYNAMIC ARRAY OF t_supplier
DEFINE curr_suppliers t_supplier

-- =====================================================================
-- Controller Setup
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS t_controller_config
   DEFINE cfg t_controller_config
   LET cfg.moduleName   = "suppliers"
   LET cfg.formName     = "suppliers"
   LET cfg.listFormName = "suppliers_list"
   LET cfg.windowTitle  = "Suppliers Management"
   LET cfg.hasModify    = TRUE
   LET cfg.hasQuery     = TRUE
   LET cfg.hasLookup    = TRUE
   LET cfg.entityName   = "Supplier"
   RETURN cfg
END FUNCTION #get_config

-- =====================================================================
-- Function: view_supplier
-- Purpose : View a specific supplier record (called from other modules)
-- =====================================================================
FUNCTION view_supplier(supp_id)
   DEFINE supp_id LIKE suppliers.supplierid
   DEFINE where_clause VARCHAR(500)

   IF supp_id IS NULL OR supp_id < 1 THEN
      ERROR "Supplier ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewSupplierWindow WITH FORM "suppliers"
      ATTRIBUTES(STYLE="modulewindow")

   LET where_clause = " suppliers.supplierid = ", supp_id
   CALL suppliers_do_load(where_clause)

   IF suppliers_arr.getLength() == 0 THEN
      CLOSE WINDOW viewSupplierWindow
      ERROR "Supplier not found"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate_view()

   CLOSE WINDOW viewSupplierWindow

END FUNCTION #view_supplier

-- =====================================================================
-- Function: submenu_suppliers
-- Purpose : Standard entry point — query then navigate using controller
-- =====================================================================
FUNCTION submenu_suppliers()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_suppliers

-- =====================================================================
-- Function: root_add_suppliers
-- Purpose : Entry point for suppliers add from root menu
-- =====================================================================
FUNCTION root_add_suppliers()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_suppliers

-- =====================================================================
-- Dispatch Interface: Functions called by the controller via dispatch
-- =====================================================================

-- Return the number of records in the result set
FUNCTION suppliers_get_count() RETURNS INTEGER
   RETURN suppliers_arr.getLength()
END FUNCTION #suppliers_get_count

-- Load the record at index into the current record
FUNCTION suppliers_load_at(idx INTEGER)
   INITIALIZE curr_suppliers.* TO NULL
   IF idx > 0 AND idx <= suppliers_arr.getLength() THEN
      LET curr_suppliers = suppliers_arr[idx]
   END IF
END FUNCTION #suppliers_load_at

-- Display the current record on the form
FUNCTION suppliers_display_curr()
   DISPLAY BY NAME curr_suppliers.*
END FUNCTION #suppliers_display_curr

-- Clear the current record
FUNCTION suppliers_clear_curr()
   INITIALIZE curr_suppliers.* TO NULL
END FUNCTION #suppliers_clear_curr

-- Query: CONSTRUCT + load
FUNCTION suppliers_do_query()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL suppliers_clear_curr()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON suppliers.supplierid, suppliers.companyname, suppliers.contactname,
                              suppliers.contacttitle, suppliers.address, suppliers.city,
                              suppliers.region, suppliers.postalcode, suppliers.country,
                              suppliers.phone, suppliers.fax, suppliers.homepage
       FROM s_suppliers.*
        ON ACTION accept
            ACCEPT CONSTRUCT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL suppliers_clear_curr()
       CALL suppliers_arr.clear()
       RETURN
    END IF

    CALL suppliers_do_load(where_clause)

    IF suppliers_arr.getLength() == 0 THEN
        MESSAGE "No suppliers found."
    END IF

END FUNCTION #suppliers_do_query

-- Load records from database into array
FUNCTION suppliers_do_load(where_clause VARCHAR(500))
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE temp_supplier t_supplier

    LET sql_stmt = " SELECT supplierid, companyname, contactname, contacttitle,",
                   " address, city, region, postalcode, country, phone, fax, homepage",
                   " FROM suppliers",
                   " WHERE ", where_clause CLIPPED, " ORDER BY companyname"

    CALL suppliers_arr.clear()

    PREPARE p_suppliers FROM sql_stmt
    DECLARE c_suppliers CURSOR FOR p_suppliers
    FOREACH c_suppliers INTO temp_supplier.*
        CALL suppliers_arr.appendElement()
        LET suppliers_arr[suppliers_arr.getLength()] = temp_supplier
    END FOREACH
    CALL suppliers_clear_curr()

END FUNCTION #suppliers_do_load

-- =====================================================================
-- Dispatch interface: suppliers_do_add_edit
-- =====================================================================
FUNCTION suppliers_do_add_edit(mode CHAR(1))

    CLEAR FORM
    LET int_flag = FALSE
    IF mode == "A" THEN
        CALL suppliers_clear_curr()
    END IF

    INPUT BY NAME curr_suppliers.*
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS=TRUE)
        BEFORE INPUT
            CALL DIALOG.setFieldActive("supplierid", FALSE)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            VAR valid_status = curr_suppliers.validateRec(mode)
            IF NOT valid_status.valid_status THEN
                ERROR valid_status.valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       IF mode = "A" THEN
          ERROR "Supplier add canceled"
       ELSE
          ERROR "Supplier update canceled"
       END IF
       RETURN
    END IF

    VAR rec_status t_valid_rec
    IF mode = "A" THEN
        LET rec_status = curr_suppliers.insertRec()
    ELSE
        LET rec_status = curr_suppliers.updateRec()
    END IF

    IF rec_status.valid_status THEN
        CALL suppliers_display_curr()
        MESSAGE rec_status.valid_msg
    ELSE
        ERROR rec_status.valid_msg
        LET int_flag = TRUE
    END IF

END FUNCTION #suppliers_do_add_edit

-- Delete a supplier
FUNCTION suppliers_do_delete()

    LET int_flag = FALSE
    IF NOT dialog_prompt.delete_prompt() THEN
        ERROR "Supplier delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    VAR del_status = curr_suppliers.deleteRec()
    IF NOT del_status.valid_status THEN
       ERROR del_status.valid_msg
       LET int_flag = TRUE
       RETURN
    END IF

    MESSAGE del_status.valid_msg

END FUNCTION #suppliers_do_delete

-- Refresh the array after add/change/delete
FUNCTION suppliers_do_refresh(currIdx INTEGER, operation CHAR(1))
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL suppliers_arr.appendElement()
         LET suppliers_arr[suppliers_arr.getLength()] = curr_suppliers
      WHEN "C"
         LET suppliers_arr[currIdx] = curr_suppliers
      WHEN "D"
         FOR idx = 1 TO suppliers_arr.getLength()
            IF suppliers_arr[idx].supplierid = curr_suppliers.supplierid THEN
               CALL suppliers_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #suppliers_do_refresh

-- DISPLAY ARRAY for list view (called by controller via dispatch)
FUNCTION suppliers_list_display() RETURNS (INTEGER, INTEGER)
   DEFINE selectedIdx    INTEGER
   DEFINE selectedOption INTEGER

   LET selectedIdx = 0
   LET selectedOption = 0

   DISPLAY ARRAY suppliers_arr TO suppliers_list.*
       ON ACTION add
           LET selectedOption = cAddRecord
           EXIT DISPLAY
       ON ACTION modify
           LET selectedIdx = ARR_CURR()
           LET selectedOption = cEditRecord
           EXIT DISPLAY
       ON ACTION delete
           LET selectedIdx = ARR_CURR()
           LET selectedOption = cDeleteRecord
           EXIT DISPLAY
       ON ACTION exit
           LET int_flag = TRUE
           EXIT DISPLAY
       ON ACTION accept
           LET selectedIdx = ARR_CURR()
           LET selectedOption = cViewRecord
           EXIT DISPLAY
   END DISPLAY

   RETURN selectedIdx, selectedOption

END FUNCTION #suppliers_list_display

-- =====================================================================
-- Function: suppliers_do_command
-- Purpose : Execute a view command for suppliers (none available)
-- =====================================================================
FUNCTION suppliers_do_command(commandName STRING)
   ERROR "Unknown command: ", commandName

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #suppliers_do_command

