IMPORT FGL list_view_helper
IMPORT FGL controller

DATABASE northwind

-- =====================================================================
-- Record Type Definitions
-- =====================================================================
TYPE t_supplier RECORD
   supplierid LIKE suppliers.supplierid,
   companyname LIKE suppliers.companyname,
   contactname LIKE suppliers.contactname,
   contacttitle LIKE suppliers.contacttitle,
   address LIKE suppliers.address,
   city LIKE suppliers.city,
   region LIKE suppliers.region,
   postalcode LIKE suppliers.postalcode,
   country LIKE suppliers.country,
   phone LIKE suppliers.phone,
   fax LIKE suppliers.fax,
   homepage LIKE suppliers.homepage
END RECORD

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

-- Add a new supplier
FUNCTION suppliers_do_add()
    DEFINE suppliers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL suppliers_clear_curr()
    INPUT BY NAME curr_suppliers.*
        ATTRIBUTE(UNBUFFERED)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL suppliers_validate("A")
               RETURNING suppliers_valid, valid_msg
            IF NOT suppliers_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Supplier add canceled"
       RETURN
    END IF

    INSERT INTO suppliers (supplierid, companyname, contactname, contacttitle,
                           address, city, region, postalcode, country, phone, fax, homepage)
       VALUES (DEFAULT, curr_suppliers.companyname, curr_suppliers.contactname,
               curr_suppliers.contacttitle, curr_suppliers.address, curr_suppliers.city,
               curr_suppliers.region, curr_suppliers.postalcode, curr_suppliers.country,
               curr_suppliers.phone, curr_suppliers.fax, curr_suppliers.homepage)
    LET curr_suppliers.supplierid = sqlca.sqlerrd[2]
    CALL suppliers_display_curr()
    MESSAGE "Supplier record added"

END FUNCTION #suppliers_do_add

-- Edit an existing supplier
FUNCTION suppliers_do_edit()
    DEFINE suppliers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_suppliers.companyname, curr_suppliers.contactname, curr_suppliers.contacttitle,
                  curr_suppliers.address, curr_suppliers.city, curr_suppliers.region,
                  curr_suppliers.postalcode, curr_suppliers.country, curr_suppliers.phone,
                  curr_suppliers.fax, curr_suppliers.homepage
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL suppliers_validate("C")
               RETURNING suppliers_valid, valid_msg
            IF NOT suppliers_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Supplier update canceled"
       RETURN
    END IF

    UPDATE suppliers
       SET companyname = curr_suppliers.companyname,
           contactname = curr_suppliers.contactname,
           contacttitle = curr_suppliers.contacttitle,
           address = curr_suppliers.address,
           city = curr_suppliers.city,
           region = curr_suppliers.region,
           postalcode = curr_suppliers.postalcode,
           country = curr_suppliers.country,
           phone = curr_suppliers.phone,
           fax = curr_suppliers.fax,
           homepage = curr_suppliers.homepage
     WHERE supplierid = curr_suppliers.supplierid
    MESSAGE "Supplier record updated"

END FUNCTION #suppliers_do_edit

-- Delete a supplier
FUNCTION suppliers_do_delete()

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
        ERROR "Supplier delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    DELETE FROM suppliers
     WHERE supplierid = curr_suppliers.supplierid
    MESSAGE "Supplier record deleted"

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

-- Validate the current record
FUNCTION suppliers_validate(mode CHAR(1)) RETURNS (SMALLINT, CHAR(75))
   DEFINE supplierExists SMALLINT

   IF mode == "C" THEN
      SELECT 1 INTO supplierExists FROM suppliers WHERE suppliers.supplierid = curr_suppliers.supplierid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Supplier ID is not found"
      END IF
   END IF
   IF curr_suppliers.companyname IS NULL OR LENGTH(curr_suppliers.companyname) == 0 THEN
      RETURN FALSE, "Company Name is required"
   END IF

   RETURN TRUE, "Okay"
END FUNCTION #suppliers_validate

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

-- =====================================================================
-- Function: supplier_lookup
-- Purpose : Open a lookup window for supplier selection
-- =====================================================================
FUNCTION supplier_lookup()
   DEFINE supp_id LIKE suppliers.supplierid
   DEFINE supp_name LIKE suppliers.companyname

   OPEN WINDOW lookupWindow WITH FORM "suppliers"
      ATTRIBUTES(STYLE="modulewindow")

   CALL supplier_lookup_menu()
      RETURNING supp_id, supp_name

   CLOSE WINDOW lookupWindow

   RETURN supp_id, supp_name

END FUNCTION #supplier_lookup

FUNCTION supplier_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL suppliers_do_query()
   IF suppliers_arr.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= suppliers_arr.getLength() AND selectedIdx == 0

       CALL suppliers_load_at(currentIdx)
       CALL suppliers_display_curr()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", suppliers_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Supplier Selection"
          COMMAND "First" "View first record in result set"
              LET currentIdx = 1
              EXIT MENU
          COMMAND "Previous" "View previous record in result set"
              LET currentIdx = currentIdx - 1
              IF currentIdx < 1 THEN
                 LET currentIdx = 1
              END IF
              EXIT MENU
          COMMAND "Next" "View next record in result set"
              LET currentIdx = currentIdx + 1
              IF currentIdx > suppliers_arr.getLength() THEN
                 LET currentIdx = suppliers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = suppliers_arr.getLength()
              EXIT MENU
          COMMAND "Select" "Select the current supplier"
              LET selectedIdx = currentIdx
              CALL suppliers_load_at(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_suppliers.supplierid, curr_suppliers.companyname
   END IF

   RETURN 0, ""

END FUNCTION #supplier_lookup_menu
