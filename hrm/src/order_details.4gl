DATABASE northwind

DEFINE order_details_arr ARRAY[10000] OF RECORD
   orderid LIKE order_details.orderid,
   productid LIKE order_details.productid,
   productname LIKE products.productname,
   unitprice LIKE order_details.unitprice,
   quantity LIKE order_details.quantity,
   discount LIKE order_details.discount
END RECORD

DEFINE curr_order_details RECORD
   orderid LIKE order_details.orderid,
   productid LIKE order_details.productid,
   productname LIKE products.productname,
   unitprice LIKE order_details.unitprice,
   quantity LIKE order_details.quantity,
   discount LIKE order_details.discount
END RECORD

DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

DEFINE skip_query SMALLINT
DEFINE default_order_id LIKE order_details.orderid

FUNCTION view_details_for_order(order_id)
   DEFINE order_id LIKE order_details.orderid
   DEFINE where_clause VARCHAR(500)

   OPEN WINDOW subWindow AT 5,5 WITH FORM "order_details"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   LET skip_query = TRUE
   LET default_order_id = order_id
   LET where_clause = " order_details.orderid = ", order_id
   LET arr_size = 0

   WHILE arr_size == 0

      CALL load_order_details(where_clause)
      IF arr_size == 0 THEN
         CALL add_order_details()
      END IF
      IF int_flag == TRUE THEN
         EXIT WHILE
      END IF

   END WHILE

    IF arr_size == 0 THEN
        RETURN
    END IF

    CALL submenu_order_details()

    CLOSE WINDOW subWindow

END FUNCTION #view_details_for_order

FUNCTION submenu_order_details()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET arr_max = 10000
   IF NOT skip_query THEN
      CALL query_order_details()
      IF arr_size == 0 THEN
         RETURN
      END IF
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_order_details(currentIdx)
       CALL display_curr_order_details()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Order Details Management"
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
          COMMAND "Add" "Add a new order detail"
              CALL add_order_details()
              IF int_flag == FALSE THEN
                 CALL refresh_order_details(currentIdx, "A")
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing order detail"
              CALL edit_order_details()
              IF int_flag == FALSE THEN
                 CALL refresh_order_details(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete an order detail"
              CALL delete_order_details()
              IF int_flag == FALSE THEN
                 CALL refresh_order_details(currentIdx, "D")
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

END FUNCTION #submenu_order_details

-- =====================================================================
-- Function: query_order_details
-- Purpose : Search and display order details using CONSTRUCT, store in array
-- =====================================================================
FUNCTION query_order_details()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_order_details()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON order_details.orderid, order_details.productid,
                              order_details.unitprice, order_details.quantity, order_details.discount
       FROM s_order_details.orderid, s_order_details.productid,
            s_order_details.unitprice, s_order_details.quantity, s_order_details.discount
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_order_details()
       CALL clear_order_details()
       RETURN
    END IF

    CALL load_order_details(where_clause)

    IF arr_size == 0 THEN
        MESSAGE "No order details found."
        RETURN
    END IF

END FUNCTION


-- =====================================================================
-- Function: load_order_details
-- Purpose : Load order details into dynamic array based on WHERE clause
-- =====================================================================
FUNCTION load_order_details(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE idx INTEGER

    LET sql_stmt = " SELECT order_details.orderid, order_details.productid, products.productname,",
                   " order_details.unitprice, order_details.quantity, order_details.discount",
                   " FROM order_details",
                   " LEFT OUTER JOIN products ON products.productid = order_details.productid",
                   " WHERE ", where_clause CLIPPED, " ORDER BY order_details.orderid, order_details.productid"

    CALL clear_order_details()

    LET idx = 0
    PREPARE p_order_details FROM sql_stmt
    DECLARE c_order_details CURSOR FOR p_order_details
    FOREACH c_order_details INTO curr_order_details.*
        LET idx = idx + 1
        LET order_details_arr[idx] = curr_order_details
    END FOREACH
    CALL clear_curr_order_details()
    LET arr_size = idx

END FUNCTION

FUNCTION clear_order_details()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE order_details_arr[idx].* TO NULL
   END FOR
   LET arr_size = 0

END FUNCTION #clear_order_details

-- =====================================================================
-- Function: add_order_details
-- Purpose : Add a new order detail record
-- =====================================================================
FUNCTION add_order_details()
    DEFINE order_details_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_order_details()
    INPUT BY NAME curr_order_details.*
        ATTRIBUTE(UNBUFFERED)
        BEFORE INPUT
           IF curr_order_details.orderid > 0 THEN
               NEXT FIELD productid
           END IF
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_order_details("A")
               RETURNING order_details_valid, valid_msg
            IF NOT order_details_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Order detail add canceled"
       RETURN
    END IF

    CALL insert_curr_order_details()
    MESSAGE "Order detail record added"

END FUNCTION


-- =====================================================================
-- Function: edit_order_details
-- Purpose : Edit an existing order detail record
-- =====================================================================
FUNCTION edit_order_details()
    DEFINE order_details_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_order_details.unitprice, curr_order_details.quantity, curr_order_details.discount
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_order_details("C")
               RETURNING order_details_valid, valid_msg
            IF NOT order_details_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Order detail update canceled"
       RETURN
    END IF

    CALL update_curr_order_details()
    MESSAGE "Order detail record updated"

END FUNCTION


-- =====================================================================
-- Function: delete_order_details
-- Purpose : Delete an existing order detail record
-- =====================================================================
FUNCTION delete_order_details()
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
        ERROR "Order detail delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_order_details()
    MESSAGE "Order detail record deleted"

END FUNCTION

FUNCTION load_curr_order_details(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_order_details()
   IF currIdx > 0 AND currIdx <= arr_size THEN
      LET curr_order_details = order_details_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_order_details()

   DISPLAY BY NAME curr_order_details.*

END FUNCTION

FUNCTION clear_curr_order_details()

   INITIALIZE curr_order_details.* TO NULL
   IF default_order_id IS NOT NULL AND default_order_id > 0 THEN
      LET curr_order_details.orderid = default_order_id
   END IF

END FUNCTION

FUNCTION insert_curr_order_details()

   INSERT INTO order_details (orderid, productid, unitprice, quantity, discount)
      VALUES (curr_order_details.orderid, curr_order_details.productid,
              curr_order_details.unitprice, curr_order_details.quantity, curr_order_details.discount)

END FUNCTION

FUNCTION update_curr_order_details()

   UPDATE order_details
      SET unitprice = curr_order_details.unitprice,
          quantity = curr_order_details.quantity,
          discount = curr_order_details.discount
    WHERE orderid = curr_order_details.orderid
      AND productid = curr_order_details.productid

END FUNCTION

FUNCTION delete_curr_order_details()

   DELETE FROM order_details
    WHERE orderid = curr_order_details.orderid
      AND productid = curr_order_details.productid

END FUNCTION

FUNCTION refresh_order_details(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET order_details_arr[newIdx] = curr_order_details
         LET arr_size = newIdx
      WHEN "C"
         LET order_details_arr[currIdx] = curr_order_details
      WHEN "D"
           LET newIdx = 0
           LET replaceRec = FALSE

           FOR idx = 1 TO arr_size
              IF order_details_arr[idx].orderid = curr_order_details.orderid
                 AND order_details_arr[idx].productid = curr_order_details.productid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF
              LET newIdx = newIdx + 1
              LET order_details_arr[newIdx] = order_details_arr[idx]
           END FOR

           IF replaceRec THEN
              INITIALIZE order_details_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF
   END CASE

END FUNCTION #refresh_order_details

FUNCTION validate_order_details(mode)
   DEFINE mode CHAR(1)
   DEFINE detailExists SMALLINT
   DEFINE product_name LIKE products.productname

   # Check composite key exists for change or doesn't exist for add
   SELECT 1 INTO detailExists FROM order_details
    WHERE order_details.orderid = curr_order_details.orderid
      AND order_details.productid = curr_order_details.productid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      RETURN FALSE, "Order detail record is not found"
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      RETURN FALSE, "Order detail record already exists for this order/product"
   END IF

   # Validate required fields
   IF curr_order_details.orderid IS NULL THEN
      RETURN FALSE, "Order ID is required"
   END IF
   IF curr_order_details.productid IS NULL THEN
      RETURN FALSE, "Product ID is required"
   END IF
   IF curr_order_details.unitprice IS NULL THEN
      RETURN FALSE, "Unit Price is required"
   END IF
   IF curr_order_details.quantity IS NULL THEN
      RETURN FALSE, "Quantity is required"
   END IF
   IF curr_order_details.discount IS NULL THEN
      RETURN FALSE, "Discount is required"
   END IF

   # Validate foreign keys
   IF mode == "A" THEN
      SELECT 1 INTO detailExists FROM orders WHERE orders.orderid = curr_order_details.orderid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Order ID does not exist in orders table"
      END IF
   END IF

   SELECT productname INTO product_name FROM products WHERE products.productid = curr_order_details.productid
   IF sqlca.sqlcode == NOTFOUND THEN
      RETURN FALSE, "Product ID does not exist in products table"
   END IF
   LET curr_order_details.productname = product_name

   # Validate data ranges
   IF curr_order_details.unitprice < 0 THEN
      RETURN FALSE, "Unit Price cannot be negative"
   END IF
   IF curr_order_details.quantity < 1 THEN
      RETURN FALSE, "Quantity must be at least 1"
   END IF
   IF curr_order_details.discount < 0 OR curr_order_details.discount > 1 THEN
      RETURN FALSE, "Discount must be between 0 and 1"
   END IF

   RETURN TRUE, "Okay"
END FUNCTION
