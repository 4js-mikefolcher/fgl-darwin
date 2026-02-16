DATABASE northwind

DEFINE usstates_arr ARRAY[1000] OF RECORD
   stateid LIKE usstates.stateid,
   statename LIKE usstates.statename,
   stateabbr LIKE usstates.stateabbr,
   stateregion LIKE usstates.stateregion
END RECORD

DEFINE curr_usstates RECORD
   stateid LIKE usstates.stateid,
   statename LIKE usstates.statename,
   stateabbr LIKE usstates.stateabbr,
   stateregion LIKE usstates.stateregion
END RECORD

DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

FUNCTION submenu_usstates()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET arr_max = 1000
   CALL query_usstates()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_usstates(currentIdx)
       CALL display_curr_usstates()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "US States Management"
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
              IF currentIdx > arr_size THEN
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = arr_size
              EXIT MENU
          COMMAND "Add" "Add a new state"
              CALL add_usstates()
              IF int_flag == FALSE THEN
                 CALL refresh_usstates(currentIdx, "A")
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing state"
              CALL edit_usstates()
              IF int_flag == FALSE THEN
                 CALL refresh_usstates(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete a state"
              CALL delete_usstates()
              IF int_flag == FALSE THEN
                 CALL refresh_usstates(currentIdx, "D")
                 IF currentIdx > arr_size THEN
                    LET currentIdx = arr_size
                 END IF
              END IF
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_usstates

FUNCTION query_usstates()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_usstates()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON usstates.stateid, usstates.statename, usstates.stateabbr, usstates.stateregion
       FROM s_usstates.*
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_usstates()
       CALL clear_usstates()
       RETURN
    END IF

    CALL load_usstates(where_clause)

    IF arr_size == 0 THEN
        MESSAGE "No states found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_usstates(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE idx INTEGER

    LET sql_stmt = " SELECT stateid, statename, stateabbr, stateregion",
                   " FROM usstates",
                   " WHERE ", where_clause CLIPPED, " ORDER BY statename"

    CALL clear_usstates()

    LET idx = 0
    PREPARE p_usstates FROM sql_stmt
    DECLARE c_usstates CURSOR FOR p_usstates
    FOREACH c_usstates INTO curr_usstates.*
        LET idx = idx + 1
        LET usstates_arr[idx] = curr_usstates
    END FOREACH
    CALL clear_curr_usstates()
    LET arr_size = idx

END FUNCTION

FUNCTION clear_usstates()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE usstates_arr[idx].* TO NULL
   END FOR
   LET arr_size = 0

END FUNCTION #clear_usstates

FUNCTION add_usstates()
    DEFINE usstates_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_usstates()
    INPUT BY NAME curr_usstates.*
        ATTRIBUTE(UNBUFFERED)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_usstates("A")
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

    CALL insert_curr_usstates()
    MESSAGE "State record added"

END FUNCTION

FUNCTION edit_usstates()
    DEFINE usstates_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_usstates.statename, curr_usstates.stateabbr, curr_usstates.stateregion
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_usstates("C")
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

    CALL update_curr_usstates()
    MESSAGE "State record updated"

END FUNCTION

FUNCTION delete_usstates()
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
        ERROR "State delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_usstates()
    MESSAGE "State record deleted"

END FUNCTION

FUNCTION load_curr_usstates(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_usstates()
   IF currIdx > 0 AND currIdx <= arr_size THEN
      LET curr_usstates = usstates_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_usstates()

   DISPLAY BY NAME curr_usstates.*

END FUNCTION

FUNCTION clear_curr_usstates()

   INITIALIZE curr_usstates.* TO NULL

END FUNCTION

FUNCTION insert_curr_usstates()

   INSERT INTO usstates (stateid, statename, stateabbr, stateregion)
      VALUES (DEFAULT, curr_usstates.statename, curr_usstates.stateabbr, curr_usstates.stateregion)
   LET curr_usstates.stateid = sqlca.sqlerrd[2]
   CALL display_curr_usstates()

END FUNCTION

FUNCTION update_curr_usstates()

   UPDATE usstates
      SET statename = curr_usstates.statename,
          stateabbr = curr_usstates.stateabbr,
          stateregion = curr_usstates.stateregion
    WHERE stateid = curr_usstates.stateid

END FUNCTION

FUNCTION delete_curr_usstates()

   DELETE FROM usstates
    WHERE stateid = curr_usstates.stateid

END FUNCTION

FUNCTION refresh_usstates(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET usstates_arr[newIdx] = curr_usstates
         LET arr_size = newIdx
      WHEN "C"
         LET usstates_arr[currIdx] = curr_usstates
      WHEN "D"
           LET newIdx = 0
           LET replaceRec = FALSE

           FOR idx = 1 TO arr_size
              IF usstates_arr[idx].stateid = curr_usstates.stateid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF
              LET newIdx = newIdx + 1
              LET usstates_arr[newIdx] = usstates_arr[idx]
           END FOR

           IF replaceRec THEN
              INITIALIZE usstates_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF
   END CASE

END FUNCTION #refresh_usstates

FUNCTION validate_usstates(mode)
   DEFINE mode CHAR(1)
   DEFINE stateExists SMALLINT

   IF mode == "C" THEN
      SELECT 1 INTO stateExists FROM usstates WHERE usstates.stateid = curr_usstates.stateid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "State ID is not found"
      END IF
   END IF

   RETURN TRUE, "Okay"
END FUNCTION
