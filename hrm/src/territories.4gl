DATABASE northwind

DEFINE territories_arr ARRAY[1000] OF RECORD
   territoryid LIKE territories.territoryid,
   territorydescription LIKE territories.territorydescription,
   regionid LIKE territories.regionid,
   regiondescription LIKE region.regiondescription
END RECORD
DEFINE curr_territories RECORD
   territoryid LIKE territories.territoryid,
   territorydescription LIKE territories.territorydescription,
   regionid LIKE territories.regionid,
   regiondescription LIKE region.regiondescription
END RECORD
DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

FUNCTION submenu_territories()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL query_territories()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_territories(currentIdx)
       CALL display_curr_territories()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
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
              IF currentIdx > arr_size THEN
                 LET currentIdx = arr_size
              END IF 
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = arr_size
              EXIT MENU
          COMMAND "Add" "Add a new territory"
              CALL add_territories()
              IF int_flag == FALSE THEN
                 CALL refresh_territories(currentIdx, "A")
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Edit" "Edit an existing territory"
              CALL edit_territories()
              IF int_flag == FALSE THEN
                 CALL refresh_territories(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete a territory"
              CALL delete_territories()
              IF int_flag == FALSE THEN
                 CALL refresh_territories(currentIdx, "D")
                 IF currentIdx > arr_size THEN
                    LET currentIdx = arr_size
                 END IF
              END IF
              EXIT MENU
          COMMAND "Cancel" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_territories

FUNCTION territories_lookup()
   DEFINE territories_id LIKE territories.territoryid

   OPEN WINDOW lookupWindow AT 5,5 WITH FORM "territories"
      ATTRIBUTES(BORDER)

   LET territories_id = territories_lookup_menu()

   CLOSE WINDOW lookupWindow

   RETURN territories_id

END FUNCTION #territories_lookup

FUNCTION territories_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL query_territories()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= arr_size AND selectedIdx == 0

       CALL load_curr_territories(currentIdx)
       CALL display_curr_territories()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
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
              IF currentIdx > arr_size THEN
                 LET currentIdx = arr_size
              END IF 
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = arr_size
              EXIT MENU
          COMMAND "Select" "Select a territory"
              LET selectedIdx = currentIdx
              EXIT MENU
          COMMAND "Cancel" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_territories.territoryid
   END IF
   RETURN ""

END FUNCTION #submenu_territories

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
                              territories.regionid, region.regiondescription
       FROM s_territories.*
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_territories()
       CALL clear_territories()
       RETURN
    END IF

    CALL load_territories(where_clause)

    IF arr_size == 0 THEN
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
    DEFINE idx INTEGER

    LET sql_stmt = " SELECT territoryid, territorydescription, territories.regionid, region.regiondescription",
                   " FROM territories",
                   " INNER JOIN region on region.regionid = territories.regionid",
                   " WHERE ", where_clause, " ORDER BY territoryid"

    CALL clear_territories()

    LET idx = 0
    DISPLAY sql_stmt
    PREPARE p1 FROM sql_stmt
    DECLARE c1 CURSOR FOR p1
    FOREACH c1 INTO curr_territories.*
        LET idx = idx + 1
        LET territories_arr[idx] = curr_territories
    END FOREACH
    CALL clear_curr_territories()
    LET arr_size = idx
    
END FUNCTION

FUNCTION clear_territories()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE territories_arr[idx].* TO NULL   
   END FOR
   LET arr_size = 0
      
END FUNCTION #clear_territories

-- =====================================================================
-- Function: add_territories
-- Purpose : Add a new territory record
-- =====================================================================
FUNCTION add_territories()
    DEFINE territories_valid SMALLINT
    DEFINE valid_msg CHAR(75)
    DEFINE selected_region_id LIKE territories.regionid
    DEFINE selected_region_desc LIKE region.regiondescription

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_territories()
    INPUT BY NAME curr_territories.*
        ATTRIBUTE(UNBUFFERED)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        ON KEY (CONTROL-T)
            IF INFIELD(regionid) THEN
               CALL region_lookup()
                  RETURNING selected_region_id, selected_region_desc
               IF selected_region_id > 0 THEN
                  LET curr_territories.regionid = selected_region_id
                  LET curr_territories.regiondescription = selected_region_desc
               END IF
            END IF
        BEFORE FIELD regionid
           MESSAGE "Use Cntrl-T to open lookup window"
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
    DEFINE selected_region_id LIKE territories.regionid
    DEFINE selected_region_desc LIKE region.regiondescription

    LET int_flag = FALSE
    INPUT BY NAME curr_territories.territorydescription, curr_territories.regionid
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        ON KEY (CONTROL-T)
            IF INFIELD(regionid) THEN
               CALL region_lookup()
                  RETURNING selected_region_id, selected_region_desc
               IF selected_region_id > 0 THEN
                  LET curr_territories.regionid = selected_region_id
                  LET curr_territories.regiondescription = selected_region_desc
               END IF
            END IF
        BEFORE FIELD regionid
           MESSAGE "Use Cntrl-T to open lookup window"
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
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
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
   IF currIdx > 0 AND currIdx <= arr_size THEN
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
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET territories_arr[newIdx] = curr_territories
         LET arr_size = newIdx
      WHEN "C"
         LET territories_arr[currIdx] = curr_territories
      WHEN "D"
           LET newIdx = 0 
           LET replaceRec = FALSE
              
           FOR idx = 1 TO arr_size
              IF territories_arr[idx].territoryid = curr_territories.territoryid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF 
              LET newIdx = newIdx + 1
              LET territories_arr[newIdx] = territories_arr[idx]
           END FOR 
    
           IF replaceRec THEN
              INITIALIZE territories_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF 
   END CASE 

END FUNCTION #refresh_territories

FUNCTION validate_territories(mode)
   DEFINE mode CHAR(1)
   DEFINE territoriesExists SMALLINT
   DEFINE region_desc LIKE region.regiondescription

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
      RETURN FALSE, "Region ID is required"
   END IF
   SELECT regiondescription INTO region_desc FROM region WHERE region.regionid = curr_territories.regionid
   IF sqlca.sqlcode == NOTFOUND THEN
      RETURN FALSE, "Region ID does not exist in region table"
   END IF
   LET curr_territories.regiondescription = region_desc
   RETURN TRUE, "Okay"
END FUNCTION
