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
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
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
