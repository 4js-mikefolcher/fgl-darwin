DATABASE northwind

-- =====================================================================
-- Record Type Definitions
-- =====================================================================
TYPE t_category RECORD
   categoryid LIKE categories.categoryid,
   categoryname LIKE categories.categoryname,
   description LIKE categories.description
END RECORD

-- =====================================================================
-- Global Variables
-- =====================================================================
DEFINE categories_arr DYNAMIC ARRAY OF t_category
DEFINE curr_categories t_category

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

   OPEN WINDOW viewCategoryWindow WITH FORM "categories"
      ATTRIBUTES(STYLE="modulewindow")

   LET where_clause = " categories.categoryid = ", cat_id
   CALL load_categories(where_clause)

   IF categories_arr.getLength() == 0 THEN
      CLOSE WINDOW viewCategoryWindow
      ERROR "Category not found"
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

   CALL query_categories()
   IF categories_arr.getLength() == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= categories_arr.getLength()

       CALL load_curr_categories(currentIdx)
       CALL display_curr_categories()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", categories_arr.getLength() USING "<<<<"
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
              IF currentIdx > categories_arr.getLength() THEN
                 LET currentIdx = categories_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = categories_arr.getLength()
              EXIT MENU
          COMMAND "Add" "Add a new category"
              CALL add_categories()
              IF int_flag == FALSE THEN
                 CALL refresh_categories(currentIdx, "A")
                 LET currentIdx = categories_arr.getLength()
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
                 IF currentIdx > categories_arr.getLength() THEN
                    LET currentIdx = categories_arr.getLength()
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
        ON ACTION accept
            ACCEPT CONSTRUCT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_categories()
       CALL clear_categories()
       RETURN
    END IF

    CALL load_categories(where_clause)

    IF categories_arr.getLength() == 0 THEN
        MESSAGE "No categories found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_categories(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE temp_category t_category

    LET sql_stmt = " SELECT categoryid, categoryname, description",
                   " FROM categories",
                   " WHERE ", where_clause CLIPPED, " ORDER BY categoryid"

    CALL clear_categories()

    PREPARE p_categories FROM sql_stmt
    DECLARE c_categories CURSOR FOR p_categories
    FOREACH c_categories INTO temp_category.*
        CALL categories_arr.appendElement()
        LET categories_arr[categories_arr.getLength()] = temp_category
    END FOREACH
    CALL clear_curr_categories()

END FUNCTION

FUNCTION clear_categories()
   CALL categories_arr.clear()
END FUNCTION #clear_categories

FUNCTION add_categories()
    DEFINE categories_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_categories()
    INPUT curr_categories.* WITHOUT DEFAULTS FROM s_categories.*
        ATTRIBUTE(UNBUFFERED)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER FIELD description
            DISPLAY SFMT("Description = (%1)", curr_categories.description)
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
    INPUT curr_categories.* WITHOUT DEFAULTS FROM s_categories.*
        ATTRIBUTE(UNBUFFERED)
        BEFORE INPUT
            CALL DIALOG.setFieldActive("s_categories.categoryid", FALSE)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
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

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
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
   IF currIdx > 0 AND currIdx <= categories_arr.getLength() THEN
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
      VALUES (DEFAULT, curr_categories.categoryname, curr_categories.description)
   LET curr_categories.categoryid = sqlca.sqlerrd[2]
   CALL display_curr_categories()

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
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL categories_arr.appendElement()
         LET categories_arr[categories_arr.getLength()] = curr_categories
      WHEN "C"
         LET categories_arr[currIdx] = curr_categories
      WHEN "D"
         FOR idx = 1 TO categories_arr.getLength()
            IF categories_arr[idx].categoryid = curr_categories.categoryid THEN
               CALL categories_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #refresh_categories

FUNCTION validate_categories(mode)
   DEFINE mode CHAR(1)
   DEFINE categoryExists SMALLINT

   IF mode == "C" THEN
      SELECT 1 INTO categoryExists FROM categories WHERE categories.categoryid = curr_categories.categoryid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Category ID is not found"
      END IF
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

   OPEN WINDOW lookupWindow WITH FORM "categories"
      ATTRIBUTES(STYLE="modulewindow")

   CALL category_lookup_menu()
      RETURNING cat_id, cat_name

   CLOSE WINDOW lookupWindow

   RETURN cat_id, cat_name

END FUNCTION #category_lookup

FUNCTION category_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL query_categories()
   IF categories_arr.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= categories_arr.getLength() AND selectedIdx == 0

       CALL load_curr_categories(currentIdx)
       CALL display_curr_categories()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", categories_arr.getLength() USING "<<<<"
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
              IF currentIdx > categories_arr.getLength() THEN
                 LET currentIdx = categories_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = categories_arr.getLength()
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

   IF selectedIdx > 0 THEN
      RETURN curr_categories.categoryid, curr_categories.categoryname
   END IF

   RETURN 0, ""

END FUNCTION #category_lookup_menu
