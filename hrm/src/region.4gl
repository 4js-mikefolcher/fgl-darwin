IMPORT FGL list_view_helper
DATABASE northwind

TYPE t_region_list RECORD
   regionid LIKE region.regionid,
   regiondescription LIKE region.regiondescription
END RECORD

DEFINE region_arr ARRAY[1000] OF RECORD LIKE region.*
DEFINE curr_region RECORD LIKE region.*
DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

FUNCTION init_region()

   LET arr_max = get_arr_max()

END FUNCTION #init_region

-- =====================================================================
-- Function: view_region
-- Purpose : View a specific region record (called from other modules)
-- =====================================================================
FUNCTION view_region(reg_id)
   DEFINE reg_id LIKE region.regionid
   DEFINE where_clause VARCHAR(255)

   IF reg_id IS NULL OR reg_id < 1 THEN
      ERROR "Region ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewRegionWindow WITH FORM "region"
      ATTRIBUTES(STYLE="modulewindow")

   CALL init_region()
   LET where_clause = " region.regionid = ", reg_id
   CALL load_regions(where_clause)

   IF arr_size == 0 THEN
      CLOSE WINDOW viewRegionWindow
      ERROR "Region not found"
      RETURN
   END IF

   CALL load_curr_region(1)
   CALL display_curr_region()

   MENU "Region View"
      COMMAND "Territories" "View Territories in this Region"
         CALL view_territories_for_region(curr_region.regionid)
      COMMAND "Exit" "Quit operation"
         EXIT MENU
   END MENU

   CLOSE WINDOW viewRegionWindow

END FUNCTION #view_region

FUNCTION submenu_region()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL init_region()
   CALL query_region()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_region(currentIdx)
       CALL display_curr_region()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Region Management"
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
          COMMAND "Add" "Add a new region"
              CALL add_region()
              IF int_flag == FALSE THEN
                 CALL refresh_regions(currentIdx, "A")
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing region"
              CALL edit_region()
              IF int_flag == FALSE THEN
                 CALL refresh_regions(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete a region"
              CALL delete_region()
              IF int_flag == FALSE THEN
                 CALL refresh_regions(currentIdx, "D")
                 IF currentIdx > arr_size THEN
                    LET currentIdx = arr_size
                 END IF
              END IF
              EXIT MENU
          COMMAND "List" "Switch to list view"
              CALL list_region_view()
              EXIT MENU
          COMMAND "Territories" "View Territories in this Region"
              CALL view_territories_for_region(curr_region.regionid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_region

-- =====================================================================
-- Function: list_region_view
-- Purpose : Display regions in a list/table view
-- =====================================================================
FUNCTION list_region_view()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER
   DEFINE list_arr DYNAMIC ARRAY OF t_region_list
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_size
      CALL list_arr.appendElement()
      LET list_arr[idx].regionid = region_arr[idx].regionid
      LET list_arr[idx].regiondescription = region_arr[idx].regiondescription
   END FOR

   OPEN WINDOW listRegionWindow WITH FORM "region_list"
      ATTRIBUTES(STYLE="modulewindow")

   MESSAGE "Displayed ", list_arr.getLength() USING "<<<<<", " regions"

   DISPLAY ARRAY list_arr TO region_list.*
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

   CLOSE WINDOW listRegionWindow

   IF int_flag THEN
      RETURN
   END IF

   CASE selectedOption
      WHEN cAddRecord
         CALL add_region()
         IF int_flag == FALSE THEN
            CALL refresh_regions(arr_size, "A")
         END IF
      WHEN cEditRecord
         IF selectedIdx >= 1 AND selectedIdx <= arr_size THEN
            CALL load_curr_region(selectedIdx)
            CALL edit_region()
            IF int_flag == FALSE THEN
                  CALL refresh_regions(selectedIdx, "C")
            END IF
         ELSE
            ERROR "Please select a region"
         END IF
      WHEN cDeleteRecord
         IF selectedIdx >= 1 AND selectedIdx <= arr_size THEN
            CALL load_curr_region(selectedIdx)
            CALL delete_region()
            IF int_flag == FALSE THEN
                  CALL refresh_regions(selectedIdx, "D")
            END IF
         ELSE
            ERROR "Please select a region"
         END IF
      WHEN cViewRecord
         CALL load_curr_region(selectedIdx)
         CALL display_curr_region()
   END CASE

END FUNCTION #list_region_view

FUNCTION region_lookup()
   DEFINE region_id LIKE region.regionid
   DEFINE region_desc LIKE region.regiondescription

   OPEN WINDOW lookupWindow WITH FORM "region"
      ATTRIBUTES(STYLE="modulewindow")

   CALL region_lookup_menu()
      RETURNING region_id, region_desc

   CLOSE WINDOW lookupWindow

   RETURN region_id, region_desc

END FUNCTION #region_lookup

FUNCTION region_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL init_region()
   CALL query_region()
   IF arr_size == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= arr_size AND selectedIdx == 0

       CALL load_curr_region(currentIdx)
       CALL display_curr_region()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Region Selection"
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
          COMMAND "Select" "Select the current region"
              LET selectedIdx = currentIdx
              CALL load_curr_region(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_region.regionid, curr_region.regiondescription
   END IF

   RETURN 0, ""

END FUNCTION #region_lookup_menu

-- =====================================================================
-- Function: query_region
-- Purpose : Search and display regions using CONSTRUCT, store in array
-- =====================================================================
FUNCTION query_region()
    DEFINE where_clause VARCHAR(255)

    CLEAR FORM
    CALL clear_curr_region()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON region.regionid, region.regiondescription
       FROM s_region.*
       ON ACTION accept
          ACCEPT CONSTRUCT
   
       ON ACTION cancel 
          LET int_flag = TRUE
          EXIT CONSTRUCT
   
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_region()
       CALL clear_regions()
       RETURN
    END IF

    CALL load_regions(where_clause)

    IF arr_size == 0 THEN
        MESSAGE "No regions found."
        RETURN
    END IF

END FUNCTION


-- =====================================================================
-- Function: load_regions
-- Purpose : Load regions into dynamic array based on WHERE clause
-- =====================================================================
FUNCTION load_regions(where_clause)
    DEFINE where_clause VARCHAR(255)
    DEFINE sql_stmt VARCHAR(512)
    DEFINE idx INTEGER

    LET sql_stmt = "SELECT regionid, regiondescription FROM region WHERE ", where_clause, " ORDER BY regionid"

    CALL clear_regions()

    LET idx = 0
    PREPARE p1 FROM sql_stmt
    DECLARE c1 CURSOR FOR p1
    FOREACH c1 INTO curr_region.*
        LET idx = idx + 1
        LET region_arr[idx] = curr_region
    END FOREACH
    CALL clear_curr_region()
    LET arr_size = idx
    
END FUNCTION

FUNCTION clear_regions()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE region_arr[idx].* TO NULL   
   END FOR
   LET arr_size = 0
      
END FUNCTION #clear_regions

-- =====================================================================
-- Function: add_region
-- Purpose : Add a new region record
-- =====================================================================
FUNCTION add_region()
    DEFINE region_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_region()
    INPUT BY NAME curr_region.*
        ATTRIBUTE(UNBUFFERED)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_region("A")
               RETURNING region_valid, valid_msg
            IF NOT region_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Region add canceled"
       RETURN
    END IF

    CALL insert_curr_region()
    MESSAGE "Region record added"
    
END FUNCTION


-- =====================================================================
-- Function: edit_region
-- Purpose : Edit an existing region record
-- =====================================================================
FUNCTION edit_region()
    DEFINE region_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_region.regiondescription
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_region("C")
               RETURNING region_valid, valid_msg
            IF NOT region_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Region update canceled"
       RETURN
    END IF

    CALL update_curr_region()
    MESSAGE "Region record updated"

END FUNCTION


-- =====================================================================
-- Function: delete_region
-- Purpose : Delete an existing region record
-- =====================================================================
FUNCTION delete_region()

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
        ERROR "Region delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_region()
    MESSAGE "Region record deleted"

END FUNCTION

FUNCTION load_curr_region(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_region()
   IF currIdx > 0 AND currIdx <= arr_size THEN
      LET curr_region = region_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_region()

   DISPLAY BY NAME curr_region.*

END FUNCTION

FUNCTION clear_curr_region()

   INITIALIZE curr_region.* TO NULL

END FUNCTION

FUNCTION insert_curr_region()

   INSERT INTO region (regionid, regiondescription)
      VALUES (DEFAULT, curr_region.regiondescription)
   LET curr_region.regionid = sqlca.sqlerrd[2]
   CALL display_curr_region()

END FUNCTION

FUNCTION update_curr_region()

   UPDATE region
      SET regiondescription = curr_region.regiondescription
    WHERE regionid = curr_region.regionid

END FUNCTION

FUNCTION delete_curr_region()

   DELETE FROM region
    WHERE regionid = curr_region.regionid

END FUNCTION

FUNCTION refresh_regions(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET region_arr[newIdx] = curr_region
         LET arr_size = newIdx
      WHEN "C"
         LET region_arr[currIdx] = curr_region
      WHEN "D"
           LET newIdx = 0 
           LET replaceRec = FALSE
              
           FOR idx = 1 TO arr_size
              IF region_arr[idx].regionid = curr_region.regionid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF 
              LET newIdx = newIdx + 1
              LET region_arr[newIdx] = region_arr[idx]
           END FOR 
    
           IF replaceRec THEN
              INITIALIZE region_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF 
   END CASE 

END FUNCTION #refresh_curr_region

FUNCTION validate_region(mode)
   DEFINE mode CHAR(1)
   DEFINE regionExists SMALLINT

   IF mode == "C" THEN
      SELECT 1 INTO regionExists FROM region WHERE region.regionid = curr_region.regionid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Region ID is not found"
      END IF
   END IF
   IF curr_region.regiondescription IS NULL OR LENGTH(curr_region.regiondescription) == 0 THEN
      RETURN FALSE, "Region Description is required"
   END IF
   RETURN TRUE, "Okay"
END FUNCTION
