IMPORT FGL main_lib
IMPORT FGL dialog_prompt
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_cust_demo
IMPORT FGL ui_cust_cust_demo
IMPORT FGL model_helper

DATABASE northwind

DEFINE cust_demo_arr DYNAMIC ARRAY OF t_cust_demo
DEFINE curr_cust_demo t_cust_demo

-- =====================================================================
-- Function: get_config
-- Purpose : Return the controller configuration for customer demographics
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS t_controller_config
   DEFINE cfg t_controller_config
   LET cfg.moduleName   = "cust_demo"
   LET cfg.formName     = "cust_demo"
   LET cfg.listFormName = "cust_demo_list"
   LET cfg.windowTitle  = "Customer Demographics Management"
   LET cfg.hasModify    = TRUE
   LET cfg.hasQuery     = TRUE
   LET cfg.hasLookup    = TRUE
   LET cfg.entityName   = "Customer Demographic"
   -- View commands available for this module
   LET cfg.availableCommands = init_view_commands()
   RETURN cfg
END FUNCTION #get_config

-- =====================================================================
-- Function: init_view_commands (PRIVATE)
-- Purpose : Define which view commands are available for customer demographics
-- =====================================================================
PRIVATE FUNCTION init_view_commands() RETURNS DYNAMIC ARRAY OF t_view_command
   DEFINE cmds DYNAMIC ARRAY OF t_view_command
   LET cmds[1].commandName  = "cust_cust_demo"
   LET cmds[1].commandLabel = "Customer Assignments"
   LET cmds[1].commandComment = "View Customers assigned to this Type"
   RETURN cmds
END FUNCTION #init_view_commands

-- =====================================================================
-- Function: submenu_cust_demo
-- Purpose : Standard entry point — query then navigate using controller
-- =====================================================================
FUNCTION submenu_cust_demo()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_cust_demo

-- =====================================================================
-- Function: root_add_cust_demo
-- Purpose : Entry point for customer demographics add from root menu
-- =====================================================================
FUNCTION root_add_cust_demo()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_cust_demo

-- =====================================================================
-- Dispatch Interface: Functions called by the controller via dispatch
-- =====================================================================

-- Return the number of records in the result set
FUNCTION cust_demo_get_count() RETURNS INTEGER
   RETURN cust_demo_arr.getLength()
END FUNCTION #cust_demo_get_count

-- Load the record at index into the current record
FUNCTION cust_demo_load_at(idx INTEGER)
   INITIALIZE curr_cust_demo.* TO NULL
   IF idx > 0 AND idx <= cust_demo_arr.getLength() THEN
      LET curr_cust_demo = cust_demo_arr[idx]
   END IF
END FUNCTION #cust_demo_load_at

-- Display the current record on the form
FUNCTION cust_demo_display_curr()
   DISPLAY BY NAME curr_cust_demo.*
END FUNCTION #cust_demo_display_curr

-- Clear the current record and form
FUNCTION cust_demo_clear_curr()
   INITIALIZE curr_cust_demo.* TO NULL
END FUNCTION #cust_demo_clear_curr

-- =====================================================================
-- Function: cust_demo_do_query
-- Purpose : Search using CONSTRUCT and load results
-- =====================================================================
FUNCTION cust_demo_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL cust_demo_clear_curr()
   LET int_flag = FALSE
   CONSTRUCT where_clause ON customerdemographics.customertypeid,
                             customerdemographics.customerdesc
      FROM s_cust_demo.*
      ON ACTION accept
          ACCEPT CONSTRUCT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL cust_demo_clear_curr()
      CALL cust_demo_arr.clear()
      RETURN
   END IF

   CALL cust_demo_do_load(where_clause)

   IF cust_demo_arr.getLength() == 0 THEN
      MESSAGE "No customer demographics found."
   END IF

END FUNCTION #cust_demo_do_query

-- =====================================================================
-- Function: cust_demo_do_load
-- Purpose : Load customer demographics into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION cust_demo_do_load(where_clause VARCHAR(500))
   DEFINE sql_stmt VARCHAR(1024)
   DEFINE temp_rec t_cust_demo

   LET sql_stmt = " SELECT customertypeid, customerdesc",
                  " FROM customerdemographics",
                  " WHERE ", where_clause CLIPPED, " ORDER BY customertypeid"

   CALL cust_demo_arr.clear()

   PREPARE p_cust_demo FROM sql_stmt
   DECLARE c_cust_demo CURSOR FOR p_cust_demo
   FOREACH c_cust_demo INTO temp_rec.*
      CALL cust_demo_arr.appendElement()
      LET cust_demo_arr[cust_demo_arr.getLength()] = temp_rec
   END FOREACH

END FUNCTION #cust_demo_do_load

-- =====================================================================
-- Function: cust_demo_do_add_edit
-- Purpose : Add or edit a customer demographic record
-- =====================================================================
FUNCTION cust_demo_do_add_edit(mode CHAR(1))

   CLEAR FORM
   LET int_flag = FALSE
   IF mode == "A" THEN
      CALL cust_demo_clear_curr()
   END IF

   INPUT BY NAME curr_cust_demo.*
      ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS=TRUE)
      BEFORE INPUT
         IF mode == "C" THEN
            CALL DIALOG.setFieldActive("customertypeid", FALSE)
         END IF
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         VAR valid_status = curr_cust_demo.validateRec(mode)
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      IF mode = "A" THEN
         ERROR "Customer demographic add canceled"
      ELSE
         ERROR "Customer demographic update canceled"
      END IF
      RETURN
   END IF

   VAR rec_status t_valid_rec
   IF mode = "A" THEN
      LET rec_status = curr_cust_demo.insertRec()
   ELSE
      LET rec_status = curr_cust_demo.updateRec()
   END IF

   IF rec_status.valid_status THEN
      CALL cust_demo_display_curr()
      MESSAGE rec_status.valid_msg
   ELSE
      ERROR rec_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #cust_demo_do_add_edit

-- =====================================================================
-- Function: cust_demo_do_delete
-- Purpose : Delete a customer demographic record
-- =====================================================================
FUNCTION cust_demo_do_delete()

   LET int_flag = FALSE
   IF NOT dialog_prompt.delete_prompt() THEN
      ERROR "Customer demographic delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_cust_demo.deleteRec()
   IF NOT del_status.valid_status THEN
      ERROR del_status.valid_msg
      LET int_flag = TRUE
      RETURN
   END IF

   MESSAGE del_status.valid_msg

END FUNCTION #cust_demo_do_delete

-- =====================================================================
-- Function: cust_demo_do_refresh
-- Purpose : Refresh the array after add, change, or delete
-- =====================================================================
FUNCTION cust_demo_do_refresh(currIdx INTEGER, operation CHAR(1))
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL cust_demo_arr.appendElement()
         LET cust_demo_arr[cust_demo_arr.getLength()] = curr_cust_demo
      WHEN "C"
         LET cust_demo_arr[currIdx] = curr_cust_demo
      WHEN "D"
         FOR idx = 1 TO cust_demo_arr.getLength()
            IF cust_demo_arr[idx].customertypeid = curr_cust_demo.customertypeid THEN
               CALL cust_demo_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #cust_demo_do_refresh

-- =====================================================================
-- Function: cust_demo_list_display
-- Purpose : DISPLAY ARRAY list view for customer demographics
-- =====================================================================
FUNCTION cust_demo_list_display() RETURNS (INTEGER, INTEGER)
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   LET selectedIdx = 0
   LET selectedOption = 0
   LET int_flag = FALSE

   MESSAGE "Displayed ", cust_demo_arr.getLength() USING "<<<<<", " customer demographics"

   DISPLAY ARRAY cust_demo_arr TO cust_demo_list.*
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

END FUNCTION #cust_demo_list_display

-- =====================================================================
-- Function: cust_demo_do_command
-- Purpose : Execute a view command for customer demographics
-- =====================================================================
FUNCTION cust_demo_do_command(commandName STRING)
   CASE commandName
      WHEN "cust_cust_demo"
         CALL cust_demo_by_type(curr_cust_demo.customertypeid)
      OTHERWISE
         ERROR "Unknown command: ", commandName
   END CASE

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #cust_demo_do_command

-- =====================================================================
-- Function: cust_demo_lookup
-- Purpose : Open a lookup window for customer demographic selection
-- =====================================================================
FUNCTION cust_demo_lookup()
   DEFINE type_id LIKE customerdemographics.customertypeid
   DEFINE type_desc LIKE customerdemographics.customerdesc

   OPEN WINDOW lookupWindow WITH FORM "cust_demo"
      ATTRIBUTES(STYLE="modulewindow")

   CALL cust_demo_lookup_menu()
      RETURNING type_id, type_desc

   CLOSE WINDOW lookupWindow

   RETURN type_id, type_desc

END FUNCTION #cust_demo_lookup

-- =====================================================================
-- Function: cust_demo_lookup_menu
-- Purpose : Navigation menu for customer demographic lookup selection
-- =====================================================================
FUNCTION cust_demo_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL cust_demo_do_query()
   IF cust_demo_arr.getLength() == 0 THEN
      RETURN "", ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= cust_demo_arr.getLength() AND selectedIdx == 0

       CALL cust_demo_load_at(currentIdx)
       CALL cust_demo_display_curr()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", cust_demo_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Customer Demographic Selection"
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
              IF currentIdx > cust_demo_arr.getLength() THEN
                 LET currentIdx = cust_demo_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = cust_demo_arr.getLength()
              EXIT MENU
          COMMAND "Select" "Select the current customer demographic"
              LET selectedIdx = currentIdx
              CALL cust_demo_load_at(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_cust_demo.customertypeid, curr_cust_demo.customerdesc
   END IF

   RETURN "", ""

END FUNCTION #cust_demo_lookup_menu
