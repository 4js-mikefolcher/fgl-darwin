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

   OPEN WINDOW viewProductWindow AT 5,5 WITH FORM "products"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   CALL populate_supplier_combo()
   CALL populate_category_combo()
   LET where_clause = " products.productid = ", prod_id
   CALL load_products(where_clause)

   IF products_arr.getLength() == 0 THEN
      ERROR "Product not found"
      CLOSE WINDOW viewProductWindow
      RETURN
   END IF

   CALL load_curr_products(1)
   CALL display_curr_products()

   MENU "Product View"
      COMMAND "Supplier" "View Supplier"
         CALL view_supplier(curr_products.supplierid)
      COMMAND "Category" "View Category"
         CALL view_category(curr_products.categoryid)
      COMMAND "Exit" "Quit operation"
         EXIT MENU
   END MENU

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

   OPEN WINDOW viewProductsWindow AT 5,5 WITH FORM "products"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   CALL populate_supplier_combo()
   CALL populate_category_combo()
   LET where_clause = " p.supplierid = ", supp_id
   CALL load_products(where_clause)

   IF products_arr.getLength() == 0 THEN
      MESSAGE "No products found for this supplier"
      CLOSE WINDOW viewProductsWindow
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

   OPEN WINDOW viewProductsWindow AT 5,5 WITH FORM "products"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   CALL populate_supplier_combo()
   CALL populate_category_combo()
   LET where_clause = " p.categoryid = ", cat_id
   CALL load_products(where_clause)

   IF products_arr.getLength() == 0 THEN
      MESSAGE "No products found for this category"
      CLOSE WINDOW viewProductsWindow
      RETURN
   END IF

   CALL submenu_products_view()

   CLOSE WINDOW viewProductsWindow

END FUNCTION #view_products_for_category

-- =====================================================================
-- Function: submenu_products_view
-- Purpose : View-only submenu for products (no add/modify/delete)
-- =====================================================================
FUNCTION submenu_products_view()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= products_arr.getLength()

       CALL load_curr_products(currentIdx)
       CALL display_curr_products()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", products_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Products View"
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
          COMMAND "Supplier" "View Supplier"
              CALL view_supplier(curr_products.supplierid)
          COMMAND "Category" "View Category"
              CALL view_category(curr_products.categoryid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_products_view

FUNCTION submenu_products()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL query_products()
   IF products_arr.getLength() == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= products_arr.getLength()

       CALL load_curr_products(currentIdx)
       CALL display_curr_products()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", products_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Products Management"
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
          COMMAND "Add" "Add a new product"
              CALL add_products()
              IF int_flag == FALSE THEN
                 CALL refresh_products(currentIdx, "A")
                 LET currentIdx = products_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing product"
              CALL edit_products()
              IF int_flag == FALSE THEN
                 CALL refresh_products(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete a product"
              CALL delete_products()
              IF int_flag == FALSE THEN
                 CALL refresh_products(currentIdx, "D")
                 IF currentIdx > products_arr.getLength() THEN
                    LET currentIdx = products_arr.getLength()
                 END IF
              END IF
              EXIT MENU
          COMMAND "Supplier" "View Supplier"
              CALL view_supplier(curr_products.supplierid)
          COMMAND "Category" "View Category"
              CALL view_category(curr_products.categoryid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_products

FUNCTION query_products()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_products()
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
       CALL clear_curr_products()
       CALL clear_products()
       RETURN
    END IF

    CALL load_products(where_clause)

    IF products_arr.getLength() == 0 THEN
        MESSAGE "No products found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_products(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE temp_product t_product

    LET sql_stmt = " SELECT productid, productname, supplierid,",
                   " categoryid, quantityperunit, unitprice,",
                   " unitsinstock, unitsonorder, reorderlevel, discontinued",
                   " FROM products",
                   " WHERE ", where_clause CLIPPED, " ORDER BY productname"

    CALL clear_products()

    PREPARE p_products FROM sql_stmt
    DECLARE c_products CURSOR FOR p_products
    FOREACH c_products INTO temp_product.*
        CALL products_arr.appendElement()
        LET products_arr[products_arr.getLength()] = temp_product
    END FOREACH
    CALL clear_curr_products()

END FUNCTION

FUNCTION clear_products()

   CALL products_arr.clear()

END FUNCTION #clear_products

FUNCTION add_products()
    DEFINE products_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_products()
    LET curr_products.discontinued = 0
    INPUT BY NAME curr_products.*
        ATTRIBUTE(UNBUFFERED)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_products("A")
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

    CALL insert_curr_products()
    MESSAGE "Product record added"

END FUNCTION

FUNCTION edit_products()
    DEFINE products_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_products.productname, curr_products.supplierid, curr_products.categoryid,
                  curr_products.quantityperunit, curr_products.unitprice, curr_products.unitsinstock,
                  curr_products.unitsonorder, curr_products.reorderlevel, curr_products.discontinued
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_products("C")
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

    CALL update_curr_products()
    MESSAGE "Product record updated"

END FUNCTION

FUNCTION delete_products()

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
        ERROR "Product delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_products()
    MESSAGE "Product record deleted"

END FUNCTION

FUNCTION load_curr_products(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_products()
   IF currIdx > 0 AND currIdx <= products_arr.getLength() THEN
      LET curr_products = products_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_products()

   DISPLAY BY NAME curr_products.*

END FUNCTION

FUNCTION clear_curr_products()

   INITIALIZE curr_products.* TO NULL

END FUNCTION

FUNCTION insert_curr_products()

   INSERT INTO products (productid, productname, supplierid, categoryid,
                         quantityperunit, unitprice, unitsinstock, unitsonorder,
                         reorderlevel, discontinued)
      VALUES (curr_products.productid, curr_products.productname, curr_products.supplierid,
              curr_products.categoryid, curr_products.quantityperunit, curr_products.unitprice,
              curr_products.unitsinstock, curr_products.unitsonorder, curr_products.reorderlevel,
              curr_products.discontinued)

END FUNCTION

FUNCTION update_curr_products()

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

END FUNCTION

FUNCTION delete_curr_products()

   DELETE FROM products
    WHERE productid = curr_products.productid

END FUNCTION

FUNCTION refresh_products(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
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

END FUNCTION #refresh_products

FUNCTION validate_products(mode)
   DEFINE mode CHAR(1)
   DEFINE productExists SMALLINT

   SELECT 1 INTO productExists FROM products WHERE products.productid = curr_products.productid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      RETURN FALSE, "Product ID is not found"
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      RETURN FALSE, "Product ID already exists"
   END IF
   IF curr_products.productid IS NULL THEN
      RETURN FALSE, "Product ID is required"
   END IF
   IF curr_products.productname IS NULL OR LENGTH(curr_products.productname) == 0 THEN
      RETURN FALSE, "Product Name is required"
   END IF
   IF curr_products.discontinued IS NULL THEN
      RETURN FALSE, "Discontinued flag is required"
   END IF

   RETURN TRUE, "Okay"
END FUNCTION

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

   OPEN WINDOW lookupWindow AT 5,5 WITH FORM "products"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   CALL populate_supplier_combo()
   CALL populate_category_combo()
   CALL product_lookup_menu()
      RETURNING prod_id, prod_name

   CLOSE WINDOW lookupWindow

   RETURN prod_id, prod_name

END FUNCTION #product_lookup

FUNCTION product_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL query_products()
   IF products_arr.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= products_arr.getLength() AND selectedIdx == 0

       CALL load_curr_products(currentIdx)
       CALL display_curr_products()
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
              CALL load_curr_products(selectedIdx)
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
