IMPORT FGL list_view_helper
DATABASE northwind

TYPE t_usstate RECORD
   stateid SMALLINT,
   statename VARCHAR(100),
   stateabbr VARCHAR(2),
   stateregion VARCHAR(50)
END RECORD

DEFINE usstates_arr DYNAMIC ARRAY OF t_usstate
DEFINE curr_usstates t_usstate

FUNCTION submenu_usstates()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL query_usstates()
   IF usstates_arr.getLength() == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= usstates_arr.getLength()

       CALL load_curr_usstates(currentIdx)
       CALL display_curr_usstates()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", usstates_arr.getLength() USING "<<<<"
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
              IF currentIdx > usstates_arr.getLength() THEN
                 LET currentIdx = usstates_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = usstates_arr.getLength()
              EXIT MENU
          COMMAND "Add" "Add a new state"
              CALL add_usstates()
              IF int_flag == FALSE THEN
                 CALL refresh_usstates(currentIdx, "A")
                 LET currentIdx = usstates_arr.getLength()
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
                 IF currentIdx > usstates_arr.getLength() THEN
                    LET currentIdx = usstates_arr.getLength()
                 END IF
              END IF
              EXIT MENU
          COMMAND "List" "Switch to list view"
              CALL list_usstates_view()
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_usstates

-- =====================================================================
-- Function: list_usstates_view
-- Purpose : Display US states in a list/table view
-- =====================================================================
FUNCTION list_usstates_view()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   OPEN WINDOW listUsstatesWindow WITH FORM "usstates_list"
      ATTRIBUTES(STYLE="modulewindow")

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

   CLOSE WINDOW listUsstatesWindow

   IF int_flag THEN
      RETURN
   END IF

   CASE selectedOption
      WHEN cAddRecord
         CALL add_usstates()
         IF int_flag == FALSE THEN
            CALL refresh_usstates(usstates_arr.getLength(), "A")
         END IF
      WHEN cEditRecord
         IF selectedIdx >= 1 AND selectedIdx <= usstates_arr.getLength() THEN
            CALL load_curr_usstates(selectedIdx)
            CALL edit_usstates()
            IF int_flag == FALSE THEN
                  CALL refresh_usstates(selectedIdx, "C")
            END IF
         ELSE
            ERROR "Please select a state"
         END IF
      WHEN cDeleteRecord
         IF selectedIdx >= 1 AND selectedIdx <= usstates_arr.getLength() THEN
            CALL load_curr_usstates(selectedIdx)
            CALL delete_usstates()
            IF int_flag == FALSE THEN
                  CALL refresh_usstates(selectedIdx, "D")
            END IF
         ELSE
            ERROR "Please select a state"
         END IF
      WHEN cViewRecord
         CALL load_curr_usstates(selectedIdx)
         CALL display_curr_usstates()
   END CASE

END FUNCTION #list_usstates_view

FUNCTION query_usstates()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_usstates()
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
       CALL clear_curr_usstates()
       CALL clear_usstates()
       RETURN
    END IF

    CALL load_usstates(where_clause)

    IF usstates_arr.getLength() == 0 THEN
        MESSAGE "No states found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_usstates(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE temp_usstate t_usstate

    LET sql_stmt = " SELECT stateid, statename, stateabbr, stateregion",
                   " FROM usstates",
                   " WHERE ", where_clause CLIPPED, " ORDER BY statename"

    CALL clear_usstates()

    PREPARE p_usstates FROM sql_stmt
    DECLARE c_usstates CURSOR FOR p_usstates
    FOREACH c_usstates INTO temp_usstate.*
        CALL usstates_arr.appendElement()
        LET usstates_arr[usstates_arr.getLength()] = temp_usstate
    END FOREACH
    CALL clear_curr_usstates()

END FUNCTION

FUNCTION clear_usstates()

   CALL usstates_arr.clear()

END FUNCTION

FUNCTION add_usstates()
    DEFINE usstates_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_usstates()
    INPUT BY NAME curr_usstates.*
        ATTRIBUTE(UNBUFFERED)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
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
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
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

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
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
   IF currIdx > 0 AND currIdx <= usstates_arr.getLength() THEN
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

END FUNCTION

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
