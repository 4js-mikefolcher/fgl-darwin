IMPORT FGL list_view_helper
IMPORT FGL controller

DATABASE northwind

TYPE t_product RECORD
   productid SMALLINT,
   productname VARCHAR(40),
   supplierid SMALLINT,
   categoryid SMALLINT,
   quantityperunit VARCHAR(20),
   unitprice FLOAT,
   unitsinstock SMALLINT,
   unitsonorder SMALLINT,
   reorderlevel SMALLINT,
   discontinued INTEGER
END RECORD

DEFINE products_arr DYNAMIC ARRAY OF t_product
DEFINE curr_products t_product

-- =====================================================================
-- Function: get_config
-- Purpose : Return the controller configuration for products
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS t_controller_config
   DEFINE cfg t_controller_config
   LET cfg.moduleName   = "products"
   LET cfg.formName     = "products"
   LET cfg.listFormName = "products_list"
   LET cfg.windowTitle  = "Products Management"
   LET cfg.hasModify    = TRUE
   LET cfg.hasQuery     = TRUE
   LET cfg.hasLookup    = TRUE
   LET cfg.entityName   = "Product"
   -- View commands available for this module
   LET cfg.availableCommands = init_view_commands()
   RETURN cfg
END FUNCTION #get_config

-- =====================================================================
-- Function: init_view_commands (PRIVATE)
-- Purpose : Define which view commands are available for products
-- =====================================================================
PRIVATE FUNCTION init_view_commands() RETURNS DYNAMIC ARRAY OF t_view_command
   DEFINE cmds DYNAMIC ARRAY OF t_view_command
   LET cmds[1].commandName  = "supplier"
   LET cmds[1].commandLabel = "Supplier"
   LET cmds[1].commandComment = "View Supplier for this Product"
   LET cmds[2].commandName  = "category"
   LET cmds[2].commandLabel = "Category"
   LET cmds[2].commandComment = "View Category for this Product"
   RETURN cmds
END FUNCTION #init_view_commands

-- =====================================================================
-- Function: view_product
-- Purpose : View a specific product record (called from other modules)
-- =====================================================================
FUNCTION view_product(prod_id)
   DEFINE prod_id LIKE products.productid
   DEFINE where_clause VARCHAR(500)

   IF prod_id IS NULL OR prod_id < 1 THEN
      ERROR "Product ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewProductWindow WITH FORM "products"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_supplier_combo()
   CALL populate_category_combo()
   LET where_clause = " products.productid = ", prod_id
   CALL products_do_load(where_clause)

   IF products_arr.getLength() == 0 THEN
      CLOSE WINDOW viewProductWindow
      ERROR "Product not found"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate_view()

   CLOSE WINDOW viewProductWindow

END FUNCTION #view_product

-- =====================================================================
-- Function: view_products_for_supplier
-- Purpose : View products for a specific supplier
-- =====================================================================
FUNCTION view_products_for_supplier(supp_id)
   DEFINE supp_id LIKE suppliers.supplierid
   DEFINE where_clause VARCHAR(500)

   IF supp_id IS NULL OR supp_id < 1 THEN
      ERROR "Supplier ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewProductsWindow WITH FORM "products"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_supplier_combo()
   CALL populate_category_combo()
   LET where_clause = " products.supplierid = ", supp_id
   CALL products_do_load(where_clause)

   IF products_arr.getLength() == 0 THEN
      CLOSE WINDOW viewProductsWindow
      ERROR "No Products found for this Supplier"
      RETURN
   END IF

   CALL submenu_products_view()

   CLOSE WINDOW viewProductsWindow

END FUNCTION #view_products_for_supplier

-- =====================================================================
-- Function: view_products_for_category
-- Purpose : View products for a specific category
-- =====================================================================
FUNCTION view_products_for_category(cat_id)
   DEFINE cat_id LIKE categories.categoryid
   DEFINE where_clause VARCHAR(500)

   IF cat_id IS NULL OR cat_id < 1 THEN
      ERROR "Category ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewProductsWindow WITH FORM "products"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_supplier_combo()
   CALL populate_category_combo()
   LET where_clause = " products.categoryid = ", cat_id
   CALL products_do_load(where_clause)

   IF products_arr.getLength() == 0 THEN
      CLOSE WINDOW viewProductsWindow
      ERROR "No Products found for this Category"
      RETURN
   END IF

   CALL submenu_products_view()

   CLOSE WINDOW viewProductsWindow

END FUNCTION #view_products_for_category

-- =====================================================================
-- Function: submenu_products_view
-- Purpose : View-only navigation for products (called from view_products_for_*)
--           Now delegates to the generic controller_navigate_view()
-- =====================================================================
FUNCTION submenu_products_view()

   CALL controller_init(get_config())
   CALL controller_navigate_view()

END FUNCTION #submenu_products_view

-- =====================================================================
-- Function: submenu_products
-- Purpose : Standard entry point — query then navigate using controller
-- =====================================================================
FUNCTION submenu_products()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_products

-- =====================================================================
-- Dispatch Interface: Functions called by the controller via dispatch
-- =====================================================================

-- Return the number of records in the result set
FUNCTION products_get_count() RETURNS INTEGER
   RETURN products_arr.getLength()
END FUNCTION #products_get_count

-- Load the record at index into the current record
FUNCTION products_load_at(idx INTEGER)
   INITIALIZE curr_products.* TO NULL
   IF idx > 0 AND idx <= products_arr.getLength() THEN
      LET curr_products = products_arr[idx]
   END IF
END FUNCTION #products_load_at

-- Display the current record on the form
FUNCTION products_display_curr()
   DISPLAY BY NAME curr_products.*
END FUNCTION #products_display_curr

-- Clear the current record and form
FUNCTION products_clear_curr()
   INITIALIZE curr_products.* TO NULL
END FUNCTION #products_clear_curr

-- =====================================================================
-- Function: products_do_query
-- Purpose : Search using CONSTRUCT and load results
-- =====================================================================
FUNCTION products_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL products_clear_curr()
   CALL populate_supplier_combo()
   CALL populate_category_combo()
   LET int_flag = FALSE
   CONSTRUCT where_clause ON products.productid, products.productname, products.supplierid,
                             products.categoryid, products.quantityperunit, products.unitprice,
                             products.unitsinstock, products.unitsonorder, products.reorderlevel,
                             products.discontinued
      FROM s_products.*
      ON ACTION accept
          ACCEPT CONSTRUCT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL products_clear_curr()
      CALL products_arr.clear()
      RETURN
   END IF

   CALL products_do_load(where_clause)

   IF products_arr.getLength() == 0 THEN
      MESSAGE "No products found."
   END IF

END FUNCTION #products_do_query

-- =====================================================================
-- Function: products_do_load
-- Purpose : Load products into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION products_do_load(where_clause VARCHAR(500))
   DEFINE sql_stmt VARCHAR(1024)
   DEFINE temp_product t_product

   LET sql_stmt = " SELECT productid, productname, supplierid,",
                  " categoryid, quantityperunit, unitprice,",
                  " unitsinstock, unitsonorder, reorderlevel, discontinued",
                  " FROM products",
                  " WHERE ", where_clause CLIPPED, " ORDER BY productname"

   CALL products_arr.clear()

   PREPARE p_products FROM sql_stmt
   DECLARE c_products CURSOR FOR p_products
   FOREACH c_products INTO temp_product.*
      CALL products_arr.appendElement()
      LET products_arr[products_arr.getLength()] = temp_product
   END FOREACH

END FUNCTION #products_do_load

-- =====================================================================
-- Function: products_do_add
-- Purpose : Add a new product record
-- =====================================================================
FUNCTION products_do_add()
   DEFINE products_valid SMALLINT
   DEFINE valid_msg CHAR(75)

   CLEAR FORM
   LET int_flag = FALSE
   CALL products_clear_curr()
   LET curr_products.discontinued = 0
   CALL populate_supplier_combo()
   CALL populate_category_combo()
   INPUT BY NAME curr_products.*
      ATTRIBUTES(UNBUFFERED)
      ON ACTION accept
          ACCEPT INPUT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT
      AFTER INPUT
          CALL products_validate("A")
             RETURNING products_valid, valid_msg
          IF NOT products_valid THEN
              ERROR valid_msg
              CONTINUE INPUT
          END IF
   END INPUT

   IF int_flag THEN
      ERROR "Product add canceled"
      RETURN
   END IF

   INSERT INTO products (productid, productname, supplierid, categoryid,
                         quantityperunit, unitprice, unitsinstock, unitsonorder,
                         reorderlevel, discontinued)
      VALUES (DEFAULT, curr_products.productname, curr_products.supplierid,
              curr_products.categoryid, curr_products.quantityperunit, curr_products.unitprice,
              curr_products.unitsinstock, curr_products.unitsonorder, curr_products.reorderlevel,
              curr_products.discontinued)
   LET curr_products.productid = sqlca.sqlerrd[2]
   CALL products_display_curr()
   MESSAGE "Product record added"

END FUNCTION #products_do_add

-- =====================================================================
-- Function: products_do_edit
-- Purpose : Edit an existing product record
-- =====================================================================
FUNCTION products_do_edit()
   DEFINE products_valid SMALLINT
   DEFINE valid_msg CHAR(75)

   LET int_flag = FALSE
   INPUT BY NAME curr_products.productname, curr_products.supplierid, curr_products.categoryid,
                 curr_products.quantityperunit, curr_products.unitprice, curr_products.unitsinstock,
                 curr_products.unitsonorder, curr_products.reorderlevel, curr_products.discontinued
      ATTRIBUTES(UNBUFFERED, WITHOUT DEFAULTS)
      ON ACTION accept
          ACCEPT INPUT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT
      AFTER INPUT
          CALL products_validate("C")
             RETURNING products_valid, valid_msg
          IF NOT products_valid THEN
              ERROR valid_msg
              CONTINUE INPUT
          END IF
   END INPUT

   IF int_flag THEN
      ERROR "Product update canceled"
      RETURN
   END IF

   UPDATE products
      SET productname = curr_products.productname,
          supplierid = curr_products.supplierid,
          categoryid = curr_products.categoryid,
          quantityperunit = curr_products.quantityperunit,
          unitprice = curr_products.unitprice,
          unitsinstock = curr_products.unitsinstock,
          unitsonorder = curr_products.unitsonorder,
          reorderlevel = curr_products.reorderlevel,
          discontinued = curr_products.discontinued
    WHERE productid = curr_products.productid
   MESSAGE "Product record updated"

END FUNCTION #products_do_edit

-- =====================================================================
-- Function: products_do_delete
-- Purpose : Delete a product record
-- =====================================================================
FUNCTION products_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "Product delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   DELETE FROM products
    WHERE productid = curr_products.productid
   MESSAGE "Product record deleted"

END FUNCTION #products_do_delete

-- =====================================================================
-- Function: products_do_refresh
-- Purpose : Refresh the array after add, change, or delete
-- =====================================================================
FUNCTION products_do_refresh(currIdx INTEGER, operation CHAR(1))
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL products_arr.appendElement()
         LET products_arr[products_arr.getLength()] = curr_products
      WHEN "C"
         LET products_arr[currIdx] = curr_products
      WHEN "D"
         FOR idx = 1 TO products_arr.getLength()
            IF products_arr[idx].productid = curr_products.productid THEN
               CALL products_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #products_do_refresh

-- =====================================================================
-- Function: products_list_display
-- Purpose : DISPLAY ARRAY list view for products
-- =====================================================================
FUNCTION products_list_display() RETURNS (INTEGER, INTEGER)
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   LET selectedIdx = 0
   LET selectedOption = 0
   LET int_flag = FALSE

   MESSAGE "Displayed ", products_arr.getLength() USING "<<<<<", " products"

   DISPLAY ARRAY products_arr TO products_list.*
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

END FUNCTION #products_list_display

-- =====================================================================
-- Function: products_do_command
-- Purpose : Execute a view command for products
-- =====================================================================
FUNCTION products_do_command(commandName STRING)
   CASE commandName
      WHEN "supplier"
         CALL view_supplier(curr_products.supplierid)
      WHEN "category"
         CALL view_category(curr_products.categoryid)
      OTHERWISE
         ERROR "Unknown command: ", commandName
   END CASE

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #products_do_command

-- =====================================================================
-- Function: products_validate
-- Purpose : Validate the current product record
-- =====================================================================
FUNCTION products_validate(mode CHAR(1)) RETURNS (SMALLINT, CHAR(75))
   DEFINE productExists SMALLINT

   IF mode == "C" THEN
      SELECT 1 INTO productExists FROM products WHERE products.productid = curr_products.productid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Product ID is not found"
      END IF
   END IF
   IF curr_products.productname IS NULL OR LENGTH(curr_products.productname) == 0 THEN
      RETURN FALSE, "Product Name is required"
   END IF
   IF curr_products.discontinued IS NULL THEN
      RETURN FALSE, "Discontinued flag is required"
   END IF

   RETURN TRUE, "Okay"

END FUNCTION #products_validate

-- =====================================================================
-- Function: populate_supplier_combo
-- Purpose : Populate the supplier combobox from the suppliers table
-- =====================================================================
FUNCTION populate_supplier_combo()
   DEFINE cb ui.ComboBox
   DEFINE sup_id SMALLINT
   DEFINE sup_name VARCHAR(40)

   LET cb = ui.ComboBox.forName("supplierid")
   IF cb IS NULL THEN
      RETURN
   END IF
   CALL cb.clear()
   DECLARE c_sup_combo CURSOR FOR
      SELECT supplierid, companyname FROM suppliers ORDER BY companyname
   FOREACH c_sup_combo INTO sup_id, sup_name
      CALL cb.addItem(sup_id, sup_name)
   END FOREACH

END FUNCTION #populate_supplier_combo

-- =====================================================================
-- Function: populate_category_combo
-- Purpose : Populate the category combobox from the categories table
-- =====================================================================
FUNCTION populate_category_combo()
   DEFINE cb ui.ComboBox
   DEFINE cat_id SMALLINT
   DEFINE cat_name VARCHAR(15)

   LET cb = ui.ComboBox.forName("categoryid")
   IF cb IS NULL THEN
      RETURN
   END IF
   CALL cb.clear()
   DECLARE c_cat_combo CURSOR FOR
      SELECT categoryid, categoryname FROM categories ORDER BY categoryname
   FOREACH c_cat_combo INTO cat_id, cat_name
      CALL cb.addItem(cat_id, cat_name)
   END FOREACH

END FUNCTION #populate_category_combo

-- =====================================================================
-- Function: product_lookup
-- Purpose : Open a lookup window for product selection
-- =====================================================================
FUNCTION product_lookup()
   DEFINE prod_id LIKE products.productid
   DEFINE prod_name LIKE products.productname

   OPEN WINDOW lookupWindow WITH FORM "products"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_supplier_combo()
   CALL populate_category_combo()
   CALL product_lookup_menu()
      RETURNING prod_id, prod_name

   CLOSE WINDOW lookupWindow

   RETURN prod_id, prod_name

END FUNCTION #product_lookup

-- =====================================================================
-- Function: product_lookup_menu
-- Purpose : Navigation menu for product lookup selection
-- =====================================================================
FUNCTION product_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL products_do_query()
   IF products_arr.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= products_arr.getLength() AND selectedIdx == 0

       CALL products_load_at(currentIdx)
       CALL products_display_curr()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", products_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Product Selection"
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
              IF currentIdx > products_arr.getLength() THEN
                 LET currentIdx = products_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = products_arr.getLength()
              EXIT MENU
          COMMAND "Select" "Select the current product"
              LET selectedIdx = currentIdx
              CALL products_load_at(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_products.productid, curr_products.productname
   END IF

   RETURN 0, ""

END FUNCTION #product_lookup_menu
