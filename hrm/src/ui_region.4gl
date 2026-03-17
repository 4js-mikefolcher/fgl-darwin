IMPORT FGL main_lib
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_region
IMPORT FGL ui_territories
IMPORT FGL model_helper
DATABASE northwind

TYPE t_region_list RECORD
   regionid LIKE region.regionid,
   regiondescription LIKE region.regiondescription
END RECORD

DEFINE region_arr DYNAMIC ARRAY OF t_region
DEFINE curr_region t_region

-- =====================================================================
-- Function: get_config (PRIVATE)
-- Purpose : Return controller configuration for region module
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS (t_controller_config)
   DEFINE cfg t_controller_config

   LET cfg.moduleName = "region"
   LET cfg.formName = "region"
   LET cfg.listFormName = "region_list"
   LET cfg.windowTitle = "Region Management"
   LET cfg.hasModify = TRUE
   LET cfg.hasQuery = TRUE
   LET cfg.hasLookup = TRUE
   LET cfg.entityName = "Region"
   -- View commands available for this module
   LET cfg.availableCommands = init_view_commands()

   RETURN cfg

END FUNCTION #get_config

-- =====================================================================
-- Function: init_view_commands (PRIVATE)
-- Purpose : Define which view commands are available for region
-- =====================================================================
PRIVATE FUNCTION init_view_commands() RETURNS DYNAMIC ARRAY OF t_view_command
   DEFINE cmds DYNAMIC ARRAY OF t_view_command
   LET cmds[1].commandName  = "territories"
   LET cmds[1].commandLabel = "Territories"
   LET cmds[1].commandComment = "View Territories in this Region"
   RETURN cmds
END FUNCTION #init_view_commands

-- =====================================================================
-- Function: view_region
-- Purpose : View a specific region record (called from other modules)
-- =====================================================================
FUNCTION view_region(reg_id)
   DEFINE reg_id LIKE region.regionid
   DEFINE where_clause VARCHAR(255)

   IF reg_id IS NULL OR reg_id < 1 THEN
      ERROR "Region ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewRegionWindow WITH FORM "region"
      ATTRIBUTES(STYLE="modulewindow")

   LET where_clause = " region.regionid = ", reg_id
   CALL region_do_load(where_clause)

   IF region_arr.getLength() == 0 THEN
      CLOSE WINDOW viewRegionWindow
      ERROR "Region not found"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate_view()

   CLOSE WINDOW viewRegionWindow

END FUNCTION #view_region

-- =====================================================================
-- Function: submenu_region
-- Purpose : Main entry point for region management
-- =====================================================================
FUNCTION submenu_region()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_region

-- =====================================================================
-- Function: root_add_region
-- Purpose : Entry point for region add from root menu
-- =====================================================================
FUNCTION root_add_region()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_region

-- =====================================================================
-- Dispatch interface: region_get_count
-- =====================================================================
FUNCTION region_get_count()

   RETURN region_arr.getLength()

END FUNCTION #region_get_count

-- =====================================================================
-- Dispatch interface: region_load_at
-- =====================================================================
FUNCTION region_load_at(idx)
   DEFINE idx INTEGER

   INITIALIZE curr_region.* TO NULL
   IF idx >= 1 AND idx <= region_arr.getLength() THEN
      LET curr_region = region_arr[idx]
   END IF

END FUNCTION #region_load_at

-- =====================================================================
-- Dispatch interface: region_display_curr
-- =====================================================================
FUNCTION region_display_curr()

   DISPLAY BY NAME curr_region.*

END FUNCTION #region_display_curr

-- =====================================================================
-- Dispatch interface: region_clear_curr
-- =====================================================================
FUNCTION region_clear_curr()

   INITIALIZE curr_region.* TO NULL

END FUNCTION #region_clear_curr

-- =====================================================================
-- Dispatch interface: region_do_query
-- =====================================================================
FUNCTION region_do_query()
   DEFINE where_clause VARCHAR(255)

   CLEAR FORM
   CALL region_clear_curr()
   LET int_flag = FALSE
   CONSTRUCT where_clause ON region.regionid, region.regiondescription
      FROM s_region.*
      ON ACTION accept
         ACCEPT CONSTRUCT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL region_clear_curr()
      CALL region_arr.clear()
      RETURN
   END IF

   CALL region_do_load(where_clause)

   IF region_arr.getLength() == 0 THEN
      MESSAGE "No regions found."
      RETURN
   END IF

END FUNCTION #region_do_query

-- =====================================================================
-- Function: region_do_load (PRIVATE)
-- Purpose : Load regions into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION region_do_load(where_clause)
   DEFINE where_clause VARCHAR(255)
   DEFINE sql_stmt VARCHAR(512)

   LET sql_stmt = "SELECT regionid, regiondescription FROM region WHERE ", where_clause, " ORDER BY regionid"

   CALL region_arr.clear()

   PREPARE p1 FROM sql_stmt
   DECLARE c1 CURSOR FOR p1
   FOREACH c1 INTO curr_region.*
      CALL region_arr.appendElement()
      LET region_arr[region_arr.getLength()] = curr_region
   END FOREACH
   CALL region_clear_curr()

END FUNCTION #region_do_load

-- =====================================================================
-- Dispatch interface: region_do_add_edit
-- =====================================================================
FUNCTION region_do_add_edit(mode CHAR(1))

   CLEAR FORM
   LET int_flag = FALSE
   CALL region_clear_curr()

   INPUT BY NAME curr_region.*
      ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS=TRUE)
      BEFORE INPUT
         CALL DIALOG.setFieldActive("regionid", FALSE)
         IF mode == "C" THEN
            CALL DIALOG.setFieldActive("regiondescription", FALSE)
         END IF
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         VAR valid_status = curr_region.validateRec(mode)
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      IF mode = "A" THEN
         ERROR "Region add canceled"
      ELSE
         ERROR "Region update canceled"
      END IF
      RETURN
   END IF

   VAR rec_status t_valid_rec
   IF mode = "A" THEN
      LET rec_status = curr_region.insertRec()
   ELSE
      LET rec_status = curr_region.updateRec()
   END IF

   IF rec_status.valid_status THEN
      CALL region_display_curr()
      MESSAGE rec_status.valid_msg
   ELSE
      ERROR rec_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #region_do_add_edit

-- =====================================================================
-- Dispatch interface: region_do_delete
-- =====================================================================
FUNCTION region_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "Region delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_region.deleteRec()
   IF del_status.valid_status THEN
      MESSAGE del_status.valid_msg
   ELSE
      ERROR del_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #region_do_delete

-- =====================================================================
-- Dispatch interface: region_do_refresh
-- =====================================================================
FUNCTION region_do_refresh(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL region_arr.appendElement()
         LET region_arr[region_arr.getLength()] = curr_region
      WHEN "C"
         LET region_arr[currIdx] = curr_region
      WHEN "D"
         FOR idx = 1 TO region_arr.getLength()
            IF region_arr[idx].regionid = curr_region.regionid THEN
               CALL region_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #region_do_refresh

-- =====================================================================
-- Dispatch interface: region_list_display
-- =====================================================================
FUNCTION region_list_display()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER
   DEFINE list_arr DYNAMIC ARRAY OF t_region_list
   DEFINE idx INTEGER

   FOR idx = 1 TO region_arr.getLength()
      CALL list_arr.appendElement()
      LET list_arr[idx].regionid = region_arr[idx].regionid
      LET list_arr[idx].regiondescription = region_arr[idx].regiondescription
   END FOR

   MESSAGE "Displayed ", list_arr.getLength() USING "<<<<<", " regions"

   DISPLAY ARRAY list_arr TO region_list.*
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

END FUNCTION #region_list_display

-- =====================================================================
-- Function: region_do_command
-- Purpose : Execute a view command for region
-- =====================================================================
FUNCTION region_do_command(commandName STRING)
   CASE commandName
      WHEN "territories"
         CALL view_territories_for_region(curr_region.regionid)
      OTHERWISE
         ERROR "Unknown command: ", commandName
   END CASE

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #region_do_command

-- =====================================================================
-- Function: region_lookup
-- Purpose : Open region lookup window, return selected region
-- =====================================================================
FUNCTION region_lookup()
   DEFINE region_id LIKE region.regionid
   DEFINE region_desc LIKE region.regiondescription

   OPEN WINDOW lookupWindow WITH FORM "region"
      ATTRIBUTES(STYLE="modulewindow")

   CALL region_lookup_menu()
      RETURNING region_id, region_desc

   CLOSE WINDOW lookupWindow

   RETURN region_id, region_desc

END FUNCTION #region_lookup

-- =====================================================================
-- Function: region_lookup_menu
-- Purpose : Navigate regions for selection
-- =====================================================================
FUNCTION region_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL region_do_query()
   IF region_arr.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= region_arr.getLength() AND selectedIdx == 0

      CALL region_load_at(currentIdx)
      CALL region_display_curr()
      LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", region_arr.getLength() USING "<<<<"
      MESSAGE statusMessage

      MENU "Region Selection"
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
            IF currentIdx > region_arr.getLength() THEN
               LET currentIdx = region_arr.getLength()
            END IF
            EXIT MENU
         COMMAND "Last" "View last record in result set"
            LET currentIdx = region_arr.getLength()
            EXIT MENU
         COMMAND "Select" "Select the current region"
            LET selectedIdx = currentIdx
            CALL region_load_at(selectedIdx)
            EXIT MENU
         COMMAND "Exit" "Quit operation"
            LET currentIdx = 0
            EXIT MENU
      END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_region.regionid, curr_region.regiondescription
   END IF

   RETURN 0, ""

END FUNCTION #region_lookup_menu


