IMPORT FGL list_view_helper
IMPORT FGL controller

DATABASE northwind

TYPE t_usstate RECORD
   stateid SMALLINT,
   statename VARCHAR(100),
   stateabbr VARCHAR(2),
   stateregion VARCHAR(50)
END RECORD

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
-- Function: usstates_do_add
-- Purpose : Add a new state record
-- =====================================================================
FUNCTION usstates_do_add()
   DEFINE usstates_valid SMALLINT
   DEFINE valid_msg CHAR(75)

   CLEAR FORM
   LET int_flag = FALSE
   CALL usstates_clear_curr()
   INPUT BY NAME curr_usstates.*
      ATTRIBUTES(UNBUFFERED)
      ON ACTION accept
          ACCEPT INPUT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT
      AFTER INPUT
          CALL usstates_validate("A")
             RETURNING usstates_valid, valid_msg
          IF NOT usstates_valid THEN
              ERROR valid_msg
              CONTINUE INPUT
          END IF
   END INPUT

   IF int_flag THEN
      ERROR "State add canceled"
      RETURN
   END IF

   INSERT INTO usstates (stateid, statename, stateabbr, stateregion)
      VALUES (DEFAULT, curr_usstates.statename, curr_usstates.stateabbr, curr_usstates.stateregion)
   LET curr_usstates.stateid = sqlca.sqlerrd[2]
   CALL usstates_display_curr()
   MESSAGE "State record added"

END FUNCTION #usstates_do_add

-- =====================================================================
-- Function: usstates_do_edit
-- Purpose : Edit an existing state record
-- =====================================================================
FUNCTION usstates_do_edit()
   DEFINE usstates_valid SMALLINT
   DEFINE valid_msg CHAR(75)

   LET int_flag = FALSE
   INPUT BY NAME curr_usstates.statename, curr_usstates.stateabbr, curr_usstates.stateregion
      ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)
      ON ACTION accept
          ACCEPT INPUT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT
      AFTER INPUT
          CALL usstates_validate("C")
             RETURNING usstates_valid, valid_msg
          IF NOT usstates_valid THEN
              ERROR valid_msg
              CONTINUE INPUT
          END IF
   END INPUT

   IF int_flag THEN
      ERROR "State update canceled"
      RETURN
   END IF

   UPDATE usstates
      SET statename = curr_usstates.statename,
          stateabbr = curr_usstates.stateabbr,
          stateregion = curr_usstates.stateregion
    WHERE stateid = curr_usstates.stateid
   MESSAGE "State record updated"

END FUNCTION #usstates_do_edit

-- =====================================================================
-- Function: usstates_do_delete
-- Purpose : Delete a state record
-- =====================================================================
FUNCTION usstates_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "State delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   DELETE FROM usstates
    WHERE stateid = curr_usstates.stateid
   MESSAGE "State record deleted"

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
-- Function: usstates_validate
-- Purpose : Validate the current state record
-- =====================================================================
FUNCTION usstates_validate(mode CHAR(1)) RETURNS (SMALLINT, CHAR(75))
   DEFINE stateExists SMALLINT

   IF mode == "C" THEN
      SELECT 1 INTO stateExists FROM usstates WHERE usstates.stateid = curr_usstates.stateid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "State ID is not found"
      END IF
   END IF

   RETURN TRUE, "Okay"

END FUNCTION #usstates_validate
