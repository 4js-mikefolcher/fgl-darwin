DATABASE northwind

DEFINE empl_terr_arr ARRAY[1000] OF RECORD
   employeeid LIKE employees.employeeid,
   fullname VARCHAR(32),
   territoryid LIKE territories.territoryid,
   territorydescription LIKE territories.territorydescription,
   regiondescription LIKE region.regiondescription
END RECORD
DEFINE curr_empl_terr RECORD
   employeeid LIKE employees.employeeid,
   fullname VARCHAR(32),
   territoryid LIKE territories.territoryid,
   territorydescription LIKE territories.territorydescription,
   regiondescription LIKE region.regiondescription
END RECORD
DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

FUNCTION submenu_empl_terr()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL query_empl_terr()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET int_flag = FALSE
   WHILE int_flag == FALSE AND arr_size > 0

      CALL set_count(arr_size)
      DISPLAY ARRAY empl_terr_arr TO sa_empl_terr.*
         BEFORE DISPLAY
            DISPLAY "Press Ctrl-P to Cancel, Ctrl-D to Delete, Ctrl-A to Add"
            AT 17,1
         BEFORE ROW
            LET currentIdx = arr_curr()
            LET curr_empl_terr = empl_terr_arr[currentIdx]
         ON KEY (ACCEPT)
            ACCEPT DISPLAY
         ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT DISPLAY
         ON KEY (CONTROL-D)
            CALL delete_empl_terr()
            IF int_flag == FALSE THEN
               CALL refresh_empl_terr(currentIdx, "D")
               IF currentIdx > arr_size THEN
                  LET currentIdx = arr_size
               END IF
               MESSAGE "Record Deleted"
               EXIT DISPLAY
            END IF
         ON KEY (CONTROL-A)
            CALL add_empl_terr()
            IF int_flag == FALSE THEN
               CALL refresh_empl_terr(currentIdx, "A")
               IF currentIdx > arr_size THEN
                  LET currentIdx = arr_size
               END IF
               MESSAGE "Record Added"
               EXIT DISPLAY
            END IF       
      END DISPLAY

   END WHILE

END FUNCTION #submenu_empl_terr

-- =====================================================================
-- Function: query_empl_terr
-- Purpose : Search and display employeeterritories using CONSTRUCT
-- =====================================================================
FUNCTION query_empl_terr()
    DEFINE where_clause VARCHAR(255)

    CLEAR FORM
    CALL clear_curr_empl_terr()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON employeeterritories.employeeid, 
                              employees.lastname,
                              employeeterritories.territoryid,
                              territories.territorydescription, 
                              region.regiondescription
       FROM sa_empl_terr[1].*
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
        BEFORE FIELD fullname
           MESSAGE "Enter search criteria for the employee's last name"
        AFTER FIELD fullname
           MESSAGE ""
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_empl_terr()
       CALL clear_empl_terr()
       RETURN
    END IF

    CALL load_empl_terr(where_clause)

    IF arr_size == 0 THEN
        MESSAGE "No employee territories found."
        RETURN
    END IF

END FUNCTION


-- =====================================================================
-- Function: load_empl_terr
-- Purpose : Load employeeterritories into dynamic array based on WHERE clause
-- =====================================================================
FUNCTION load_empl_terr(where_clause)
    DEFINE where_clause VARCHAR(255)
    DEFINE sql_stmt VARCHAR(2000)
    DEFINE idx INTEGER

    LET sql_stmt = " SELECT employeeterritories.employeeid,",
                   " RTRIM(employees.firstname) || ' ' || RTRIM(employees.lastname) as fullname,",
                   " employeeterritories.territoryid, territories.territorydescription, region.regiondescription",
                   " FROM employeeterritories",
                   " INNER JOIN employees ON employees.employeeid = employeeterritories.employeeid",
                   " INNER JOIN territories ON territories.territoryid = employeeterritories.territoryid",
                   " INNER JOIN region ON region.regionid = territories.regionid",
                   " WHERE ", where_clause,
                   " ORDER BY employeeterritories.employeeid, employeeterritories.territoryid"

    CALL clear_empl_terr()

    LET idx = 0
    DISPLAY sql_stmt
    PREPARE p1 FROM sql_stmt
    DECLARE c1 CURSOR FOR p1
    FOREACH c1 INTO curr_empl_terr.*
        LET idx = idx + 1
        LET empl_terr_arr[idx] = curr_empl_terr
    END FOREACH
    CALL clear_curr_empl_terr()
    LET arr_size = idx
    
END FUNCTION

FUNCTION clear_empl_terr()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE empl_terr_arr[idx].* TO NULL   
   END FOR
   LET arr_size = 0
      
END FUNCTION #clear_empl_terr

-- =====================================================================
-- Function: add_empl_terr
-- Purpose : Add a new territory record
-- =====================================================================
FUNCTION add_empl_terr()
    DEFINE empl_terr_valid SMALLINT
    DEFINE valid_msg CHAR(75)
    DEFINE selected_employee_id LIKE employees.employeeid
    DEFINE selected_fullname VARCHAR(32)
    DEFINE selected_territory_id LIKE territories.territoryid
    DEFINE selected_territory_desc LIKE territories.territorydescription

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_empl_terr()
    INPUT curr_empl_terr.* WITHOUT DEFAULTS FROM sa_empl_terr[1].*
        ATTRIBUTE(UNBUFFERED)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        ON KEY (CONTROL-T)
            IF INFIELD(employeeid) THEN
               CALL employee_lookup()
                  RETURNING selected_employee_id, selected_fullname
               IF selected_employee_id > 0 THEN
                  LET curr_empl_terr.employeeid = selected_employee_id
                  LET curr_empl_terr.fullname = selected_fullname
               END IF
            END IF
            IF INFIELD(territoryid) THEN
               CALL territories_lookup()
                  RETURNING selected_territory_id, selected_territory_desc
               IF selected_territory_id > 0 THEN
                  LET curr_empl_terr.territoryid = selected_territory_id
                  LET curr_empl_terr.territorydescription = selected_territory_desc
               END IF
            END IF
        BEFORE FIELD territoryid, employeeid
           MESSAGE "Use Ctrl-T to open lookup window"
        AFTER INPUT
            CALL validate_empl_terr("A")
               RETURNING empl_terr_valid, valid_msg
            IF NOT empl_terr_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Employee Territory add canceled"
       RETURN
    END IF

    CALL insert_curr_empl_terr()
    MESSAGE "Employee Territory record added"
    
END FUNCTION

-- =====================================================================
-- Function: delete_empl_terr
-- Purpose : Delete an existing territory record
-- =====================================================================
FUNCTION delete_empl_terr()
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
        ERROR "Territory delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_empl_terr()
    MESSAGE "Territory record deleted"

END FUNCTION

FUNCTION load_curr_empl_terr(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_empl_terr()
   IF currIdx > 0 AND currIdx <= arr_size THEN
      LET curr_empl_terr = empl_terr_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_empl_terr()

   DISPLAY BY NAME curr_empl_terr.*

END FUNCTION

FUNCTION clear_curr_empl_terr()

   INITIALIZE curr_empl_terr.* TO NULL

END FUNCTION

FUNCTION insert_curr_empl_terr()

   INSERT INTO employeeterritories (employeeid, territoryid) 
      VALUES ($curr_empl_terr.employeeid, $curr_empl_terr.territoryid)

END FUNCTION

FUNCTION delete_curr_empl_terr()

   DELETE FROM employeeterritories
      WHERE territoryid = $curr_empl_terr.territoryid
      AND employeeid = $curr_empl_terr.employeeid

END FUNCTION

FUNCTION refresh_empl_terr(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET empl_terr_arr[newIdx] = curr_empl_terr
         LET arr_size = newIdx
      WHEN "C"
         LET empl_terr_arr[currIdx] = curr_empl_terr
      WHEN "D"
           LET newIdx = 0 
           LET replaceRec = FALSE
              
           FOR idx = 1 TO arr_size
              IF empl_terr_arr[idx].territoryid = curr_empl_terr.territoryid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF 
              LET newIdx = newIdx + 1
              LET empl_terr_arr[newIdx] = empl_terr_arr[idx]
           END FOR 
    
           IF replaceRec THEN
              INITIALIZE empl_terr_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF 
   END CASE 

END FUNCTION #refresh_empl_terr

FUNCTION validate_empl_terr(mode)
   DEFINE mode CHAR(1)
   DEFINE territorydesc LIKE territories.territorydescription
   DEFINE employeeName VARCHAR(30)
   DEFINE regionDesc LIKE region.regiondescription
   DEFINE messageStr CHAR(70)

   LET messageStr = "Territory ID = (", curr_empl_terr.territoryid, ")"
   CALL debug_message(messageStr)
   SELECT territorydescription INTO territorydesc FROM territories
      WHERE territories.territoryid = $curr_empl_terr.territoryid
   IF sqlca.sqlcode == NOTFOUND THEN
      RETURN FALSE, "Territory ID is not found"
   END IF
   LET curr_empl_terr.territorydescription = territorydesc

   SELECT RTRIM(employees.firstname) || ' ' || RTRIM(employees.lastname) as fullname INTO employeeName
      FROM employees WHERE employeeid = $curr_empl_terr.employeeid
   IF sqlca.sqlcode == NOTFOUND THEN
      RETURN FALSE, "Employee ID is not found"
   END IF
   LET curr_empl_terr.fullname = employeeName

   SELECT regiondescription INTO regionDesc
      FROM region
      INNER JOIN territories ON territories.regionid = region.regionid
      WHERE territories.territoryid = $curr_empl_terr.territoryid
   LET curr_empl_terr.regiondescription = regionDesc
   
   RETURN TRUE, "Okay"
END FUNCTION

FUNCTION debug_message(str)
   DEFINE str CHAR(70)

   DISPLAY str AT 20, 1 ATTRIBUTES(REVERSE)

END FUNCTION #debug_message
