DATABASE northwind

DEFINE shippers_arr ARRAY[1000] OF RECORD
   shipperid LIKE shippers.shipperid,
   companyname LIKE shippers.companyname,
   phone LIKE shippers.phone
END RECORD

DEFINE curr_shippers RECORD
   shipperid LIKE shippers.shipperid,
   companyname LIKE shippers.companyname,
   phone LIKE shippers.phone
END RECORD

DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

-- =====================================================================
-- Function: view_shipper
-- Purpose : View a specific shipper record (called from other modules)
-- =====================================================================
FUNCTION view_shipper(ship_id)
   DEFINE ship_id LIKE shippers.shipperid
   DEFINE where_clause VARCHAR(500)

   IF ship_id IS NULL OR ship_id < 1 THEN
      ERROR "Shipper ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewShipperWindow AT 5,5 WITH FORM "shippers"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   LET arr_max = 1000
   LET where_clause = " shippers.shipperid = ", ship_id
   CALL load_shippers(where_clause)

   IF arr_size == 0 THEN
      ERROR "Shipper not found"
      CLOSE WINDOW viewShipperWindow
      RETURN
   END IF

   CALL load_curr_shippers(1)
   CALL display_curr_shippers()

   MENU "Shipper View"
      COMMAND "Exit" "Quit operation"
         EXIT MENU
   END MENU

   CLOSE WINDOW viewShipperWindow

END FUNCTION #view_shipper

FUNCTION submenu_shippers()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET arr_max = 1000
   CALL query_shippers()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_shippers(currentIdx)
       CALL display_curr_shippers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Shippers Management"
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
          COMMAND "Add" "Add a new shipper"
              CALL add_shippers()
              IF int_flag == FALSE THEN
                 CALL refresh_shippers(currentIdx, "A")
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing shipper"
              CALL edit_shippers()
              IF int_flag == FALSE THEN
                 CALL refresh_shippers(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete a shipper"
              CALL delete_shippers()
              IF int_flag == FALSE THEN
                 CALL refresh_shippers(currentIdx, "D")
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

END FUNCTION #submenu_shippers

FUNCTION query_shippers()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_shippers()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON shippers.shipperid, shippers.companyname, shippers.phone
       FROM s_shippers.*
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_shippers()
       CALL clear_shippers()
       RETURN
    END IF

    CALL load_shippers(where_clause)

    IF arr_size == 0 THEN
        MESSAGE "No shippers found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_shippers(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE idx INTEGER

    LET sql_stmt = " SELECT shipperid, companyname, phone",
                   " FROM shippers",
                   " WHERE ", where_clause CLIPPED, " ORDER BY companyname"

    CALL clear_shippers()

    LET idx = 0
    PREPARE p_shippers FROM sql_stmt
    DECLARE c_shippers CURSOR FOR p_shippers
    FOREACH c_shippers INTO curr_shippers.*
        LET idx = idx + 1
        LET shippers_arr[idx] = curr_shippers
    END FOREACH
    CALL clear_curr_shippers()
    LET arr_size = idx

END FUNCTION

FUNCTION clear_shippers()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE shippers_arr[idx].* TO NULL
   END FOR
   LET arr_size = 0

END FUNCTION #clear_shippers

FUNCTION add_shippers()
    DEFINE shippers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_shippers()
    INPUT BY NAME curr_shippers.*
        ATTRIBUTE(UNBUFFERED)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_shippers("A")
               RETURNING shippers_valid, valid_msg
            IF NOT shippers_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Shipper add canceled"
       RETURN
    END IF

    CALL insert_curr_shippers()
    MESSAGE "Shipper record added"

END FUNCTION

FUNCTION edit_shippers()
    DEFINE shippers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_shippers.companyname, curr_shippers.phone
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_shippers("C")
               RETURNING shippers_valid, valid_msg
            IF NOT shippers_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Shipper update canceled"
       RETURN
    END IF

    CALL update_curr_shippers()
    MESSAGE "Shipper record updated"

END FUNCTION

FUNCTION delete_shippers()
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
        ERROR "Shipper delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_shippers()
    MESSAGE "Shipper record deleted"

END FUNCTION

FUNCTION load_curr_shippers(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_shippers()
   IF currIdx > 0 AND currIdx <= arr_size THEN
      LET curr_shippers = shippers_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_shippers()

   DISPLAY BY NAME curr_shippers.*

END FUNCTION

FUNCTION clear_curr_shippers()

   INITIALIZE curr_shippers.* TO NULL

END FUNCTION

FUNCTION insert_curr_shippers()

   INSERT INTO shippers (shipperid, companyname, phone)
      VALUES (DEFAULT, curr_shippers.companyname, curr_shippers.phone)
   LET curr_shippers.shipperid = sqlca.sqlerrd[2]
   CALL display_curr_shippers()

END FUNCTION

FUNCTION update_curr_shippers()

   UPDATE shippers
      SET companyname = curr_shippers.companyname,
          phone = curr_shippers.phone
    WHERE shipperid = curr_shippers.shipperid

END FUNCTION

FUNCTION delete_curr_shippers()

   DELETE FROM shippers
    WHERE shipperid = curr_shippers.shipperid

END FUNCTION

FUNCTION refresh_shippers(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET shippers_arr[newIdx] = curr_shippers
         LET arr_size = newIdx
      WHEN "C"
         LET shippers_arr[currIdx] = curr_shippers
      WHEN "D"
           LET newIdx = 0
           LET replaceRec = FALSE

           FOR idx = 1 TO arr_size
              IF shippers_arr[idx].shipperid = curr_shippers.shipperid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF
              LET newIdx = newIdx + 1
              LET shippers_arr[newIdx] = shippers_arr[idx]
           END FOR

           IF replaceRec THEN
              INITIALIZE shippers_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF
   END CASE

END FUNCTION #refresh_shippers

FUNCTION validate_shippers(mode)
   DEFINE mode CHAR(1)
   DEFINE shipperExists SMALLINT

   IF mode == "C" THEN
      SELECT 1 INTO shipperExists FROM shippers WHERE shippers.shipperid = curr_shippers.shipperid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Shipper ID is not found"
      END IF
   END IF
   IF curr_shippers.companyname IS NULL OR LENGTH(curr_shippers.companyname) == 0 THEN
      RETURN FALSE, "Company Name is required"
   END IF

   RETURN TRUE, "Okay"
END FUNCTION

-- =====================================================================
-- Function: shipper_lookup
-- Purpose : Open a lookup window for shipper selection
-- =====================================================================
FUNCTION shipper_lookup()
   DEFINE ship_id LIKE shippers.shipperid
   DEFINE ship_name LIKE shippers.companyname

   OPEN WINDOW lookupWindow AT 5,5 WITH FORM "shippers"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   CALL shipper_lookup_menu()
      RETURNING ship_id, ship_name

   CLOSE WINDOW lookupWindow

   RETURN ship_id, ship_name

END FUNCTION #shipper_lookup

FUNCTION shipper_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER
   DEFINE save_arr_max INTEGER

   LET save_arr_max = arr_max
   LET arr_max = 1000
   CALL query_shippers()
   IF arr_size == 0 THEN
      LET arr_max = save_arr_max
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= arr_size AND selectedIdx == 0

       CALL load_curr_shippers(currentIdx)
       CALL display_curr_shippers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Shipper Selection"
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
          COMMAND "Select" "Select the current shipper"
              LET selectedIdx = currentIdx
              CALL load_curr_shippers(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   LET arr_max = save_arr_max

   IF selectedIdx > 0 THEN
      RETURN curr_shippers.shipperid, curr_shippers.companyname
   END IF

   RETURN 0, ""

END FUNCTION #shipper_lookup_menu
