DATABASE northwind

DEFINE categories_arr ARRAY[1000] OF RECORD
   categoryid LIKE categories.categoryid,
   categoryname LIKE categories.categoryname,
   description LIKE categories.description
END RECORD

DEFINE curr_categories RECORD
   categoryid LIKE categories.categoryid,
   categoryname LIKE categories.categoryname,
   description LIKE categories.description
END RECORD

DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

-- =====================================================================
-- Function: view_category
-- Purpose : View a specific category record (called from other modules)
-- =====================================================================
FUNCTION view_category(cat_id)
   DEFINE cat_id LIKE categories.categoryid
   DEFINE where_clause VARCHAR(500)

   IF cat_id IS NULL OR cat_id < 1 THEN
      ERROR "Category ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewCategoryWindow AT 5,5 WITH FORM "categories"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   LET arr_max = 1000
   LET where_clause = " categories.categoryid = ", cat_id
   CALL load_categories(where_clause)

   IF arr_size == 0 THEN
      ERROR "Category not found"
      CLOSE WINDOW viewCategoryWindow
      RETURN
   END IF

   CALL load_curr_categories(1)
   CALL display_curr_categories()

   MENU "Category View"
      COMMAND "Products" "View Products in this Category"
         CALL view_products_for_category(curr_categories.categoryid)
      COMMAND "Exit" "Quit operation"
         EXIT MENU
   END MENU

   CLOSE WINDOW viewCategoryWindow

END FUNCTION #view_category

FUNCTION submenu_categories()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET arr_max = 1000
   CALL query_categories()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_categories(currentIdx)
       CALL display_curr_categories()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Categories Management"
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
          COMMAND "Add" "Add a new category"
              CALL add_categories()
              IF int_flag == FALSE THEN
                 CALL refresh_categories(currentIdx, "A")
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing category"
              CALL edit_categories()
              IF int_flag == FALSE THEN
                 CALL refresh_categories(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete a category"
              CALL delete_categories()
              IF int_flag == FALSE THEN
                 CALL refresh_categories(currentIdx, "D")
                 IF currentIdx > arr_size THEN
                    LET currentIdx = arr_size
                 END IF
              END IF
              EXIT MENU
          COMMAND "Products" "View Products in this Category"
              CALL view_products_for_category(curr_categories.categoryid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_categories

FUNCTION query_categories()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_categories()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON categories.categoryid, categories.categoryname, categories.description
       FROM s_categories.*
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_categories()
       CALL clear_categories()
       RETURN
    END IF

    CALL load_categories(where_clause)

    IF arr_size == 0 THEN
        MESSAGE "No categories found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_categories(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE idx INTEGER

    LET sql_stmt = " SELECT categoryid, categoryname, description",
                   " FROM categories",
                   " WHERE ", where_clause CLIPPED, " ORDER BY categoryid"

    CALL clear_categories()

    LET idx = 0
    PREPARE p_categories FROM sql_stmt
    DECLARE c_categories CURSOR FOR p_categories
    FOREACH c_categories INTO curr_categories.*
        LET idx = idx + 1
        LET categories_arr[idx] = curr_categories
    END FOREACH
    CALL clear_curr_categories()
    LET arr_size = idx

END FUNCTION

FUNCTION clear_categories()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE categories_arr[idx].* TO NULL
   END FOR
   LET arr_size = 0

END FUNCTION #clear_categories

FUNCTION add_categories()
    DEFINE categories_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_categories()
    INPUT BY NAME curr_categories.*
        ATTRIBUTE(UNBUFFERED)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_categories("A")
               RETURNING categories_valid, valid_msg
            IF NOT categories_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Category add canceled"
       RETURN
    END IF

    CALL insert_curr_categories()
    MESSAGE "Category record added"

END FUNCTION

FUNCTION edit_categories()
    DEFINE categories_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_categories.categoryname, curr_categories.description
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_categories("C")
               RETURNING categories_valid, valid_msg
            IF NOT categories_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Category update canceled"
       RETURN
    END IF

    CALL update_curr_categories()
    MESSAGE "Category record updated"

END FUNCTION

FUNCTION delete_categories()
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
        ERROR "Category delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_categories()
    MESSAGE "Category record deleted"

END FUNCTION

FUNCTION load_curr_categories(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_categories()
   IF currIdx > 0 AND currIdx <= arr_size THEN
      LET curr_categories = categories_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_categories()

   DISPLAY BY NAME curr_categories.*

END FUNCTION

FUNCTION clear_curr_categories()

   INITIALIZE curr_categories.* TO NULL

END FUNCTION

FUNCTION insert_curr_categories()

   INSERT INTO categories (categoryid, categoryname, description)
      VALUES (curr_categories.categoryid, curr_categories.categoryname, curr_categories.description)

END FUNCTION

FUNCTION update_curr_categories()

   UPDATE categories
      SET categoryname = curr_categories.categoryname,
          description = curr_categories.description
    WHERE categoryid = curr_categories.categoryid

END FUNCTION

FUNCTION delete_curr_categories()

   DELETE FROM categories
    WHERE categoryid = curr_categories.categoryid

END FUNCTION

FUNCTION refresh_categories(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET categories_arr[newIdx] = curr_categories
         LET arr_size = newIdx
      WHEN "C"
         LET categories_arr[currIdx] = curr_categories
      WHEN "D"
           LET newIdx = 0
           LET replaceRec = FALSE

           FOR idx = 1 TO arr_size
              IF categories_arr[idx].categoryid = curr_categories.categoryid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF
              LET newIdx = newIdx + 1
              LET categories_arr[newIdx] = categories_arr[idx]
           END FOR

           IF replaceRec THEN
              INITIALIZE categories_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF
   END CASE

END FUNCTION #refresh_categories

FUNCTION validate_categories(mode)
   DEFINE mode CHAR(1)
   DEFINE categoryExists SMALLINT

   SELECT 1 INTO categoryExists FROM categories WHERE categories.categoryid = curr_categories.categoryid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      RETURN FALSE, "Category ID is not found"
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      RETURN FALSE, "Category ID already exists"
   END IF
   IF curr_categories.categoryid IS NULL THEN
      RETURN FALSE, "Category ID is required"
   END IF
   IF curr_categories.categoryname IS NULL OR LENGTH(curr_categories.categoryname) == 0 THEN
      RETURN FALSE, "Category Name is required"
   END IF

   RETURN TRUE, "Okay"
END FUNCTION

-- =====================================================================
-- Function: category_lookup
-- Purpose : Open a lookup window for category selection
-- =====================================================================
FUNCTION category_lookup()
   DEFINE cat_id LIKE categories.categoryid
   DEFINE cat_name LIKE categories.categoryname

   OPEN WINDOW lookupWindow AT 5,5 WITH FORM "categories"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   CALL category_lookup_menu()
      RETURNING cat_id, cat_name

   CLOSE WINDOW lookupWindow

   RETURN cat_id, cat_name

END FUNCTION #category_lookup

FUNCTION category_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER
   DEFINE save_arr_max INTEGER

   LET save_arr_max = arr_max
   LET arr_max = 1000
   CALL query_categories()
   IF arr_size == 0 THEN
      LET arr_max = save_arr_max
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= arr_size AND selectedIdx == 0

       CALL load_curr_categories(currentIdx)
       CALL display_curr_categories()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Category Selection"
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
          COMMAND "Select" "Select the current category"
              LET selectedIdx = currentIdx
              CALL load_curr_categories(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   LET arr_max = save_arr_max

   IF selectedIdx > 0 THEN
      RETURN curr_categories.categoryid, curr_categories.categoryname
   END IF

   RETURN 0, ""

END FUNCTION #category_lookup_menu
