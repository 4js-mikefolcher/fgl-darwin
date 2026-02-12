DATABASE northwind

TYPE t_empl_terr RECORD
   employeeid LIKE employees.employeeid,
   fullname VARCHAR(32),
   territoryid LIKE territories.territoryid,
   territorydescription LIKE territories.territorydescription,
   regiondescription LIKE region.regiondescription
END RECORD

DEFINE empl_terr_arr DYNAMIC ARRAY OF t_empl_terr
DEFINE contrl_empl_id LIKE employees.employeeid

-- =====================================================================
-- Function: terr_by_empl
-- Purpose : Open employee territories in a sub-window for a given employee
-- =====================================================================
FUNCTION terr_by_empl(employ_id)
   DEFINE employ_id LIKE employees.employeeid

   OPEN WINDOW subw1 AT 5,5 WITH FORM "empl_terr"

   LET contrl_empl_id = employ_id
   CALL load_empl_terr_by_id(employ_id)
   CALL manage_empl_terr()
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
   CALL manage_empl_terr()

END FUNCTION #submenu_empl_terr

-- =====================================================================
-- Function: manage_empl_terr
-- Purpose : INPUT ARRAY with modification triggers for inline editing,
--           adding, and deleting of employee territory assignments.
-- =====================================================================
FUNCTION manage_empl_terr()
   DEFINE curr_row INTEGER
   DEFINE selected_employee_id LIKE employees.employeeid
   DEFINE selected_fullname VARCHAR(32)
   DEFINE selected_territory_id LIKE territories.territoryid
   DEFINE selected_territory_desc LIKE territories.territorydescription
   DEFINE empl_terr_valid SMALLINT
   DEFINE valid_msg CHAR(75)

   LET int_flag = FALSE

   INPUT ARRAY empl_terr_arr WITHOUT DEFAULTS FROM sa_empl_terr.*
      ATTRIBUTES(UNBUFFERED, INSERT ROW = FALSE, APPEND ROW = FALSE,
                 DELETE ROW = FALSE, AUTO APPEND = FALSE)

      BEFORE ROW
         LET curr_row = arr_curr()

      BEFORE FIELD fullname
         -- fullname is derived; skip to next editable field
         IF DIALOG.getFieldTouched("employeeid") OR
            empl_terr_arr[curr_row].employeeid IS NOT NULL THEN
            NEXT FIELD territoryid
         ELSE
            NEXT FIELD employeeid
         END IF

      BEFORE FIELD territorydescription
         -- derived field; skip past
         NEXT FIELD NEXT

      BEFORE FIELD regiondescription
         -- derived field; skip past
         NEXT FIELD NEXT

      ON ACTION zoom_employee INFIELD employeeid
         CALL employee_lookup()
            RETURNING selected_employee_id, selected_fullname
         IF selected_employee_id > 0 THEN
            LET empl_terr_arr[curr_row].employeeid = selected_employee_id
            LET empl_terr_arr[curr_row].fullname = selected_fullname
         END IF

      ON ACTION zoom_territory INFIELD territoryid
         CALL territories_lookup()
            RETURNING selected_territory_id, selected_territory_desc
         IF selected_territory_id > 0 THEN
            LET empl_terr_arr[curr_row].territoryid = selected_territory_id
            LET empl_terr_arr[curr_row].territorydescription = selected_territory_desc
         END IF

      AFTER FIELD employeeid
         IF empl_terr_arr[curr_row].employeeid IS NOT NULL THEN
            CALL validate_empl_id(empl_terr_arr[curr_row].employeeid)
               RETURNING empl_terr_valid, valid_msg
            IF empl_terr_valid THEN
               LET empl_terr_arr[curr_row].fullname = valid_msg
            ELSE
               ERROR valid_msg
               NEXT FIELD employeeid
            END IF
         END IF

      AFTER FIELD territoryid
         IF empl_terr_arr[curr_row].territoryid IS NOT NULL THEN
            CALL validate_territory(empl_terr_arr[curr_row].territoryid)
               RETURNING empl_terr_valid, valid_msg,
                         empl_terr_arr[curr_row].territorydescription,
                         empl_terr_arr[curr_row].regiondescription
            IF NOT empl_terr_valid THEN
               ERROR valid_msg
               NEXT FIELD territoryid
            END IF
         END IF

      ON ACTION query
         CALL query_empl_terr()

      ON ACTION add
         CALL append_new_row(empl_terr_arr)

      ON ACTION delete
         IF empl_terr_arr.getLength() > 0 AND curr_row > 0 THEN
            IF confirm_delete() THEN
               CALL delete_empl_terr_row(empl_terr_arr[curr_row].*)
               CALL empl_terr_arr.deleteElement(curr_row)
               MESSAGE "Record Deleted"
            END IF
         END IF

      ON ACTION accept
         CALL save_all_changes(empl_terr_arr)
         EXIT INPUT

      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT

      ON ACTION exit
         LET int_flag = TRUE
         EXIT INPUT

   END INPUT

END FUNCTION #manage_empl_terr

-- =====================================================================
-- Function: append_new_row
-- Purpose : Append an empty row to the array, pre-filling the employee
--           id when launched from the employee context.
-- =====================================================================
FUNCTION append_new_row(p_arr)
   DEFINE p_arr DYNAMIC ARRAY OF t_empl_terr
   DEFINE idx INTEGER
   DEFINE empl_valid SMALLINT
   DEFINE empl_msg CHAR(75)

   LET idx = p_arr.getLength() + 1
   INITIALIZE p_arr[idx].* TO NULL
   IF contrl_empl_id > 0 THEN
      LET p_arr[idx].employeeid = contrl_empl_id
      CALL validate_empl_id(contrl_empl_id)
         RETURNING empl_valid, empl_msg
      IF empl_valid THEN
         LET p_arr[idx].fullname = empl_msg
      END IF
   END IF

END FUNCTION #append_new_row

-- =====================================================================
-- Function: query_empl_terr
-- Purpose : Search and display employeeterritories using CONSTRUCT
-- =====================================================================
FUNCTION query_empl_terr()
    DEFINE where_clause VARCHAR(255)

    CLEAR FORM
    LET int_flag = FALSE
    CONSTRUCT where_clause ON employeeterritories.employeeid,
                              employees.lastname,
                              employeeterritories.territoryid,
                              territories.territorydescription,
                              region.regiondescription
       FROM sa_empl_terr[1].*

        BEFORE FIELD fullname
           MESSAGE "Enter search criteria for the employee's last name"
        AFTER FIELD fullname
           MESSAGE ""

        ON ACTION cancel
            LET int_flag = TRUE
            EXIT CONSTRUCT

    END CONSTRUCT

    IF int_flag THEN
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
    DEFINE where_clause VARCHAR(255)
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

    PREPARE p1 FROM sql_stmt
    DECLARE c1 CURSOR FOR p1
    FOREACH c1 INTO l_rec.*
        CALL empl_terr_arr.appendElement()
        LET empl_terr_arr[empl_terr_arr.getLength()] = l_rec
    END FOREACH

END FUNCTION #load_empl_terr

-- =====================================================================
-- Function: load_empl_terr_by_id
-- Purpose : Load employeeterritories by employee id
-- =====================================================================
FUNCTION load_empl_terr_by_id(empl_id)
    DEFINE empl_id LIKE employees.employeeid
    DEFINE sql_stmt VARCHAR(2000)
    DEFINE l_rec t_empl_terr

    LET sql_stmt = " SELECT employeeterritories.employeeid,",
                   " RTRIM(employees.firstname) || ' ' || RTRIM(employees.lastname) as fullname,",
                   " employeeterritories.territoryid, territories.territorydescription, region.regiondescription",
                   " FROM employeeterritories",
                   " INNER JOIN employees ON employees.employeeid = employeeterritories.employeeid",
                   " INNER JOIN territories ON territories.territoryid = employeeterritories.territoryid",
                   " INNER JOIN region ON region.regionid = territories.regionid",
                   " WHERE employees.employeeid = ", empl_id,
                   " ORDER BY employeeterritories.employeeid, employeeterritories.territoryid"

    CALL empl_terr_arr.clear()

    PREPARE p2 FROM sql_stmt
    DECLARE c2 CURSOR FOR p2
    FOREACH c2 INTO l_rec.*
        CALL empl_terr_arr.appendElement()
        LET empl_terr_arr[empl_terr_arr.getLength()] = l_rec
    END FOREACH

END FUNCTION #load_empl_terr_by_id

-- =====================================================================
-- Function: save_all_changes
-- Purpose : Delete all existing rows for employees in the array, then
--           re-insert all current rows. Uses a transaction for safety.
-- =====================================================================
FUNCTION save_all_changes(p_arr)
   DEFINE p_arr DYNAMIC ARRAY OF t_empl_terr
   DEFINE i INTEGER
   DEFINE j INTEGER
   DEFINE empl_ids DYNAMIC ARRAY OF INTEGER
   DEFINE found SMALLINT

   -- Collect distinct employee ids from the array
   FOR i = 1 TO p_arr.getLength()
      IF p_arr[i].employeeid IS NOT NULL AND p_arr[i].territoryid IS NOT NULL THEN
         LET found = FALSE
         FOR j = 1 TO empl_ids.getLength()
            IF empl_ids[j] == p_arr[i].employeeid THEN
               LET found = TRUE
               EXIT FOR
            END IF
         END FOR
         IF NOT found THEN
            CALL empl_ids.appendElement()
            LET empl_ids[empl_ids.getLength()] = p_arr[i].employeeid
         END IF
      END IF
   END FOR

   BEGIN WORK

   -- Delete existing rows for each employee
   FOR i = 1 TO empl_ids.getLength()
      DELETE FROM employeeterritories
         WHERE employeeid = empl_ids[i]
   END FOR

   -- Re-insert all valid rows
   FOR i = 1 TO p_arr.getLength()
      IF p_arr[i].employeeid IS NOT NULL AND p_arr[i].territoryid IS NOT NULL THEN
         INSERT INTO employeeterritories (employeeid, territoryid)
            VALUES (p_arr[i].employeeid, p_arr[i].territoryid)
      END IF
   END FOR

   COMMIT WORK
   MESSAGE "Changes saved successfully"

END FUNCTION #save_all_changes

-- =====================================================================
-- Function: delete_empl_terr_row
-- Purpose : Delete a single employee territory row from the database
-- =====================================================================
FUNCTION delete_empl_terr_row(p_rec)
   DEFINE p_rec t_empl_terr

   IF p_rec.employeeid IS NOT NULL AND p_rec.territoryid IS NOT NULL THEN
      DELETE FROM employeeterritories
         WHERE employeeid = p_rec.employeeid
         AND territoryid = p_rec.territoryid
   END IF

END FUNCTION #delete_empl_terr_row

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
