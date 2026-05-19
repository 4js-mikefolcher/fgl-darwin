IMPORT FGL main_lib
IMPORT FGL dialog_prompt
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_shippers
IMPORT FGL model_helper

DATABASE northwind

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
-- Function: submenu_shippers
-- Purpose : Standard entry point — query then navigate using controller
-- =====================================================================
FUNCTION submenu_shippers()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_shippers

-- =====================================================================
-- Function: root_add_shippers
-- Purpose : Entry point for shippers add from root menu
-- =====================================================================
FUNCTION root_add_shippers()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_shippers

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
-- Function: shippers_do_add_edit
-- Purpose : Add or edit a shipper record
-- =====================================================================
FUNCTION shippers_do_add_edit(mode CHAR(1))

   CLEAR FORM
   LET int_flag = FALSE
   IF mode == "A" THEN
      CALL shippers_clear_curr()
   END IF

   INPUT BY NAME curr_shippers.*
      ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS=TRUE)
      BEFORE INPUT
         CALL DIALOG.setFieldActive("shipperid", FALSE)
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         VAR valid_status = curr_shippers.validateRec(mode)
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      IF mode = "A" THEN
         ERROR "Shipper add canceled"
      ELSE
         ERROR "Shipper update canceled"
      END IF
      RETURN
   END IF

   VAR rec_status t_valid_rec
   IF mode = "A" THEN
      LET rec_status = curr_shippers.insertRec()
   ELSE
      LET rec_status = curr_shippers.updateRec()
   END IF

   IF rec_status.valid_status THEN
      CALL shippers_display_curr()
      MESSAGE rec_status.valid_msg
   ELSE
      ERROR rec_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #shippers_do_add_edit

-- =====================================================================
-- Function: shippers_do_delete
-- Purpose : Delete a shipper record
-- =====================================================================
FUNCTION shippers_do_delete()

   LET int_flag = FALSE
   IF NOT dialog_prompt.delete_prompt() THEN
      ERROR "Shipper delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_shippers.deleteRec()
   IF NOT del_status.valid_status THEN
      ERROR del_status.valid_msg
      LET int_flag = TRUE
      RETURN
   END IF

   MESSAGE del_status.valid_msg

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
-- Function: shippers_do_command
-- Purpose : Execute a view command for shippers (none available)
-- =====================================================================
FUNCTION shippers_do_command(commandName STRING)
   ERROR "Unknown command: ", commandName

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #shippers_do_command

