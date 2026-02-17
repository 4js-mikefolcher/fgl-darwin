DATABASE northwind

TYPE t_shipper RECORD
   shipperid SMALLINT,
   companyname VARCHAR(40),
   phone VARCHAR(24)
END RECORD

DEFINE shippers_arr DYNAMIC ARRAY OF t_shipper
DEFINE curr_shippers t_shipper

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

   OPEN WINDOW viewShipperWindow WITH FORM "shippers"
      ATTRIBUTES(STYLE="modulewindow")

   LET where_clause = " shippers.shipperid = ", ship_id
   CALL load_shippers(where_clause)

   IF shippers_arr.getLength() == 0 THEN
      CLOSE WINDOW viewShipperWindow
      ERROR "Shipper not found"
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

   CALL query_shippers()
   IF shippers_arr.getLength() == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= shippers_arr.getLength()

       CALL load_curr_shippers(currentIdx)
       CALL display_curr_shippers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", shippers_arr.getLength() USING "<<<<"
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
              IF currentIdx > shippers_arr.getLength() THEN
                 LET currentIdx = shippers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = shippers_arr.getLength()
              EXIT MENU
          COMMAND "Add" "Add a new shipper"
              CALL add_shippers()
              IF int_flag == FALSE THEN
                 CALL refresh_shippers(currentIdx, "A")
                 LET currentIdx = shippers_arr.getLength()
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
                 IF currentIdx > shippers_arr.getLength() THEN
                    LET currentIdx = shippers_arr.getLength()
                 END IF
              END IF
              EXIT MENU
          COMMAND "List" "Switch to list view"
              CALL list_shippers_view()
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_shippers

FUNCTION list_shippers_view()
   DEFINE selectedIdx INTEGER

   OPEN WINDOW listShippersWindow WITH FORM "shippers_list"
      ATTRIBUTES(STYLE="modulewindow")

   MESSAGE "Displayed ", shippers_arr.getLength() USING "<<<<<", " shippers"

   DISPLAY ARRAY shippers_arr TO shippers_list.*
       ON ACTION add
           CALL add_shippers()
           IF int_flag == FALSE THEN
              CALL refresh_shippers(shippers_arr.getLength(), "A")
           END IF
       ON ACTION modify
           LET selectedIdx = ARR_CURR()
           IF selectedIdx >= 1 AND selectedIdx <= shippers_arr.getLength() THEN
               CALL load_curr_shippers(selectedIdx)
               CALL edit_shippers()
               IF int_flag == FALSE THEN
                   CALL refresh_shippers(selectedIdx, "C")
               END IF
           ELSE
               ERROR "Please select a shipper"
           END IF
       ON ACTION delete
           LET selectedIdx = ARR_CURR()
           IF selectedIdx >= 1 AND selectedIdx <= shippers_arr.getLength() THEN
               CALL load_curr_shippers(selectedIdx)
               CALL delete_shippers()
               IF int_flag == FALSE THEN
                   CALL refresh_shippers(selectedIdx, "D")
               END IF
           ELSE
               ERROR "Please select a shipper"
           END IF
       ON ACTION exit
           EXIT DISPLAY
       ON KEY (ESCAPE)
           EXIT DISPLAY
   END DISPLAY

   CLOSE WINDOW listShippersWindow

END FUNCTION #list_shippers_view

FUNCTION query_shippers()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_shippers()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON shippers.shipperid, shippers.companyname, shippers.phone
       FROM s_shippers.*
        ON ACTION accept
            ACCEPT CONSTRUCT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_shippers()
       CALL clear_shippers()
       RETURN
    END IF

    CALL load_shippers(where_clause)

    IF shippers_arr.getLength() == 0 THEN
        MESSAGE "No shippers found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_shippers(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE temp_shipper t_shipper

    LET sql_stmt = " SELECT shipperid, companyname, phone",
                   " FROM shippers",
                   " WHERE ", where_clause CLIPPED, " ORDER BY companyname"

    CALL clear_shippers()

    PREPARE p_shippers FROM sql_stmt
    DECLARE c_shippers CURSOR FOR p_shippers
    FOREACH c_shippers INTO temp_shipper.*
        CALL shippers_arr.appendElement()
        LET shippers_arr[shippers_arr.getLength()] = temp_shipper
    END FOREACH
    CALL clear_curr_shippers()

END FUNCTION

FUNCTION clear_shippers()

   CALL shippers_arr.clear()

END FUNCTION

FUNCTION add_shippers()
    DEFINE shippers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_shippers()
    INPUT curr_shippers.* WITHOUT DEFAULTS FROM s_shippers.*
        ATTRIBUTES(UNBUFFERED)
        ON ACTION cancel
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
        ON ACTION cancel
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

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
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
   IF currIdx > 0 AND currIdx <= shippers_arr.getLength() THEN
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
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL shippers_arr.appendElement()
         LET shippers_arr[shippers_arr.getLength()] = curr_shippers
      WHEN "C"
         LET shippers_arr[currIdx] = curr_shippers
      WHEN "D"
         FOR idx = 1 TO shippers_arr.getLength()
            IF shippers_arr[idx].shipperid = curr_shippers.shipperid THEN
               CALL shippers_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION

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

   IF NVL(curr_shippers.phone, "NULL") == "NULL" THEN
      RETURN FALSE, "Phone number is required"
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

   OPEN WINDOW lookupWindow WITH FORM "shippers"
      ATTRIBUTES(STYLE="modulewindow")

   CALL shipper_lookup_menu()
      RETURNING ship_id, ship_name

   CLOSE WINDOW lookupWindow

   RETURN ship_id, ship_name

END FUNCTION #shipper_lookup

FUNCTION shipper_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL query_shippers()
   IF shippers_arr.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= shippers_arr.getLength() AND selectedIdx == 0

       CALL load_curr_shippers(currentIdx)
       CALL display_curr_shippers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", shippers_arr.getLength() USING "<<<<"
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
              IF currentIdx > shippers_arr.getLength() THEN
                 LET currentIdx = shippers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = shippers_arr.getLength()
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

   IF selectedIdx > 0 THEN
      RETURN curr_shippers.shipperid, curr_shippers.companyname
   END IF

   RETURN 0, ""

END FUNCTION
