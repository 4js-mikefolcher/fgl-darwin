IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_categories

DATABASE northwind

DEFINE categories_arr DYNAMIC ARRAY OF t_category
DEFINE curr_categories t_category

-- =====================================================================
-- Function: get_config
-- Purpose : Return the controller configuration for categories
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS t_controller_config
   DEFINE cfg t_controller_config
   LET cfg.moduleName   = "categories"
   LET cfg.formName     = "categories"
   LET cfg.listFormName = "categories_list"
   LET cfg.windowTitle  = "Categories Management"
   LET cfg.hasModify    = TRUE
   LET cfg.hasQuery     = TRUE
   LET cfg.hasLookup    = TRUE
   LET cfg.entityName   = "Category"
   -- View commands available for this module
   LET cfg.availableCommands = init_view_commands()
   RETURN cfg
END FUNCTION #get_config

-- =====================================================================
-- Function: init_view_commands (PRIVATE)
-- Purpose : Define which view commands are available for categories
-- =====================================================================
PRIVATE FUNCTION init_view_commands() RETURNS DYNAMIC ARRAY OF t_view_command
   DEFINE cmds DYNAMIC ARRAY OF t_view_command
   LET cmds[1].commandName  = "products"
   LET cmds[1].commandLabel = "Products"
   LET cmds[1].commandComment = "View Products in this Category"
   RETURN cmds
END FUNCTION #init_view_commands

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
   CALL categories_do_load(where_clause)

   IF categories_arr.getLength() == 0 THEN
      CLOSE WINDOW viewCategoryWindow
      ERROR "Category not found"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate_view()

   CLOSE WINDOW viewCategoryWindow

END FUNCTION #view_category

-- =====================================================================
-- Function: submenu_categories
-- Purpose : Standard entry point — query then navigate using controller
-- =====================================================================
FUNCTION submenu_categories()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_categories

-- =====================================================================
-- Function: root_add_categories
-- Purpose : Entry point for categories add from root menu
-- =====================================================================
FUNCTION root_add_categories()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_categories

-- =====================================================================
-- Dispatch Interface: Functions called by the controller via dispatch
-- =====================================================================

-- Return the number of records in the result set
FUNCTION categories_get_count() RETURNS INTEGER
   RETURN categories_arr.getLength()
END FUNCTION #categories_get_count

-- Load the record at index into the current record
FUNCTION categories_load_at(idx INTEGER)
   INITIALIZE curr_categories.* TO NULL
   IF idx > 0 AND idx <= categories_arr.getLength() THEN
      LET curr_categories = categories_arr[idx]
   END IF
END FUNCTION #categories_load_at

-- Display the current record on the form
FUNCTION categories_display_curr()
   DISPLAY BY NAME curr_categories.*
END FUNCTION #categories_display_curr

-- Clear the current record and form
FUNCTION categories_clear_curr()
   INITIALIZE curr_categories.* TO NULL
END FUNCTION #categories_clear_curr

-- =====================================================================
-- Function: categories_do_query
-- Purpose : Search using CONSTRUCT and load results
-- =====================================================================
FUNCTION categories_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL categories_clear_curr()
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
      CALL categories_clear_curr()
      CALL categories_arr.clear()
      RETURN
   END IF

   CALL categories_do_load(where_clause)

   IF categories_arr.getLength() == 0 THEN
      MESSAGE "No categories found."
   END IF

END FUNCTION #categories_do_query

-- =====================================================================
-- Function: categories_do_load
-- Purpose : Load categories into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION categories_do_load(where_clause VARCHAR(500))
   DEFINE sql_stmt VARCHAR(1024)
   DEFINE temp_category t_category

   LET sql_stmt = " SELECT categoryid, categoryname, description",
                  " FROM categories",
                  " WHERE ", where_clause CLIPPED, " ORDER BY categoryid"

   CALL categories_arr.clear()

   PREPARE p_categories FROM sql_stmt
   DECLARE c_categories CURSOR FOR p_categories
   FOREACH c_categories INTO temp_category.*
      CALL categories_arr.appendElement()
      LET categories_arr[categories_arr.getLength()] = temp_category
   END FOREACH

END FUNCTION #categories_do_load

-- =====================================================================
-- Function: categories_do_add
-- Purpose : Add a new category record
-- =====================================================================
FUNCTION categories_do_add()

   CLEAR FORM
   LET int_flag = FALSE
   CALL categories_clear_curr()
   INPUT curr_categories.* WITHOUT DEFAULTS FROM s_categories.*
      ATTRIBUTES(UNBUFFERED)
      ON ACTION accept
          ACCEPT INPUT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT
      AFTER FIELD description
          DISPLAY SFMT("Description = (%1)", curr_categories.description)
      AFTER INPUT
          VAR valid_status = curr_categories.validateRec("A")
          IF NOT valid_status.valid_status THEN
              ERROR valid_status.valid_msg
              CONTINUE INPUT
          END IF
   END INPUT

   IF int_flag THEN
      ERROR "Category add canceled"
      RETURN
   END IF

   VAR ins_status = curr_categories.insertRec()
   IF NOT ins_status.valid_status THEN
      ERROR ins_status.valid_msg
      LET int_flag = TRUE
      RETURN
   END IF

   CALL categories_display_curr()
   MESSAGE ins_status.valid_msg

END FUNCTION #categories_do_add

-- =====================================================================
-- Function: categories_do_edit
-- Purpose : Edit an existing category record
-- =====================================================================
FUNCTION categories_do_edit()

   LET int_flag = FALSE
   INPUT curr_categories.* WITHOUT DEFAULTS FROM s_categories.*
      ATTRIBUTES(UNBUFFERED)
      BEFORE INPUT
          CALL DIALOG.setFieldActive("s_categories.categoryid", FALSE)
      ON ACTION accept
          ACCEPT INPUT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT
      AFTER INPUT
          VAR valid_status = curr_categories.validateRec("C")
          IF NOT valid_status.valid_status THEN
              ERROR valid_status.valid_msg
              CONTINUE INPUT
          END IF
   END INPUT

   IF int_flag THEN
      ERROR "Category update canceled"
      RETURN
   END IF

   VAR upd_status = curr_categories.updateRec()
   IF NOT upd_status.valid_status THEN
      ERROR upd_status.valid_msg
      LET int_flag = TRUE
      RETURN
   END IF

   MESSAGE upd_status.valid_msg

END FUNCTION #categories_do_edit

-- =====================================================================
-- Function: categories_do_delete
-- Purpose : Delete a category record
-- =====================================================================
FUNCTION categories_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "Category delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_categories.deleteRec()
   IF NOT del_status.valid_status THEN
      ERROR del_status.valid_msg
      LET int_flag = TRUE
      RETURN
   END IF

   MESSAGE del_status.valid_msg

END FUNCTION #categories_do_delete

-- =====================================================================
-- Function: categories_do_refresh
-- Purpose : Refresh the array after add, change, or delete
-- =====================================================================
FUNCTION categories_do_refresh(currIdx INTEGER, operation CHAR(1))
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

END FUNCTION #categories_do_refresh

-- =====================================================================
-- Function: categories_list_display
-- Purpose : DISPLAY ARRAY list view for categories
-- =====================================================================
FUNCTION categories_list_display() RETURNS (INTEGER, INTEGER)
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   LET selectedIdx = 0
   LET selectedOption = 0
   LET int_flag = FALSE

   MESSAGE "Displayed ", categories_arr.getLength() USING "<<<<<", " categories"

   DISPLAY ARRAY categories_arr TO categories_list.*
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

   RETURN selectedIdx, selectedOption

END FUNCTION #categories_list_display

-- =====================================================================
-- Function: categories_do_command
-- Purpose : Execute a view command for categories
-- =====================================================================
FUNCTION categories_do_command(commandName STRING)
   CASE commandName
      WHEN "products"
         CALL view_products_for_category(curr_categories.categoryid)
      OTHERWISE
         ERROR "Unknown command: ", commandName
   END CASE

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #categories_do_command

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

-- =====================================================================
-- Function: category_lookup_menu
-- Purpose : Navigation menu for category lookup selection
-- =====================================================================
FUNCTION category_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL categories_do_query()
   IF categories_arr.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= categories_arr.getLength() AND selectedIdx == 0

       CALL categories_load_at(currentIdx)
       CALL categories_display_curr()
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
              CALL categories_load_at(selectedIdx)
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
