IMPORT FGL list_view_helper

DATABASE northwind

TYPE t_empl_terr RECORD
   employeeid LIKE employees.employeeid,
   fullname VARCHAR(32),
   territoryid LIKE territories.territoryid,
   territorydescription LIKE territories.territorydescription,
   regiondescription LIKE region.regiondescription
END RECORD

DEFINE empl_terr_arr DYNAMIC ARRAY OF t_empl_terr
DEFINE curr_empl_terr t_empl_terr
DEFINE contrl_empl_id LIKE employees.employeeid

-- =====================================================================
-- Function: terr_by_empl
-- Purpose : Open employee territories in a sub-window for a given employee
-- =====================================================================
FUNCTION terr_by_empl(employ_id)
   DEFINE employ_id LIKE employees.employeeid
   DEFINE where_clause VARCHAR(500)

   OPEN WINDOW subw1 WITH FORM "empl_terr"
      ATTRIBUTES(STYLE="modulewindow")

   LET contrl_empl_id = employ_id
   LET where_clause = " employeeterritories.employeeid = ", employ_id
   CALL load_empl_terr(where_clause)

   IF empl_terr_arr.getLength() == 0 THEN
      LET contrl_empl_id = 0
      CLOSE WINDOW subw1
      ERROR "No Territories found for this Employee"
      RETURN
   END IF

   CALL submenu_empl_terr_nav()
   LET contrl_empl_id = 0

   CLOSE WINDOW subw1

END FUNCTION #terr_by_empl

-- =====================================================================
-- Function: submenu_empl_terr
-- Purpose : Entry point when launched standalone (query first)
-- =====================================================================
FUNCTION submenu_empl_terr()

   CALL query_empl_terr()
   IF empl_terr_arr.getLength() == 0 THEN
      RETURN
   END IF
   CALL submenu_empl_terr_nav()

END FUNCTION #submenu_empl_terr

-- =====================================================================
-- Function: submenu_empl_terr_nav
-- Purpose : Record-at-a-time navigation menu for employee territories
-- =====================================================================
FUNCTION submenu_empl_terr_nav()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= empl_terr_arr.getLength()

       CALL load_curr_empl_terr(currentIdx)
       CALL display_curr_empl_terr()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", empl_terr_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Employee Territories Management"
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
              IF currentIdx > empl_terr_arr.getLength() THEN
                 LET currentIdx = empl_terr_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = empl_terr_arr.getLength()
              EXIT MENU
          COMMAND "Add" "Add a new employee territory"
              CALL add_empl_terr()
              IF int_flag == FALSE THEN
                 CALL refresh_empl_terr(currentIdx, "A")
                 LET currentIdx = empl_terr_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete an employee territory"
              CALL delete_empl_terr()
              IF int_flag == FALSE THEN
                 CALL refresh_empl_terr(currentIdx, "D")
                 IF currentIdx > empl_terr_arr.getLength() THEN
                    LET currentIdx = empl_terr_arr.getLength()
                 END IF
              END IF
              EXIT MENU
          COMMAND "List" "Switch to list view"
              CALL list_empl_terr_view()
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_empl_terr_nav

-- =====================================================================
-- Function: list_empl_terr_view
-- Purpose : Display employee territories in a list/table view
-- =====================================================================
FUNCTION list_empl_terr_view()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   OPEN WINDOW listEmplTerrWindow WITH FORM "empl_terr_list"
      ATTRIBUTES(STYLE="modulewindow")

   MESSAGE "Displayed ", empl_terr_arr.getLength() USING "<<<<<", " employee territories"

   DISPLAY ARRAY empl_terr_arr TO empl_terr_list.*
       ON ACTION add
         LET selectedOption = cAddRecord
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

   CLOSE WINDOW listEmplTerrWindow

   IF int_flag THEN
      RETURN
   END IF

   CASE selectedOption
      WHEN cAddRecord
         CALL add_empl_terr()
         IF int_flag == FALSE THEN
            CALL refresh_empl_terr(empl_terr_arr.getLength(), "A")
         END IF
      WHEN cDeleteRecord
         IF selectedIdx >= 1 AND selectedIdx <= empl_terr_arr.getLength() THEN
            CALL load_curr_empl_terr(selectedIdx)
            CALL delete_empl_terr()
            IF int_flag == FALSE THEN
                  CALL refresh_empl_terr(selectedIdx, "D")
            END IF
         ELSE
            ERROR "Please select an employee territory"
         END IF
      WHEN cViewRecord
         CALL load_curr_empl_terr(selectedIdx)
         CALL display_curr_empl_terr()
   END CASE

END FUNCTION #list_empl_terr_view

-- =====================================================================
-- Function: query_empl_terr
-- Purpose : Search and display employeeterritories using CONSTRUCT
-- =====================================================================
FUNCTION query_empl_terr()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_empl_terr()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON employeeterritories.employeeid,
                              employees.lastname,
                              employeeterritories.territoryid,
                              territories.territorydescription,
                              region.regiondescription
       FROM s_empl_terr.*

        BEFORE FIELD fullname
           MESSAGE "Enter search criteria for the employee's last name"
        AFTER FIELD fullname
           MESSAGE ""

        ON ACTION accept
            ACCEPT CONSTRUCT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT CONSTRUCT

    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_empl_terr()
       CALL empl_terr_arr.clear()
       RETURN
    END IF

    CALL load_empl_terr(where_clause)

    IF empl_terr_arr.getLength() == 0 THEN
        MESSAGE "No employee territories found."
    END IF

END FUNCTION #query_empl_terr

-- =====================================================================
-- Function: load_empl_terr
-- Purpose : Load employeeterritories into dynamic array based on WHERE clause
-- =====================================================================
FUNCTION load_empl_terr(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(2000)
    DEFINE l_rec t_empl_terr

    LET sql_stmt = " SELECT employeeterritories.employeeid,",
                   " RTRIM(employees.firstname) || ' ' || RTRIM(employees.lastname) as fullname,",
                   " employeeterritories.territoryid, territories.territorydescription, region.regiondescription",
                   " FROM employeeterritories",
                   " INNER JOIN employees ON employees.employeeid = employeeterritories.employeeid",
                   " INNER JOIN territories ON territories.territoryid = employeeterritories.territoryid",
                   " INNER JOIN region ON region.regionid = territories.regionid",
                   " WHERE ", where_clause,
                   " ORDER BY employeeterritories.employeeid, employeeterritories.territoryid"

    CALL empl_terr_arr.clear()

    PREPARE p_empl_terr FROM sql_stmt
    DECLARE c_empl_terr CURSOR FOR p_empl_terr
    FOREACH c_empl_terr INTO l_rec.*
        CALL empl_terr_arr.appendElement()
        LET empl_terr_arr[empl_terr_arr.getLength()] = l_rec
    END FOREACH

END FUNCTION #load_empl_terr

-- =====================================================================
-- Function: add_empl_terr
-- Purpose : Add a new employee territory assignment
-- =====================================================================
FUNCTION add_empl_terr()
   DEFINE selected_employee_id LIKE employees.employeeid
   DEFINE selected_fullname VARCHAR(32)
   DEFINE selected_territory_id LIKE territories.territoryid
   DEFINE selected_territory_desc LIKE territories.territorydescription
   DEFINE empl_terr_valid SMALLINT
   DEFINE valid_msg CHAR(75)

   CLEAR FORM
   LET int_flag = FALSE
   CALL clear_curr_empl_terr()

   -- Pre-fill employee id when launched from employee context
   IF contrl_empl_id > 0 THEN
      LET curr_empl_terr.employeeid = contrl_empl_id
      CALL validate_empl_id(contrl_empl_id)
         RETURNING empl_terr_valid, valid_msg
      IF empl_terr_valid THEN
         LET curr_empl_terr.fullname = valid_msg
      END IF
      CALL display_curr_empl_terr()
   END IF

   INPUT BY NAME curr_empl_terr.employeeid, curr_empl_terr.territoryid
      ATTRIBUTES(UNBUFFERED)

      ON ACTION zoom_employee INFIELD employeeid
         CALL employee_lookup()
            RETURNING selected_employee_id, selected_fullname
         IF selected_employee_id > 0 THEN
            LET curr_empl_terr.employeeid = selected_employee_id
            LET curr_empl_terr.fullname = selected_fullname
            DISPLAY BY NAME curr_empl_terr.fullname
         END IF

      ON ACTION zoom_territory INFIELD territoryid
         CALL territories_lookup()
            RETURNING selected_territory_id, selected_territory_desc
         IF selected_territory_id IS NOT NULL AND LENGTH(selected_territory_id) > 0 THEN
            LET curr_empl_terr.territoryid = selected_territory_id
            LET curr_empl_terr.territorydescription = selected_territory_desc
            DISPLAY BY NAME curr_empl_terr.territorydescription
         END IF

      AFTER FIELD employeeid
         IF curr_empl_terr.employeeid IS NOT NULL THEN
            CALL validate_empl_id(curr_empl_terr.employeeid)
               RETURNING empl_terr_valid, valid_msg
            IF empl_terr_valid THEN
               LET curr_empl_terr.fullname = valid_msg
               DISPLAY BY NAME curr_empl_terr.fullname
            ELSE
               ERROR valid_msg
               NEXT FIELD employeeid
            END IF
         END IF

      AFTER FIELD territoryid
         IF curr_empl_terr.territoryid IS NOT NULL THEN
            CALL validate_territory(curr_empl_terr.territoryid)
               RETURNING empl_terr_valid, valid_msg,
                         curr_empl_terr.territorydescription,
                         curr_empl_terr.regiondescription
            IF NOT empl_terr_valid THEN
               ERROR valid_msg
               NEXT FIELD territoryid
            ELSE
               DISPLAY BY NAME curr_empl_terr.territorydescription,
                               curr_empl_terr.regiondescription
            END IF
         END IF

      ON ACTION accept
          ACCEPT INPUT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT

      AFTER INPUT
         CALL validate_empl_terr()
            RETURNING empl_terr_valid, valid_msg
         IF NOT empl_terr_valid THEN
            ERROR valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      ERROR "Employee territory add canceled"
      RETURN
   END IF

   CALL insert_curr_empl_terr()
   MESSAGE "Employee territory record added"

END FUNCTION #add_empl_terr

-- =====================================================================
-- Function: delete_empl_terr
-- Purpose : Delete an existing employee territory record
-- =====================================================================
FUNCTION delete_empl_terr()

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
        ERROR "Employee territory delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_empl_terr()
    MESSAGE "Employee territory record deleted"

END FUNCTION #delete_empl_terr

-- =====================================================================
-- Function: load_curr_empl_terr
-- Purpose : Load a record from the array into the current record
-- =====================================================================
FUNCTION load_curr_empl_terr(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_empl_terr()
   IF currIdx > 0 AND currIdx <= empl_terr_arr.getLength() THEN
      LET curr_empl_terr = empl_terr_arr[currIdx]
   END IF

END FUNCTION #load_curr_empl_terr

-- =====================================================================
-- Function: display_curr_empl_terr
-- Purpose : Display the current record on the form
-- =====================================================================
FUNCTION display_curr_empl_terr()

   DISPLAY BY NAME curr_empl_terr.*

END FUNCTION #display_curr_empl_terr

-- =====================================================================
-- Function: clear_curr_empl_terr
-- Purpose : Initialize the current record to NULL
-- =====================================================================
FUNCTION clear_curr_empl_terr()

   INITIALIZE curr_empl_terr.* TO NULL

END FUNCTION #clear_curr_empl_terr

-- =====================================================================
-- Function: insert_curr_empl_terr
-- Purpose : Insert the current record into the database
-- =====================================================================
FUNCTION insert_curr_empl_terr()

   INSERT INTO employeeterritories (employeeid, territoryid)
      VALUES (curr_empl_terr.employeeid, curr_empl_terr.territoryid)

END FUNCTION #insert_curr_empl_terr

-- =====================================================================
-- Function: delete_curr_empl_terr
-- Purpose : Delete the current record from the database
-- =====================================================================
FUNCTION delete_curr_empl_terr()

   DELETE FROM employeeterritories
    WHERE employeeid = curr_empl_terr.employeeid
      AND territoryid = curr_empl_terr.territoryid

END FUNCTION #delete_curr_empl_terr

-- =====================================================================
-- Function: refresh_empl_terr
-- Purpose : Refresh the array after add or delete operations
-- =====================================================================
FUNCTION refresh_empl_terr(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER
   DEFINE found SMALLINT

   CASE operation
      WHEN "A"
         CALL empl_terr_arr.appendElement()
         LET empl_terr_arr[empl_terr_arr.getLength()] = curr_empl_terr
      WHEN "D"
         LET found = FALSE
         FOR idx = 1 TO empl_terr_arr.getLength()
            IF empl_terr_arr[idx].employeeid == curr_empl_terr.employeeid
               AND empl_terr_arr[idx].territoryid == curr_empl_terr.territoryid THEN
               CALL empl_terr_arr.deleteElement(idx)
               LET found = TRUE
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #refresh_empl_terr

-- =====================================================================
-- Function: validate_empl_terr
-- Purpose : Validate the current employee territory record
-- =====================================================================
FUNCTION validate_empl_terr()
   DEFINE exists_count SMALLINT

   IF curr_empl_terr.employeeid IS NULL THEN
      RETURN FALSE, "Employee ID is required"
   END IF
   IF curr_empl_terr.territoryid IS NULL OR LENGTH(curr_empl_terr.territoryid) == 0 THEN
      RETURN FALSE, "Territory ID is required"
   END IF

   -- Check for duplicate assignment
   SELECT COUNT(*) INTO exists_count
      FROM employeeterritories
      WHERE employeeid = curr_empl_terr.employeeid
        AND territoryid = curr_empl_terr.territoryid
   IF exists_count > 0 THEN
      RETURN FALSE, "This employee is already assigned to this territory"
   END IF

   RETURN TRUE, "Okay"

END FUNCTION #validate_empl_terr

-- =====================================================================
-- Function: validate_territory
-- Purpose : Validate a territory ID and return its description and region
-- =====================================================================
FUNCTION validate_territory(p_territory_id)
   DEFINE p_territory_id LIKE territories.territoryid
   DEFINE l_terr_desc LIKE territories.territorydescription
   DEFINE l_region_desc LIKE region.regiondescription

   SELECT territorydescription INTO l_terr_desc
      FROM territories
      WHERE territories.territoryid = p_territory_id
   IF sqlca.sqlcode == NOTFOUND THEN
      RETURN FALSE, "Territory ID is not found", NULL, NULL
   END IF

   SELECT regiondescription INTO l_region_desc
      FROM region
      INNER JOIN territories ON territories.regionid = region.regionid
      WHERE territories.territoryid = p_territory_id

   RETURN TRUE, "Okay", l_terr_desc, l_region_desc

END FUNCTION #validate_territory

-- =====================================================================
-- Function: validate_empl_id
-- Purpose : Validate an employee ID and return the full name
-- =====================================================================
FUNCTION validate_empl_id(p_employee_id)
   DEFINE p_employee_id LIKE employees.employeeid
   DEFINE employeeName VARCHAR(30)

   SELECT RTRIM(employees.firstname) || ' ' || RTRIM(employees.lastname) as fullname
      INTO employeeName
      FROM employees
      WHERE employeeid = p_employee_id
   IF sqlca.sqlcode == NOTFOUND THEN
      RETURN FALSE, "Employee ID is not found"
   END IF

   RETURN TRUE, employeeName

END FUNCTION #validate_empl_id
