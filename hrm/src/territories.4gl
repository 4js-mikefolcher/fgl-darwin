IMPORT FGL list_view_helper
DATABASE northwind

TYPE t_territory RECORD
   territoryid VARCHAR(20),
   territorydescription VARCHAR(20),
   regionid SMALLINT
END RECORD

DEFINE territories_arr DYNAMIC ARRAY OF t_territory
DEFINE curr_territories t_territory

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

   LET where_clause = " territories.territoryid = '", terr_id CLIPPED, "'"
   CALL load_territories(where_clause)

   IF territories_arr.getLength() == 0 THEN
      CLOSE WINDOW viewTerritoryWindow
      ERROR "Territory not found"
      RETURN
   END IF

   CALL populate_region_combo()
   CALL load_curr_territories(1)
   CALL display_curr_territories()

   MENU "Territory View"
      COMMAND "Region" "View Region"
         CALL view_region(curr_territories.regionid)
      COMMAND "Employees" "View Employees in this Territory"
         CALL empl_by_terr(curr_territories.territoryid)
      COMMAND "Exit" "Quit operation"
         EXIT MENU
   END MENU

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

   LET where_clause = " territories.regionid = ", reg_id
   CALL load_territories(where_clause)

   IF territories_arr.getLength() == 0 THEN
      CLOSE WINDOW viewTerritoriesWindow
      ERROR "No Territories found for this Region"
      RETURN
   END IF

   CALL populate_region_combo()
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
-- =====================================================================
FUNCTION submenu_territories_view()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= territories_arr.getLength()

       CALL load_curr_territories(currentIdx)
       CALL display_curr_territories()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", territories_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Territories View"
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
          COMMAND "Region" "View Region"
              CALL view_region(curr_territories.regionid)
          COMMAND "Employees" "View Employees in this Territory"
              CALL empl_by_terr(curr_territories.territoryid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_territories_view

FUNCTION submenu_territories()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL query_territories()
   IF territories_arr.getLength() == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= territories_arr.getLength()

       CALL load_curr_territories(currentIdx)
       CALL display_curr_territories()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", territories_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Territories Management"
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
          COMMAND "Add" "Add a new territory"
              CALL add_territories()
              IF int_flag == FALSE THEN
                 CALL refresh_territories(currentIdx, "A")
                 LET currentIdx = territories_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing territory"
              CALL edit_territories()
              IF int_flag == FALSE THEN
                 CALL refresh_territories(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete a territory"
              CALL delete_territories()
              IF int_flag == FALSE THEN
                 CALL refresh_territories(currentIdx, "D")
                 IF currentIdx > territories_arr.getLength() THEN
                    LET currentIdx = territories_arr.getLength()
                 END IF
              END IF
              EXIT MENU
          COMMAND "List" "Switch to list view"
              CALL list_territories_view()
              EXIT MENU
          COMMAND "Region" "View Region"
              CALL view_region(curr_territories.regionid)
          COMMAND "Employees" "View Employees in this Territory"
              CALL empl_by_terr(curr_territories.territoryid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_territories

-- =====================================================================
-- Function: list_territories_view
-- Purpose : Display territories in a list/table view
-- =====================================================================
FUNCTION list_territories_view()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   OPEN WINDOW listTerritoriesWindow WITH FORM "territories_list"
      ATTRIBUTES(STYLE="modulewindow")

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

   CLOSE WINDOW listTerritoriesWindow

   IF int_flag THEN
      RETURN
   END IF

   CASE selectedOption
      WHEN cAddRecord
         CALL add_territories()
         IF int_flag == FALSE THEN
            CALL refresh_territories(territories_arr.getLength(), "A")
         END IF
      WHEN cEditRecord
         IF selectedIdx >= 1 AND selectedIdx <= territories_arr.getLength() THEN
            CALL load_curr_territories(selectedIdx)
            CALL edit_territories()
            IF int_flag == FALSE THEN
                  CALL refresh_territories(selectedIdx, "C")
            END IF
         ELSE
            ERROR "Please select a territory"
         END IF
      WHEN cDeleteRecord
         IF selectedIdx >= 1 AND selectedIdx <= territories_arr.getLength() THEN
            CALL load_curr_territories(selectedIdx)
            CALL delete_territories()
            IF int_flag == FALSE THEN
                  CALL refresh_territories(selectedIdx, "D")
            END IF
         ELSE
            ERROR "Please select a territory"
         END IF
      WHEN cViewRecord
         CALL load_curr_territories(selectedIdx)
         CALL display_curr_territories()
   END CASE

END FUNCTION #list_territories_view

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

FUNCTION territories_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL query_territories()
   IF territories_arr.getLength() == 0 THEN
      RETURN "", ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= territories_arr.getLength() AND selectedIdx == 0

       CALL load_curr_territories(currentIdx)
       CALL display_curr_territories()
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
-- Function: query_territories
-- Purpose : Search and display territories using CONSTRUCT, store in array
-- =====================================================================
FUNCTION query_territories()
    DEFINE where_clause VARCHAR(255)

    CLEAR FORM
    CALL clear_curr_territories()
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
       CALL clear_curr_territories()
       CALL clear_territories()
       RETURN
    END IF

    CALL load_territories(where_clause)

    IF territories_arr.getLength() == 0 THEN
        MESSAGE "No territories found."
        RETURN
    END IF

END FUNCTION


-- =====================================================================
-- Function: load_territories
-- Purpose : Load territories into dynamic array based on WHERE clause
-- =====================================================================
FUNCTION load_territories(where_clause)
    DEFINE where_clause VARCHAR(255)
    DEFINE sql_stmt VARCHAR(512)
    DEFINE temp_territory t_territory

    LET sql_stmt = " SELECT territoryid, territorydescription, regionid",
                   " FROM territories",
                   " WHERE ", where_clause CLIPPED, " ORDER BY territoryid"

    CALL clear_territories()

    PREPARE p_territories FROM sql_stmt
    DECLARE c_territories CURSOR FOR p_territories
    FOREACH c_territories INTO temp_territory.*
        CALL territories_arr.appendElement()
        LET territories_arr[territories_arr.getLength()] = temp_territory
    END FOREACH
    CALL clear_curr_territories()

END FUNCTION

FUNCTION clear_territories()

   CALL territories_arr.clear()

END FUNCTION #clear_territories

-- =====================================================================
-- Function: add_territories
-- Purpose : Add a new territory record
-- =====================================================================
FUNCTION add_territories()
    DEFINE territories_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_territories()
    INPUT BY NAME curr_territories.*
        ATTRIBUTE(UNBUFFERED)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_territories("A")
               RETURNING territories_valid, valid_msg
            IF NOT territories_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Territory add canceled"
       RETURN
    END IF

    CALL insert_curr_territories()
    MESSAGE "Territory record added"

END FUNCTION


-- =====================================================================
-- Function: edit_territories
-- Purpose : Edit an existing territory record
-- =====================================================================
FUNCTION edit_territories()
    DEFINE territories_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_territories.territorydescription, curr_territories.regionid
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_territories("C")
               RETURNING territories_valid, valid_msg
            IF NOT territories_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Territory update canceled"
       RETURN
    END IF

    CALL update_curr_territories()
    MESSAGE "Territory record updated"

END FUNCTION


-- =====================================================================
-- Function: delete_territories
-- Purpose : Delete an existing territory record
-- =====================================================================
FUNCTION delete_territories()

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
        ERROR "Territory delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_territories()
    MESSAGE "Territory record deleted"

END FUNCTION

FUNCTION load_curr_territories(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_territories()
   IF currIdx > 0 AND currIdx <= territories_arr.getLength() THEN
      LET curr_territories = territories_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_territories()

   DISPLAY BY NAME curr_territories.*

END FUNCTION

FUNCTION clear_curr_territories()

   INITIALIZE curr_territories.* TO NULL

END FUNCTION

FUNCTION insert_curr_territories()

   INSERT INTO territories (territoryid, territorydescription, regionid) 
      VALUES (curr_territories.territoryid, curr_territories.territorydescription, curr_territories.regionid)

END FUNCTION

FUNCTION update_curr_territories()

   UPDATE territories
      SET territorydescription = curr_territories.territorydescription,
          regionid = curr_territories.regionid
    WHERE territoryid = curr_territories.territoryid

END FUNCTION

FUNCTION delete_curr_territories()

   DELETE FROM territories
    WHERE territoryid = curr_territories.territoryid

END FUNCTION

FUNCTION refresh_territories(currIdx, operation)
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

END FUNCTION #refresh_territories

FUNCTION validate_territories(mode)
   DEFINE mode CHAR(1)
   DEFINE territoriesExists SMALLINT

   SELECT 1 INTO territoriesExists FROM territories WHERE territories.territoryid = curr_territories.territoryid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      RETURN FALSE, "Territory ID is not found"
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      RETURN FALSE, "Territory ID already exists"
   END IF
   IF curr_territories.territoryid IS NULL OR LENGTH(curr_territories.territoryid) == 0 THEN
      RETURN FALSE, "Territory ID is required"
   END IF
   IF curr_territories.territorydescription IS NULL OR LENGTH(curr_territories.territorydescription) == 0 THEN
      RETURN FALSE, "Territory Description is required"
   END IF
   IF curr_territories.regionid IS NULL THEN
      RETURN FALSE, "Region is required"
   END IF
   RETURN TRUE, "Okay"
END FUNCTION

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
