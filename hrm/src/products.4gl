DATABASE northwind

DEFINE products_arr ARRAY[1000] OF RECORD
   productid LIKE products.productid,
   productname LIKE products.productname,
   supplierid LIKE products.supplierid,
   suppliername LIKE suppliers.companyname,
   categoryid LIKE products.categoryid,
   categoryname LIKE categories.categoryname,
   quantityperunit LIKE products.quantityperunit,
   unitprice LIKE products.unitprice,
   unitsinstock LIKE products.unitsinstock,
   unitsonorder LIKE products.unitsonorder,
   reorderlevel LIKE products.reorderlevel,
   discontinued LIKE products.discontinued
END RECORD

DEFINE curr_products RECORD
   productid LIKE products.productid,
   productname LIKE products.productname,
   supplierid LIKE products.supplierid,
   suppliername LIKE suppliers.companyname,
   categoryid LIKE products.categoryid,
   categoryname LIKE categories.categoryname,
   quantityperunit LIKE products.quantityperunit,
   unitprice LIKE products.unitprice,
   unitsinstock LIKE products.unitsinstock,
   unitsonorder LIKE products.unitsonorder,
   reorderlevel LIKE products.reorderlevel,
   discontinued LIKE products.discontinued
END RECORD

DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

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

   LET arr_max = 1000
   LET where_clause = " products.productid = ", prod_id
   CALL load_products(where_clause)

   IF arr_size == 0 THEN
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

   LET arr_max = 1000
   LET where_clause = " p.supplierid = ", supp_id
   CALL load_products(where_clause)

   IF arr_size == 0 THEN
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

   LET arr_max = 1000
   LET where_clause = " p.categoryid = ", cat_id
   CALL load_products(where_clause)

   IF arr_size == 0 THEN
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
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_products(currentIdx)
       CALL display_curr_products()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
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
              IF currentIdx > arr_size THEN
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = arr_size
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

   LET arr_max = 1000
   CALL query_products()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_products(currentIdx)
       CALL display_curr_products()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
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
              IF currentIdx > arr_size THEN
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = arr_size
              EXIT MENU
          COMMAND "Add" "Add a new product"
              CALL add_products()
              IF int_flag == FALSE THEN
                 CALL refresh_products(currentIdx, "A")
                 LET currentIdx = arr_size
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
                 IF currentIdx > arr_size THEN
                    LET currentIdx = arr_size
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
    CONSTRUCT where_clause ON p.productid, p.productname, p.supplierid,
                              p.categoryid, p.quantityperunit, p.unitprice,
                              p.unitsinstock, p.unitsonorder, p.reorderlevel,
                              p.discontinued
       FROM s_products.productid, s_products.productname, s_products.supplierid,
            s_products.categoryid, s_products.quantityperunit, s_products.unitprice,
            s_products.unitsinstock, s_products.unitsonorder, s_products.reorderlevel,
            s_products.discontinued
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_products()
       CALL clear_products()
       RETURN
    END IF

    CALL load_products(where_clause)

    IF arr_size == 0 THEN
        MESSAGE "No products found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_products(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE idx INTEGER

    LET sql_stmt = " SELECT p.productid, p.productname, p.supplierid, s.companyname,",
                   " p.categoryid, c.categoryname, p.quantityperunit, p.unitprice,",
                   " p.unitsinstock, p.unitsonorder, p.reorderlevel, p.discontinued",
                   " FROM products p",
                   " LEFT OUTER JOIN suppliers s ON s.supplierid = p.supplierid",
                   " LEFT OUTER JOIN categories c ON c.categoryid = p.categoryid",
                   " WHERE ", where_clause CLIPPED, " ORDER BY p.productname"

    CALL clear_products()

    LET idx = 0
    PREPARE p_products FROM sql_stmt
    DECLARE c_products CURSOR FOR p_products
    FOREACH c_products INTO curr_products.*
        LET idx = idx + 1
        LET products_arr[idx] = curr_products
    END FOREACH
    CALL clear_curr_products()
    LET arr_size = idx

END FUNCTION

FUNCTION clear_products()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE products_arr[idx].* TO NULL
   END FOR
   LET arr_size = 0

END FUNCTION #clear_products

FUNCTION add_products()
    DEFINE products_valid SMALLINT
    DEFINE valid_msg CHAR(75)
    DEFINE selected_supplier_id LIKE suppliers.supplierid
    DEFINE selected_supplier_name LIKE suppliers.companyname
    DEFINE selected_category_id LIKE categories.categoryid
    DEFINE selected_category_name LIKE categories.categoryname

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_products()
    INPUT BY NAME curr_products.*
        ATTRIBUTE(UNBUFFERED)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        ON KEY (CONTROL-T)
            IF INFIELD(supplierid) THEN
               CALL supplier_lookup()
                  RETURNING selected_supplier_id, selected_supplier_name
               IF selected_supplier_id > 0 THEN
                  LET curr_products.supplierid = selected_supplier_id
                  LET curr_products.suppliername = selected_supplier_name
               END IF
            END IF
            IF INFIELD(categoryid) THEN
               CALL category_lookup()
                  RETURNING selected_category_id, selected_category_name
               IF selected_category_id > 0 THEN
                  LET curr_products.categoryid = selected_category_id
                  LET curr_products.categoryname = selected_category_name
               END IF
            END IF

        BEFORE FIELD supplierid
            MESSAGE "Use Ctrl-T to open lookup window"
        BEFORE FIELD categoryid
            MESSAGE "Use Ctrl-T to open lookup window"

        AFTER FIELD supplierid
            CALL validate_supplier_field()
               RETURNING products_valid, valid_msg
            IF NOT products_valid THEN
               ERROR valid_msg
               NEXT FIELD supplierid
            END IF

        AFTER FIELD categoryid
            CALL validate_category_field()
               RETURNING products_valid, valid_msg
            IF NOT products_valid THEN
               ERROR valid_msg
               NEXT FIELD categoryid
            END IF

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
    DEFINE selected_supplier_id LIKE suppliers.supplierid
    DEFINE selected_supplier_name LIKE suppliers.companyname
    DEFINE selected_category_id LIKE categories.categoryid
    DEFINE selected_category_name LIKE categories.categoryname

    LET int_flag = FALSE
    INPUT BY NAME curr_products.productname, curr_products.supplierid, curr_products.categoryid,
                  curr_products.quantityperunit, curr_products.unitprice, curr_products.unitsinstock,
                  curr_products.unitsonorder, curr_products.reorderlevel, curr_products.discontinued
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        ON KEY (CONTROL-T)
            IF INFIELD(supplierid) THEN
               CALL supplier_lookup()
                  RETURNING selected_supplier_id, selected_supplier_name
               IF selected_supplier_id > 0 THEN
                  LET curr_products.supplierid = selected_supplier_id
                  LET curr_products.suppliername = selected_supplier_name
               END IF
            END IF
            IF INFIELD(categoryid) THEN
               CALL category_lookup()
                  RETURNING selected_category_id, selected_category_name
               IF selected_category_id > 0 THEN
                  LET curr_products.categoryid = selected_category_id
                  LET curr_products.categoryname = selected_category_name
               END IF
            END IF

        BEFORE FIELD supplierid
            MESSAGE "Use Ctrl-T to open lookup window"
        BEFORE FIELD categoryid
            MESSAGE "Use Ctrl-T to open lookup window"

        AFTER FIELD supplierid
            CALL validate_supplier_field()
               RETURNING products_valid, valid_msg
            IF NOT products_valid THEN
               ERROR valid_msg
               NEXT FIELD supplierid
            END IF

        AFTER FIELD categoryid
            CALL validate_category_field()
               RETURNING products_valid, valid_msg
            IF NOT products_valid THEN
               ERROR valid_msg
               NEXT FIELD categoryid
            END IF

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
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
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
   IF currIdx > 0 AND currIdx <= arr_size THEN
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
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET products_arr[newIdx] = curr_products
         LET arr_size = newIdx
      WHEN "C"
         LET products_arr[currIdx] = curr_products
      WHEN "D"
           LET newIdx = 0
           LET replaceRec = FALSE

           FOR idx = 1 TO arr_size
              IF products_arr[idx].productid = curr_products.productid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF
              LET newIdx = newIdx + 1
              LET products_arr[newIdx] = products_arr[idx]
           END FOR

           IF replaceRec THEN
              INITIALIZE products_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF
   END CASE

END FUNCTION #refresh_products

FUNCTION validate_products(mode)
   DEFINE mode CHAR(1)
   DEFINE productExists SMALLINT
   DEFINE supplier_name LIKE suppliers.companyname
   DEFINE category_name LIKE categories.categoryname

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

   # Validate supplier foreign key
   IF curr_products.supplierid IS NOT NULL THEN
      SELECT companyname INTO supplier_name FROM suppliers WHERE suppliers.supplierid = curr_products.supplierid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Supplier ID does not exist in suppliers table"
      END IF
      LET curr_products.suppliername = supplier_name
   ELSE
      LET curr_products.suppliername = NULL
   END IF

   # Validate category foreign key
   IF curr_products.categoryid IS NOT NULL THEN
      SELECT categoryname INTO category_name FROM categories WHERE categories.categoryid = curr_products.categoryid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Category ID does not exist in categories table"
      END IF
      LET curr_products.categoryname = category_name
   ELSE
      LET curr_products.categoryname = NULL
   END IF

   RETURN TRUE, "Okay"
END FUNCTION

FUNCTION validate_supplier_field()
   DEFINE supplier_name LIKE suppliers.companyname

   IF curr_products.supplierid IS NOT NULL THEN
      SELECT companyname INTO supplier_name FROM suppliers WHERE suppliers.supplierid = curr_products.supplierid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Supplier ID does not exist in suppliers table"
      END IF
      LET curr_products.suppliername = supplier_name
   ELSE
      LET curr_products.suppliername = NULL
   END IF
   RETURN TRUE, "Okay"

END FUNCTION #validate_supplier_field

FUNCTION validate_category_field()
   DEFINE category_name LIKE categories.categoryname

   IF curr_products.categoryid IS NOT NULL THEN
      SELECT categoryname INTO category_name FROM categories WHERE categories.categoryid = curr_products.categoryid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Category ID does not exist in categories table"
      END IF
      LET curr_products.categoryname = category_name
   ELSE
      LET curr_products.categoryname = NULL
   END IF
   RETURN TRUE, "Okay"

END FUNCTION #validate_category_field

-- =====================================================================
-- Function: product_lookup
-- Purpose : Open a lookup window for product selection
-- =====================================================================
FUNCTION product_lookup()
   DEFINE prod_id LIKE products.productid
   DEFINE prod_name LIKE products.productname

   OPEN WINDOW lookupWindow AT 5,5 WITH FORM "products"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   CALL product_lookup_menu()
      RETURNING prod_id, prod_name

   CLOSE WINDOW lookupWindow

   RETURN prod_id, prod_name

END FUNCTION #product_lookup

FUNCTION product_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER
   DEFINE save_arr_max INTEGER

   LET save_arr_max = arr_max
   LET arr_max = 1000
   CALL query_products()
   IF arr_size == 0 THEN
      LET arr_max = save_arr_max
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= arr_size AND selectedIdx == 0

       CALL load_curr_products(currentIdx)
       CALL display_curr_products()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
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
              IF currentIdx > arr_size THEN
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = arr_size
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

   LET arr_max = save_arr_max

   IF selectedIdx > 0 THEN
      RETURN curr_products.productid, curr_products.productname
   END IF

   RETURN 0, ""

END FUNCTION #product_lookup_menu
