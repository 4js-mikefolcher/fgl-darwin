IMPORT FGL list_view_helper
IMPORT FGL controller

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
-- Function: get_config
-- Purpose : Return the controller configuration for employee territories
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS t_controller_config
   DEFINE cfg t_controller_config
   LET cfg.moduleName   = "empl_terr"
   LET cfg.formName     = "empl_terr"
   LET cfg.listFormName = "empl_terr_list"
   LET cfg.windowTitle  = "Employee Territories Management"
   LET cfg.hasModify    = FALSE
   LET cfg.hasQuery     = TRUE
   LET cfg.hasLookup    = FALSE
   LET cfg.entityName   = "Employee Territory"
   RETURN cfg
END FUNCTION #get_config

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
   CALL empl_terr_do_load(where_clause)

   IF empl_terr_arr.getLength() == 0 THEN
      LET contrl_empl_id = 0
      CLOSE WINDOW subw1
      ERROR "No Territories found for this Employee"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate()

   LET contrl_empl_id = 0
   CLOSE WINDOW subw1

END FUNCTION #terr_by_empl

-- =====================================================================
-- Function: submenu_empl_terr
-- Purpose : Standard entry point — query then navigate using controller
-- =====================================================================
FUNCTION submenu_empl_terr()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_empl_terr

-- =====================================================================
-- Dispatch Interface: Functions called by the controller via dispatch
-- =====================================================================

-- Return the number of records in the result set
FUNCTION empl_terr_get_count() RETURNS INTEGER
   RETURN empl_terr_arr.getLength()
END FUNCTION #empl_terr_get_count

-- Load the record at index into the current record
FUNCTION empl_terr_load_at(idx INTEGER)
   INITIALIZE curr_empl_terr.* TO NULL
   IF idx > 0 AND idx <= empl_terr_arr.getLength() THEN
      LET curr_empl_terr = empl_terr_arr[idx]
   END IF
END FUNCTION #empl_terr_load_at

-- Display the current record on the form
FUNCTION empl_terr_display_curr()
   DISPLAY BY NAME curr_empl_terr.*
END FUNCTION #empl_terr_display_curr

-- Clear the current record and form
FUNCTION empl_terr_clear_curr()
   INITIALIZE curr_empl_terr.* TO NULL
END FUNCTION #empl_terr_clear_curr

-- =====================================================================
-- Function: empl_terr_do_query
-- Purpose : Search using CONSTRUCT and load results
-- =====================================================================
FUNCTION empl_terr_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL empl_terr_clear_curr()
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
      CALL empl_terr_clear_curr()
      CALL empl_terr_arr.clear()
      RETURN
   END IF

   CALL empl_terr_do_load(where_clause)

   IF empl_terr_arr.getLength() == 0 THEN
      MESSAGE "No employee territories found."
   END IF

END FUNCTION #empl_terr_do_query

-- =====================================================================
-- Function: empl_terr_do_load
-- Purpose : Load employeeterritories into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION empl_terr_do_load(where_clause VARCHAR(500))
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

END FUNCTION #empl_terr_do_load

-- =====================================================================
-- Function: empl_terr_do_add
-- Purpose : Add a new employee territory assignment
-- =====================================================================
FUNCTION empl_terr_do_add()
   DEFINE selected_employee_id LIKE employees.employeeid
   DEFINE selected_fullname VARCHAR(32)
   DEFINE selected_territory_id LIKE territories.territoryid
   DEFINE selected_territory_desc LIKE territories.territorydescription
   DEFINE empl_terr_valid SMALLINT
   DEFINE valid_msg CHAR(75)

   CLEAR FORM
   LET int_flag = FALSE
   CALL empl_terr_clear_curr()

   -- Pre-fill employee id when launched from employee context
   IF contrl_empl_id > 0 THEN
      LET curr_empl_terr.employeeid = contrl_empl_id
      CALL validate_empl_id(contrl_empl_id)
         RETURNING empl_terr_valid, valid_msg
      IF empl_terr_valid THEN
         LET curr_empl_terr.fullname = valid_msg
      END IF
      CALL empl_terr_display_curr()
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
         CALL empl_terr_validate()
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

   INSERT INTO employeeterritories (employeeid, territoryid)
      VALUES (curr_empl_terr.employeeid, curr_empl_terr.territoryid)
   MESSAGE "Employee territory record added"

END FUNCTION #empl_terr_do_add

-- =====================================================================
-- Function: empl_terr_do_edit
-- Purpose : Edit not supported for employee territories (no-op)
-- =====================================================================
FUNCTION empl_terr_do_edit()
   LET int_flag = TRUE
END FUNCTION #empl_terr_do_edit

-- =====================================================================
-- Function: empl_terr_do_delete
-- Purpose : Delete an existing employee territory record
-- =====================================================================
FUNCTION empl_terr_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "Employee territory delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   DELETE FROM employeeterritories
    WHERE employeeid = curr_empl_terr.employeeid
      AND territoryid = curr_empl_terr.territoryid
   MESSAGE "Employee territory record deleted"

END FUNCTION #empl_terr_do_delete

-- =====================================================================
-- Function: empl_terr_do_refresh
-- Purpose : Refresh the array after add or delete operations
-- =====================================================================
FUNCTION empl_terr_do_refresh(currIdx INTEGER, operation CHAR(1))
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL empl_terr_arr.appendElement()
         LET empl_terr_arr[empl_terr_arr.getLength()] = curr_empl_terr
      WHEN "D"
         FOR idx = 1 TO empl_terr_arr.getLength()
            IF empl_terr_arr[idx].employeeid == curr_empl_terr.employeeid
               AND empl_terr_arr[idx].territoryid == curr_empl_terr.territoryid THEN
               CALL empl_terr_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #empl_terr_do_refresh

-- =====================================================================
-- Function: empl_terr_list_display
-- Purpose : DISPLAY ARRAY list view for employee territories
-- =====================================================================
FUNCTION empl_terr_list_display() RETURNS (INTEGER, INTEGER)
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   LET selectedIdx = 0
   LET selectedOption = 0
   LET int_flag = FALSE

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

   RETURN selectedIdx, selectedOption

END FUNCTION #empl_terr_list_display

-- =====================================================================
-- Function: empl_terr_validate
-- Purpose : Validate the current employee territory record
-- =====================================================================
FUNCTION empl_terr_validate() RETURNS (SMALLINT, CHAR(75))
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

END FUNCTION #empl_terr_validate

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
