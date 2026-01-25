DATABASE northwind

DEFINE orders_arr ARRAY[1000] OF RECORD
   orderid LIKE orders.orderid,
   customerid LIKE orders.customerid,
   customername LIKE customers.companyname,
   employeeid LIKE orders.employeeid,
   employeename VARCHAR(30),
   orderdate LIKE orders.orderdate,
   requireddate LIKE orders.requireddate,
   shippeddate LIKE orders.shippeddate,
   shipvia LIKE orders.shipvia,
   companyname LIKE shippers.companyname,
   freight LIKE orders.freight,
   shipname LIKE orders.shipname,
   shipaddress LIKE orders.shipaddress,
   shipcity LIKE orders.shipcity,
   shipregion LIKE orders.shipregion,
   shippostalcode LIKE orders.shippostalcode,
   shipcountry LIKE orders.shipcountry
END RECORD

DEFINE curr_orders RECORD
   orderid LIKE orders.orderid,
   customerid LIKE orders.customerid,
   customername LIKE customers.companyname,
   employeeid LIKE orders.employeeid,
   employeename VARCHAR(30),
   orderdate LIKE orders.orderdate,
   requireddate LIKE orders.requireddate,
   shippeddate LIKE orders.shippeddate,
   shipvia LIKE orders.shipvia,
   companyname LIKE shippers.companyname,
   freight LIKE orders.freight,
   shipname LIKE orders.shipname,
   shipaddress LIKE orders.shipaddress,
   shipcity LIKE orders.shipcity,
   shipregion LIKE orders.shipregion,
   shippostalcode LIKE orders.shippostalcode,
   shipcountry LIKE orders.shipcountry
END RECORD

DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

FUNCTION submenu_orders()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET arr_max = 1000
   CALL query_orders()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_orders(currentIdx)
       CALL display_curr_orders()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Orders Management"
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
          COMMAND "Add" "Add a new order"
              CALL add_orders()
              IF int_flag == FALSE THEN
                 CALL refresh_orders(currentIdx, "A")
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing order"
              CALL edit_orders()
              IF int_flag == FALSE THEN
                 CALL refresh_orders(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete an order"
              CALL delete_orders()
              IF int_flag == FALSE THEN
                 CALL refresh_orders(currentIdx, "D")
                 IF currentIdx > arr_size THEN
                    LET currentIdx = arr_size
                 END IF
              END IF
              EXIT MENU
          COMMAND "Employee" "View Employee"
              CALL view_employee(curr_orders.employeeid)
          COMMAND "Details" "View Order Details"
              CALL view_details_for_order(curr_orders.orderid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_orders

-- =====================================================================
-- Function: query_orders
-- Purpose : Search and display orders using CONSTRUCT, store in array
-- =====================================================================
FUNCTION query_orders()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_orders()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON orders.orderid, orders.customerid, orders.employeeid,
                              orders.orderdate, orders.requireddate, orders.shippeddate,
                              orders.shipvia, orders.freight,
                              orders.shipname, orders.shipaddress, orders.shipcity,
                              orders.shipregion, orders.shippostalcode, orders.shipcountry
       FROM s_orders.orderid, s_orders.customerid, s_orders.employeeid,
                              s_orders.orderdate, s_orders.requireddate, s_orders.shippeddate,
                              s_orders.shipvia, s_orders.freight,
                              s_orders.shipname,s_orders.shipaddress, s_orders.shipcity,
                              s_orders.shipregion, s_orders.shippostalcode, s_orders.shipcountry
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_orders()
       CALL clear_orders()
       RETURN
    END IF

    CALL load_orders(where_clause)

    IF arr_size == 0 THEN
        MESSAGE "No orders found."
        RETURN
    END IF

END FUNCTION


-- =====================================================================
-- Function: load_orders
-- Purpose : Load orders into dynamic array based on WHERE clause
-- =====================================================================
FUNCTION load_orders(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE idx INTEGER

    LET sql_stmt = " SELECT orders.orderid, orders.customerid, customers.companyname,",
                   " orders.employeeid, RTRIM(e.firstname) || ' ' || RTRIM(e.lastname) as employeename, ",
                   " orders.orderdate, orders.requireddate, orders.shippeddate,",
                   " orders.shipvia, s.companyname, orders.freight, orders.shipname, orders.shipaddress,",
                   " orders.shipcity, orders.shipregion, orders.shippostalcode, orders.shipcountry",
                   " FROM orders",
                   " LEFT OUTER JOIN customers ON customers.customerid = orders.customerid",
                   " LEFT OUTER JOIN employees e ON e.employeeid = orders.employeeid",
                   " LEFT OUTER JOIN shippers s ON s.shipperid = orders.shipvia",
                   " WHERE ", where_clause CLIPPED, " ORDER BY orders.orderid"

    CALL clear_orders()

    LET idx = 0
    PREPARE p_orders FROM sql_stmt
    DECLARE c_orders CURSOR FOR p_orders
    FOREACH c_orders INTO curr_orders.*
        LET idx = idx + 1
        LET orders_arr[idx] = curr_orders
    END FOREACH
    CALL clear_curr_orders()
    LET arr_size = idx

END FUNCTION

FUNCTION clear_orders()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE orders_arr[idx].* TO NULL
   END FOR
   LET arr_size = 0

END FUNCTION #clear_orders

-- =====================================================================
-- Function: add_orders
-- Purpose : Add a new order record
-- =====================================================================
FUNCTION add_orders()
    DEFINE orders_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_orders()
    INPUT BY NAME curr_orders.*
        ATTRIBUTE(UNBUFFERED)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_orders("A")
               RETURNING orders_valid, valid_msg
            IF NOT orders_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Order add canceled"
       RETURN
    END IF

    CALL insert_curr_orders()
    MESSAGE "Order record added"

END FUNCTION


-- =====================================================================
-- Function: edit_orders
-- Purpose : Edit an existing order record
-- =====================================================================
FUNCTION edit_orders()
    DEFINE orders_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_orders.customerid, curr_orders.employeeid,
                  curr_orders.orderdate, curr_orders.requireddate, curr_orders.shippeddate,
                  curr_orders.shipvia, curr_orders.freight,
                  curr_orders.shipname, curr_orders.shipaddress, curr_orders.shipcity,
                  curr_orders.shipregion, curr_orders.shippostalcode, curr_orders.shipcountry
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_orders("C")
               RETURNING orders_valid, valid_msg
            IF NOT orders_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Order update canceled"
       RETURN
    END IF

    CALL update_curr_orders()
    MESSAGE "Order record updated"

END FUNCTION


-- =====================================================================
-- Function: delete_orders
-- Purpose : Delete an existing order record
-- =====================================================================
FUNCTION delete_orders()
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
        ERROR "Order delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_orders()
    MESSAGE "Order record deleted"

END FUNCTION

FUNCTION load_curr_orders(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_orders()
   IF currIdx > 0 AND currIdx <= arr_size THEN
      LET curr_orders = orders_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_orders()

   DISPLAY BY NAME curr_orders.*

END FUNCTION

FUNCTION clear_curr_orders()

   INITIALIZE curr_orders.* TO NULL

END FUNCTION

FUNCTION insert_curr_orders()

   INSERT INTO orders (orderid, customerid, employeeid, orderdate, requireddate, shippeddate,
                       shipvia, freight, shipname, shipaddress, shipcity, shipregion,
                       shippostalcode, shipcountry)
      VALUES (curr_orders.orderid, curr_orders.customerid, curr_orders.employeeid,
              curr_orders.orderdate, curr_orders.requireddate, curr_orders.shippeddate,
              curr_orders.shipvia, curr_orders.freight, curr_orders.shipname,
              curr_orders.shipaddress, curr_orders.shipcity, curr_orders.shipregion,
              curr_orders.shippostalcode, curr_orders.shipcountry)

END FUNCTION

FUNCTION update_curr_orders()

   UPDATE orders
      SET customerid = curr_orders.customerid,
          employeeid = curr_orders.employeeid,
          orderdate = curr_orders.orderdate,
          requireddate = curr_orders.requireddate,
          shippeddate = curr_orders.shippeddate,
          shipvia = curr_orders.shipvia,
          freight = curr_orders.freight,
          shipname = curr_orders.shipname,
          shipaddress = curr_orders.shipaddress,
          shipcity = curr_orders.shipcity,
          shipregion = curr_orders.shipregion,
          shippostalcode = curr_orders.shippostalcode,
          shipcountry = curr_orders.shipcountry
    WHERE orderid = curr_orders.orderid

END FUNCTION

FUNCTION delete_curr_orders()

   DELETE FROM orders
    WHERE orderid = curr_orders.orderid

END FUNCTION

FUNCTION refresh_orders(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET orders_arr[newIdx] = curr_orders
         LET arr_size = newIdx
      WHEN "C"
         LET orders_arr[currIdx] = curr_orders
      WHEN "D"
           LET newIdx = 0
           LET replaceRec = FALSE

           FOR idx = 1 TO arr_size
              IF orders_arr[idx].orderid = curr_orders.orderid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF
              LET newIdx = newIdx + 1
              LET orders_arr[newIdx] = orders_arr[idx]
           END FOR

           IF replaceRec THEN
              INITIALIZE orders_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF
   END CASE

END FUNCTION #refresh_orders

FUNCTION validate_orders(mode)
   DEFINE mode CHAR(1)
   DEFINE ordersExists SMALLINT
   DEFINE customer_name LIKE customers.companyname

   SELECT 1 INTO ordersExists FROM orders WHERE orders.orderid = curr_orders.orderid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      RETURN FALSE, "Order ID is not found"
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      RETURN FALSE, "Order ID already exists"
   END IF
   IF curr_orders.orderid IS NULL THEN
      RETURN FALSE, "Order ID is required"
   END IF
   IF curr_orders.orderdate IS NULL THEN
      RETURN FALSE, "Order Date is required"
   END IF
   IF curr_orders.customerid IS NOT NULL AND LENGTH(curr_orders.customerid) > 0 THEN
      SELECT companyname INTO customer_name FROM customers WHERE customers.customerid = curr_orders.customerid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Customer ID does not exist in customers table"
      END IF
      LET curr_orders.customername = customer_name
   END IF
   IF curr_orders.employeeid IS NOT NULL THEN
      SELECT 1 INTO ordersExists FROM employees WHERE employees.employeeid = curr_orders.employeeid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Employee ID does not exist in employees table"
      END IF
   END IF
   RETURN TRUE, "Okay"
END FUNCTION
