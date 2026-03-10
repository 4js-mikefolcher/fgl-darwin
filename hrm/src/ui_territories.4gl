IMPORT FGL main_lib
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_territories
IMPORT FGL ui_region
IMPORT FGL ui_employees
DATABASE northwind

DEFINE territories_arr DYNAMIC ARRAY OF t_territory
DEFINE curr_territories t_territory

-- =====================================================================
-- Function: get_config (PRIVATE)
-- Purpose : Return controller configuration for territories module
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS (t_controller_config)
   DEFINE cfg t_controller_config

   LET cfg.moduleName = "territories"
   LET cfg.formName = "territories"
   LET cfg.listFormName = "territories_list"
   LET cfg.windowTitle = "Territories Management"
   LET cfg.hasModify = TRUE
   LET cfg.hasQuery = TRUE
   LET cfg.hasLookup = TRUE
   LET cfg.entityName = "Territory"
   -- View commands available for this module
   LET cfg.availableCommands = init_view_commands()

   RETURN cfg

END FUNCTION #get_config

-- =====================================================================
-- Function: init_view_commands (PRIVATE)
-- Purpose : Define which view commands are available for territories
-- =====================================================================
PRIVATE FUNCTION init_view_commands() RETURNS DYNAMIC ARRAY OF t_view_command
   DEFINE cmds DYNAMIC ARRAY OF t_view_command
   LET cmds[1].commandName  = "region"
   LET cmds[1].commandLabel = "Region"
   LET cmds[1].commandComment = "View Region for this Territory"
   LET cmds[2].commandName  = "employees"
   LET cmds[2].commandLabel = "Employees"
   LET cmds[2].commandComment = "View Employees in this Territory"
   RETURN cmds
END FUNCTION #init_view_commands

-- =====================================================================
-- Function: submenu_territories
-- Purpose : Main entry point for territories management
-- =====================================================================
FUNCTION submenu_territories()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_territories

-- =====================================================================
-- Function: root_add_territories
-- Purpose : Entry point for territories add from root menu
-- =====================================================================
FUNCTION root_add_territories()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_territories

-- =====================================================================
-- Function: view_territory
-- Purpose : View a specific territory record (called from other modules)
-- =====================================================================
FUNCTION view_territory(terr_id)
   DEFINE terr_id LIKE territories.territoryid
   DEFINE where_clause VARCHAR(255)

   IF terr_id IS NULL OR LENGTH(terr_id) == 0 THEN
      ERROR "Territory ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewTerritoryWindow WITH FORM "territories"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_region_combo()
   LET where_clause = " territories.territoryid = '", terr_id CLIPPED, "'"
   CALL territories_do_load(where_clause)

   IF territories_arr.getLength() == 0 THEN
      CLOSE WINDOW viewTerritoryWindow
      ERROR "Territory not found"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate_view()

   CLOSE WINDOW viewTerritoryWindow

END FUNCTION #view_territory

-- =====================================================================
-- Function: view_territories_for_region
-- Purpose : View territories for a specific region
-- =====================================================================
FUNCTION view_territories_for_region(reg_id)
   DEFINE reg_id LIKE region.regionid
   DEFINE where_clause VARCHAR(255)

   IF reg_id IS NULL OR reg_id < 1 THEN
      ERROR "Region ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewTerritoriesWindow WITH FORM "territories"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_region_combo()
   LET where_clause = " territories.regionid = ", reg_id
   CALL territories_do_load(where_clause)

   IF territories_arr.getLength() == 0 THEN
      CLOSE WINDOW viewTerritoriesWindow
      ERROR "No Territories found for this Region"
      RETURN
   END IF

   CALL submenu_territories_view()

   CLOSE WINDOW viewTerritoriesWindow

END FUNCTION #view_territories_for_region

-- =====================================================================
-- Function: empl_by_terr
-- Purpose : View employees assigned to a territory (via link table)
-- =====================================================================
FUNCTION empl_by_terr(terr_id)
   DEFINE terr_id LIKE territories.territoryid
   DEFINE where_clause VARCHAR(500)

   IF terr_id IS NULL OR LENGTH(terr_id) == 0 THEN
      ERROR "Territory ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewEmployeesWindow WITH FORM "employees"
      ATTRIBUTES(STYLE="modulewindow")

   LET where_clause = " employees.employeeid IN (SELECT employeeid FROM employeeterritories WHERE territoryid = '", terr_id CLIPPED, "')"
   CALL load_employees_ext(where_clause)

   IF get_employees_count() == 0 THEN
      CLOSE WINDOW viewEmployeesWindow
      ERROR "No Employees found for this Territory"
      RETURN
   END IF

   CALL submenu_employees_view()

   CLOSE WINDOW viewEmployeesWindow

END FUNCTION #empl_by_terr

-- =====================================================================
-- Function: submenu_territories_view
-- Purpose : View-only submenu for territories (no add/modify/delete)
--           Now delegates to the generic controller_navigate_view()
-- =====================================================================
FUNCTION submenu_territories_view()

   CALL controller_init(get_config())
   CALL controller_navigate_view()

END FUNCTION #submenu_territories_view

-- =====================================================================
-- Dispatch interface: territories_get_count
-- =====================================================================
FUNCTION territories_get_count()

   RETURN territories_arr.getLength()

END FUNCTION #territories_get_count

-- =====================================================================
-- Dispatch interface: territories_load_at
-- =====================================================================
FUNCTION territories_load_at(idx)
   DEFINE idx INTEGER

   INITIALIZE curr_territories.* TO NULL
   IF idx >= 1 AND idx <= territories_arr.getLength() THEN
      LET curr_territories = territories_arr[idx]
   END IF

END FUNCTION #territories_load_at

-- =====================================================================
-- Dispatch interface: territories_display_curr
-- =====================================================================
FUNCTION territories_display_curr()

   DISPLAY BY NAME curr_territories.*

END FUNCTION #territories_display_curr

-- =====================================================================
-- Dispatch interface: territories_clear_curr
-- =====================================================================
FUNCTION territories_clear_curr()

   INITIALIZE curr_territories.* TO NULL

END FUNCTION #territories_clear_curr

-- =====================================================================
-- Dispatch interface: territories_do_query
-- =====================================================================
FUNCTION territories_do_query()
   DEFINE where_clause VARCHAR(255)

   CLEAR FORM
   CALL territories_clear_curr()
   CALL populate_region_combo()
   LET int_flag = FALSE
   CONSTRUCT where_clause ON territories.territoryid, territories.territorydescription,
                             territories.regionid
      FROM s_territories.*
      ON ACTION accept
         ACCEPT CONSTRUCT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL territories_clear_curr()
      CALL territories_arr.clear()
      RETURN
   END IF

   CALL territories_do_load(where_clause)

   IF territories_arr.getLength() == 0 THEN
      MESSAGE "No territories found."
      RETURN
   END IF

END FUNCTION #territories_do_query

-- =====================================================================
-- Function: territories_do_load (PRIVATE)
-- Purpose : Load territories into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION territories_do_load(where_clause)
   DEFINE where_clause VARCHAR(255)
   DEFINE sql_stmt VARCHAR(512)
   DEFINE temp_territory t_territory

   LET sql_stmt = " SELECT territoryid, territorydescription, regionid",
                  " FROM territories",
                  " WHERE ", where_clause CLIPPED, " ORDER BY territoryid"

   CALL territories_arr.clear()

   PREPARE p_territories FROM sql_stmt
   DECLARE c_territories CURSOR FOR p_territories
   FOREACH c_territories INTO temp_territory.*
      CALL territories_arr.appendElement()
      LET territories_arr[territories_arr.getLength()] = temp_territory
   END FOREACH
   CALL territories_clear_curr()

END FUNCTION #territories_do_load

-- =====================================================================
-- Dispatch interface: territories_do_add
-- =====================================================================
FUNCTION territories_do_add()

   CLEAR FORM
   LET int_flag = FALSE
   CALL territories_clear_curr()
   CALL populate_region_combo()
   INPUT BY NAME curr_territories.*
      ATTRIBUTE(UNBUFFERED)
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         VAR valid_status = curr_territories.validateRec("A")
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      ERROR "Territory add canceled"
      RETURN
   END IF

   VAR ins_status = curr_territories.insertRec()
   IF ins_status.valid_status THEN
      CALL territories_display_curr()
      MESSAGE ins_status.valid_msg
   ELSE
      ERROR ins_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #territories_do_add

-- =====================================================================
-- Dispatch interface: territories_do_edit
-- =====================================================================
FUNCTION territories_do_edit()

   CALL populate_region_combo()
   LET int_flag = FALSE
   INPUT BY NAME curr_territories.territorydescription, curr_territories.regionid
      ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         VAR valid_status = curr_territories.validateRec("C")
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      ERROR "Territory update canceled"
      RETURN
   END IF

   VAR upd_status = curr_territories.updateRec()
   IF upd_status.valid_status THEN
      MESSAGE upd_status.valid_msg
   ELSE
      ERROR upd_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #territories_do_edit

-- =====================================================================
-- Dispatch interface: territories_do_delete
-- =====================================================================
FUNCTION territories_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "Territory delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_territories.deleteRec()
   IF del_status.valid_status THEN
      MESSAGE del_status.valid_msg
   ELSE
      ERROR del_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #territories_do_delete

-- =====================================================================
-- Dispatch interface: territories_do_refresh
-- =====================================================================
FUNCTION territories_do_refresh(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL territories_arr.appendElement()
         LET territories_arr[territories_arr.getLength()] = curr_territories
      WHEN "C"
         LET territories_arr[currIdx] = curr_territories
      WHEN "D"
         FOR idx = 1 TO territories_arr.getLength()
            IF territories_arr[idx].territoryid = curr_territories.territoryid THEN
               CALL territories_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #territories_do_refresh

-- =====================================================================
-- Dispatch interface: territories_list_display
-- =====================================================================
FUNCTION territories_list_display()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   MESSAGE "Displayed ", territories_arr.getLength() USING "<<<<<", " territories"

   DISPLAY ARRAY territories_arr TO territories_list.*
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

END FUNCTION #territories_list_display

-- =====================================================================
-- Function: territories_do_command
-- Purpose : Execute a view command for territories
-- =====================================================================
FUNCTION territories_do_command(commandName STRING)
   CASE commandName
      WHEN "region"
         CALL view_region(curr_territories.regionid)
      WHEN "employees"
         CALL empl_by_terr(curr_territories.territoryid)
      OTHERWISE
         ERROR "Unknown command: ", commandName
   END CASE

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #territories_do_command

-- =====================================================================
-- Function: territories_lookup
-- Purpose : Open territory lookup window, return selected territory
-- =====================================================================
FUNCTION territories_lookup()
   DEFINE territories_id LIKE territories.territoryid
   DEFINE territories_desc LIKE territories.territorydescription

   OPEN WINDOW lookupWindow WITH FORM "territories"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_region_combo()
   CALL territories_lookup_menu()
      RETURNING territories_id, territories_desc

   CLOSE WINDOW lookupWindow

   RETURN territories_id, territories_desc

END FUNCTION #territories_lookup

-- =====================================================================
-- Function: territories_lookup_menu
-- Purpose : Navigate territories for selection
-- =====================================================================
FUNCTION territories_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL territories_do_query()
   IF territories_arr.getLength() == 0 THEN
      RETURN "", ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= territories_arr.getLength() AND selectedIdx == 0

      CALL territories_load_at(currentIdx)
      CALL territories_display_curr()
      LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", territories_arr.getLength() USING "<<<<"
      MESSAGE statusMessage

      MENU "Territory Select"
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
            IF currentIdx > territories_arr.getLength() THEN
               LET currentIdx = territories_arr.getLength()
            END IF
            EXIT MENU
         COMMAND "Last" "View last record in result set"
            LET currentIdx = territories_arr.getLength()
            EXIT MENU
         COMMAND "Select" "Select a territory"
            LET selectedIdx = currentIdx
            EXIT MENU
         COMMAND "Exit" "Quit operation"
            LET currentIdx = 0
            EXIT MENU
      END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_territories.territoryid, curr_territories.territorydescription
   END IF
   RETURN "", ""

END FUNCTION #territories_lookup_menu



-- =====================================================================
-- Function: populate_region_combo
-- Purpose : Populate the region combobox from the region table
-- =====================================================================
FUNCTION populate_region_combo()
   DEFINE cb ui.ComboBox
   DEFINE reg_id SMALLINT
   DEFINE reg_desc VARCHAR(20)

   LET cb = ui.ComboBox.forName("regionid")
   IF cb IS NULL THEN
      RETURN
   END IF
   CALL cb.clear()
   DECLARE c_region_combo CURSOR FOR
      SELECT regionid, regiondescription FROM region ORDER BY regiondescription
   FOREACH c_region_combo INTO reg_id, reg_desc
      CALL cb.addItem(reg_id, reg_desc)
   END FOREACH

END FUNCTION #populate_region_combo
