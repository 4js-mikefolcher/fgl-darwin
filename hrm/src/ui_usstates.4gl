IMPORT FGL main_lib
IMPORT FGL dialog_prompt
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_usstates
IMPORT FGL model_helper

DATABASE northwind

DEFINE usstates_arr DYNAMIC ARRAY OF t_usstate
DEFINE curr_usstates t_usstate

-- =====================================================================
-- Function: get_config
-- Purpose : Return the controller configuration for US states
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS t_controller_config
   DEFINE cfg t_controller_config
   LET cfg.moduleName   = "usstates"
   LET cfg.formName     = "usstates"
   LET cfg.listFormName = "usstates_list"
   LET cfg.windowTitle  = "US States Management"
   LET cfg.hasModify    = TRUE
   LET cfg.hasQuery     = TRUE
   LET cfg.hasLookup    = FALSE
   LET cfg.entityName   = "State"
   RETURN cfg
END FUNCTION #get_config

-- =====================================================================
-- Function: submenu_usstates
-- Purpose : Standard entry point — query then navigate using controller
-- =====================================================================
FUNCTION submenu_usstates()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_usstates

-- =====================================================================
-- Function: root_add_usstates
-- Purpose : Entry point for US states add from root menu
-- =====================================================================
FUNCTION root_add_usstates()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_usstates

-- =====================================================================
-- Dispatch Interface: Functions called by the controller via dispatch
-- =====================================================================

-- Return the number of records in the result set
FUNCTION usstates_get_count() RETURNS INTEGER
   RETURN usstates_arr.getLength()
END FUNCTION #usstates_get_count

-- Load the record at index into the current record
FUNCTION usstates_load_at(idx INTEGER)
   INITIALIZE curr_usstates.* TO NULL
   IF idx > 0 AND idx <= usstates_arr.getLength() THEN
      LET curr_usstates = usstates_arr[idx]
   END IF
END FUNCTION #usstates_load_at

-- Display the current record on the form
FUNCTION usstates_display_curr()
   DISPLAY BY NAME curr_usstates.*
END FUNCTION #usstates_display_curr

-- Clear the current record and form
FUNCTION usstates_clear_curr()
   INITIALIZE curr_usstates.* TO NULL
END FUNCTION #usstates_clear_curr

-- =====================================================================
-- Function: usstates_do_query
-- Purpose : Search using CONSTRUCT and load results
-- =====================================================================
FUNCTION usstates_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL usstates_clear_curr()
   LET int_flag = FALSE
   CONSTRUCT where_clause ON usstates.stateid, usstates.statename, usstates.stateabbr, usstates.stateregion
      FROM s_usstates.*
      ON ACTION accept
          ACCEPT CONSTRUCT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL usstates_clear_curr()
      CALL usstates_arr.clear()
      RETURN
   END IF

   CALL usstates_do_load(where_clause)

   IF usstates_arr.getLength() == 0 THEN
      MESSAGE "No states found."
   END IF

END FUNCTION #usstates_do_query

-- =====================================================================
-- Function: usstates_do_load
-- Purpose : Load states into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION usstates_do_load(where_clause VARCHAR(500))
   DEFINE sql_stmt VARCHAR(1024)
   DEFINE temp_usstate t_usstate

   LET sql_stmt = " SELECT stateid, statename, stateabbr, stateregion",
                  " FROM usstates",
                  " WHERE ", where_clause CLIPPED, " ORDER BY statename"

   CALL usstates_arr.clear()

   PREPARE p_usstates FROM sql_stmt
   DECLARE c_usstates CURSOR FOR p_usstates
   FOREACH c_usstates INTO temp_usstate.*
      CALL usstates_arr.appendElement()
      LET usstates_arr[usstates_arr.getLength()] = temp_usstate
   END FOREACH

END FUNCTION #usstates_do_load

-- =====================================================================
-- Function: usstates_do_add_edit
-- Purpose : Add or edit a state record
-- =====================================================================
FUNCTION usstates_do_add_edit(mode CHAR(1))

   CLEAR FORM
   LET int_flag = FALSE
   IF mode == "A" THEN
      CALL usstates_clear_curr()
   END IF

   INPUT BY NAME curr_usstates.*
      ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS=TRUE)
      BEFORE INPUT
         CALL DIALOG.setFieldActive("stateid", FALSE)
         IF mode == "C" THEN
            CALL DIALOG.setFieldActive("statename", FALSE)
            CALL DIALOG.setFieldActive("stateabbr", FALSE)
            CALL DIALOG.setFieldActive("stateregion", FALSE)
         END IF
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         VAR valid_status = curr_usstates.validateRec(mode)
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      IF mode = "A" THEN
         ERROR "State add canceled"
      ELSE
         ERROR "State update canceled"
      END IF
      RETURN
   END IF

   VAR rec_status t_valid_rec
   IF mode = "A" THEN
      LET rec_status = curr_usstates.insertRec()
   ELSE
      LET rec_status = curr_usstates.updateRec()
   END IF

   IF rec_status.valid_status THEN
      CALL usstates_display_curr()
      MESSAGE rec_status.valid_msg
   ELSE
      ERROR rec_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #usstates_do_add_edit

-- =====================================================================
-- Function: usstates_do_delete
-- Purpose : Delete a state record
-- =====================================================================
FUNCTION usstates_do_delete()

   LET int_flag = FALSE
   IF NOT dialog_prompt.delete_prompt() THEN
      ERROR "State delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_usstates.deleteRec()
   IF del_status.valid_status THEN
      MESSAGE del_status.valid_msg
   ELSE
      ERROR del_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #usstates_do_delete

-- =====================================================================
-- Function: usstates_do_refresh
-- Purpose : Refresh the array after add, change, or delete
-- =====================================================================
FUNCTION usstates_do_refresh(currIdx INTEGER, operation CHAR(1))
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL usstates_arr.appendElement()
         LET usstates_arr[usstates_arr.getLength()] = curr_usstates
      WHEN "C"
         LET usstates_arr[currIdx] = curr_usstates
      WHEN "D"
         FOR idx = 1 TO usstates_arr.getLength()
            IF usstates_arr[idx].stateid = curr_usstates.stateid THEN
               CALL usstates_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #usstates_do_refresh

-- =====================================================================
-- Function: usstates_list_display
-- Purpose : DISPLAY ARRAY list view for states
-- =====================================================================
FUNCTION usstates_list_display() RETURNS (INTEGER, INTEGER)
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   LET selectedIdx = 0
   LET selectedOption = 0
   LET int_flag = FALSE

   MESSAGE "Displayed ", usstates_arr.getLength() USING "<<<<<", " states"

   DISPLAY ARRAY usstates_arr TO usstates_list.*
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

END FUNCTION #usstates_list_display

-- =====================================================================
-- Function: usstates_do_command
-- Purpose : Execute a view command for US states (none available)
-- =====================================================================
FUNCTION usstates_do_command(commandName STRING)
   ERROR "Unknown command: ", commandName

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #usstates_do_command


