IMPORT FGL list_view_helper
IMPORT FGL controller

DATABASE northwind

TYPE t_shipper RECORD
   shipperid SMALLINT,
   companyname VARCHAR(40),
   phone VARCHAR(24)
END RECORD

DEFINE shippers_arr DYNAMIC ARRAY OF t_shipper
DEFINE curr_shippers t_shipper

-- =====================================================================
-- Function: get_config
-- Purpose : Return the controller configuration for shippers
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS t_controller_config
   DEFINE cfg t_controller_config
   LET cfg.moduleName   = "shippers"
   LET cfg.formName     = "shippers"
   LET cfg.listFormName = "shippers_list"
   LET cfg.windowTitle  = "Shippers Management"
   LET cfg.hasModify    = TRUE
   LET cfg.hasQuery     = TRUE
   LET cfg.hasLookup    = TRUE
   LET cfg.entityName   = "Shipper"
   RETURN cfg
END FUNCTION #get_config

-- =====================================================================
-- Function: view_shipper
-- Purpose : View a specific shipper record (called from other modules)
-- =====================================================================
FUNCTION view_shipper(ship_id)
   DEFINE ship_id LIKE shippers.shipperid
   DEFINE where_clause VARCHAR(500)

   IF ship_id IS NULL OR ship_id < 1 THEN
      ERROR "Shipper ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewShipperWindow WITH FORM "shippers"
      ATTRIBUTES(STYLE="modulewindow")

   LET where_clause = " shippers.shipperid = ", ship_id
   CALL shippers_do_load(where_clause)

   IF shippers_arr.getLength() == 0 THEN
      CLOSE WINDOW viewShipperWindow
      ERROR "Shipper not found"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate_view()

   CLOSE WINDOW viewShipperWindow

END FUNCTION #view_shipper

-- =====================================================================
-- Function: submenu_shippers
-- Purpose : Standard entry point — query then navigate using controller
-- =====================================================================
FUNCTION submenu_shippers()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_shippers

-- =====================================================================
-- Dispatch Interface: Functions called by the controller via dispatch
-- =====================================================================

-- Return the number of records in the result set
FUNCTION shippers_get_count() RETURNS INTEGER
   RETURN shippers_arr.getLength()
END FUNCTION #shippers_get_count

-- Load the record at index into the current record
FUNCTION shippers_load_at(idx INTEGER)
   INITIALIZE curr_shippers.* TO NULL
   IF idx > 0 AND idx <= shippers_arr.getLength() THEN
      LET curr_shippers = shippers_arr[idx]
   END IF
END FUNCTION #shippers_load_at

-- Display the current record on the form
FUNCTION shippers_display_curr()
   DISPLAY BY NAME curr_shippers.*
END FUNCTION #shippers_display_curr

-- Clear the current record and form
FUNCTION shippers_clear_curr()
   INITIALIZE curr_shippers.* TO NULL
END FUNCTION #shippers_clear_curr

-- =====================================================================
-- Function: shippers_do_query
-- Purpose : Search using CONSTRUCT and load results
-- =====================================================================
FUNCTION shippers_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL shippers_clear_curr()
   LET int_flag = FALSE
   CONSTRUCT where_clause ON shippers.shipperid, shippers.companyname, shippers.phone
      FROM s_shippers.*
      ON ACTION accept
          ACCEPT CONSTRUCT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL shippers_clear_curr()
      CALL shippers_arr.clear()
      RETURN
   END IF

   CALL shippers_do_load(where_clause)

   IF shippers_arr.getLength() == 0 THEN
      MESSAGE "No shippers found."
   END IF

END FUNCTION #shippers_do_query

-- =====================================================================
-- Function: shippers_do_load
-- Purpose : Load shippers into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION shippers_do_load(where_clause VARCHAR(500))
   DEFINE sql_stmt VARCHAR(1024)
   DEFINE temp_shipper t_shipper

   LET sql_stmt = " SELECT shipperid, companyname, phone",
                  " FROM shippers",
                  " WHERE ", where_clause CLIPPED, " ORDER BY companyname"

   CALL shippers_arr.clear()

   PREPARE p_shippers FROM sql_stmt
   DECLARE c_shippers CURSOR FOR p_shippers
   FOREACH c_shippers INTO temp_shipper.*
      CALL shippers_arr.appendElement()
      LET shippers_arr[shippers_arr.getLength()] = temp_shipper
   END FOREACH

END FUNCTION #shippers_do_load

-- =====================================================================
-- Function: shippers_do_add
-- Purpose : Add a new shipper record
-- =====================================================================
FUNCTION shippers_do_add()
   DEFINE shippers_valid SMALLINT
   DEFINE valid_msg CHAR(75)

   CLEAR FORM
   LET int_flag = FALSE
   CALL shippers_clear_curr()
   INPUT curr_shippers.* WITHOUT DEFAULTS FROM s_shippers.*
      ATTRIBUTES(UNBUFFERED)
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT
      AFTER INPUT
          CALL shippers_validate("A")
             RETURNING shippers_valid, valid_msg
          IF NOT shippers_valid THEN
              ERROR valid_msg
              CONTINUE INPUT
          END IF
   END INPUT

   IF int_flag THEN
      ERROR "Shipper add canceled"
      RETURN
   END IF

   INSERT INTO shippers (shipperid, companyname, phone)
      VALUES (DEFAULT, curr_shippers.companyname, curr_shippers.phone)
   LET curr_shippers.shipperid = sqlca.sqlerrd[2]
   CALL shippers_display_curr()
   MESSAGE "Shipper record added"

END FUNCTION #shippers_do_add

-- =====================================================================
-- Function: shippers_do_edit
-- Purpose : Edit an existing shipper record
-- =====================================================================
FUNCTION shippers_do_edit()
   DEFINE shippers_valid SMALLINT
   DEFINE valid_msg CHAR(75)

   LET int_flag = FALSE
   INPUT BY NAME curr_shippers.companyname, curr_shippers.phone
      ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT
      AFTER INPUT
          CALL shippers_validate("C")
             RETURNING shippers_valid, valid_msg
          IF NOT shippers_valid THEN
              ERROR valid_msg
              CONTINUE INPUT
          END IF
   END INPUT

   IF int_flag THEN
      ERROR "Shipper update canceled"
      RETURN
   END IF

   UPDATE shippers
      SET companyname = curr_shippers.companyname,
          phone = curr_shippers.phone
    WHERE shipperid = curr_shippers.shipperid
   MESSAGE "Shipper record updated"

END FUNCTION #shippers_do_edit

-- =====================================================================
-- Function: shippers_do_delete
-- Purpose : Delete a shipper record
-- =====================================================================
FUNCTION shippers_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "Shipper delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   DELETE FROM shippers
    WHERE shipperid = curr_shippers.shipperid
   MESSAGE "Shipper record deleted"

END FUNCTION #shippers_do_delete

-- =====================================================================
-- Function: shippers_do_refresh
-- Purpose : Refresh the array after add, change, or delete
-- =====================================================================
FUNCTION shippers_do_refresh(currIdx INTEGER, operation CHAR(1))
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL shippers_arr.appendElement()
         LET shippers_arr[shippers_arr.getLength()] = curr_shippers
      WHEN "C"
         LET shippers_arr[currIdx] = curr_shippers
      WHEN "D"
         FOR idx = 1 TO shippers_arr.getLength()
            IF shippers_arr[idx].shipperid = curr_shippers.shipperid THEN
               CALL shippers_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #shippers_do_refresh

-- =====================================================================
-- Function: shippers_list_display
-- Purpose : DISPLAY ARRAY list view for shippers
-- =====================================================================
FUNCTION shippers_list_display() RETURNS (INTEGER, INTEGER)
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   LET selectedIdx = 0
   LET selectedOption = 0
   LET int_flag = FALSE

   MESSAGE "Displayed ", shippers_arr.getLength() USING "<<<<<", " shippers"

   DISPLAY ARRAY shippers_arr TO shippers_list.*
      ON ACTION add
         LET selectedOption = cAddRecord
         EXIT DISPLAY
      ON ACTION modify
         LET selectedOption = cEditRecord
         LET selectedIdx = ARR_CURR()
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

END FUNCTION #shippers_list_display

-- =====================================================================
-- Function: shippers_validate
-- Purpose : Validate the current shipper record
-- =====================================================================
FUNCTION shippers_validate(mode CHAR(1)) RETURNS (SMALLINT, CHAR(75))
   DEFINE shipperExists SMALLINT

   IF mode == "C" THEN
      SELECT 1 INTO shipperExists FROM shippers WHERE shippers.shipperid = curr_shippers.shipperid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Shipper ID is not found"
      END IF
   END IF
   IF curr_shippers.companyname IS NULL OR LENGTH(curr_shippers.companyname) == 0 THEN
      RETURN FALSE, "Company Name is required"
   END IF

   IF NVL(curr_shippers.phone, "NULL") == "NULL" THEN
      RETURN FALSE, "Phone number is required"
   END IF

   RETURN TRUE, "Okay"

END FUNCTION #shippers_validate

-- =====================================================================
-- Function: shipper_lookup
-- Purpose : Open a lookup window for shipper selection
-- =====================================================================
FUNCTION shipper_lookup()
   DEFINE ship_id LIKE shippers.shipperid
   DEFINE ship_name LIKE shippers.companyname

   OPEN WINDOW lookupWindow WITH FORM "shippers"
      ATTRIBUTES(STYLE="modulewindow")

   CALL shipper_lookup_menu()
      RETURNING ship_id, ship_name

   CLOSE WINDOW lookupWindow

   RETURN ship_id, ship_name

END FUNCTION #shipper_lookup

-- =====================================================================
-- Function: shipper_lookup_menu
-- Purpose : Navigation menu for shipper lookup selection
-- =====================================================================
FUNCTION shipper_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL shippers_do_query()
   IF shippers_arr.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= shippers_arr.getLength() AND selectedIdx == 0

       CALL shippers_load_at(currentIdx)
       CALL shippers_display_curr()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", shippers_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Shipper Selection"
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
              IF currentIdx > shippers_arr.getLength() THEN
                 LET currentIdx = shippers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = shippers_arr.getLength()
              EXIT MENU
          COMMAND "Select" "Select the current shipper"
              LET selectedIdx = currentIdx
              CALL shippers_load_at(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_shippers.shipperid, curr_shippers.companyname
   END IF

   RETURN 0, ""

END FUNCTION #shipper_lookup_menu
