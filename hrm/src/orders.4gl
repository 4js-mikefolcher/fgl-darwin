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

-- =====================================================================
-- Function: view_order
-- Purpose : View a specific order record (called from other modules)
-- =====================================================================
FUNCTION view_order(order_id)
   DEFINE order_id LIKE orders.orderid
   DEFINE where_clause VARCHAR(500)

   IF order_id IS NULL OR order_id < 1 THEN
      ERROR "Order ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewOrderWindow WITH FORM "orders"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_shipvia_combo()
   LET arr_max = 1000
   LET where_clause = " orders.orderid = ", order_id
   CALL load_orders(where_clause)

   IF arr_size == 0 THEN
      CLOSE WINDOW viewOrderWindow
      ERROR "Order not found"
      RETURN
   END IF

   CALL load_curr_orders(1)
   CALL display_curr_orders()

   MENU "Order View"
      COMMAND "Customer" "View Customer"
         CALL view_customer(curr_orders.customerid)
      COMMAND "Employee" "View Employee"
         CALL view_employee(curr_orders.employeeid)
      COMMAND "Shipper" "View Shipper"
         CALL view_shipper(curr_orders.shipvia)
      COMMAND "Details" "View Order Details"
         CALL view_details_for_order(curr_orders.orderid)
      COMMAND "Exit" "Quit operation"
         EXIT MENU
   END MENU

   CLOSE WINDOW viewOrderWindow

END FUNCTION #view_order

-- =====================================================================
-- Function: view_orders_for_customer
-- Purpose : View orders for a specific customer (called from customers)
-- =====================================================================
FUNCTION view_orders_for_customer(cust_id)
   DEFINE cust_id LIKE customers.customerid
   DEFINE where_clause VARCHAR(500)

   IF cust_id IS NULL OR LENGTH(cust_id) == 0 THEN
      ERROR "Customer ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewOrdersWindow WITH FORM "orders"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_shipvia_combo()
   LET arr_max = 1000
   LET where_clause = " orders.customerid = '", cust_id CLIPPED, "'"
   CALL load_orders(where_clause)

   IF arr_size == 0 THEN
      CLOSE WINDOW viewOrdersWindow
      ERROR "No Orders found for this Customer"
      RETURN
   END IF

   CALL submenu_orders_view()

   CLOSE WINDOW viewOrdersWindow

END FUNCTION #view_orders_for_customer

-- =====================================================================
-- Function: view_orders_for_employee
-- Purpose : View orders for a specific employee (called from employees)
-- =====================================================================
FUNCTION view_orders_for_employee(empl_id)
   DEFINE empl_id LIKE employees.employeeid
   DEFINE where_clause VARCHAR(500)

   IF empl_id IS NULL OR empl_id < 1 THEN
      ERROR "Employee ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewOrdersWindow WITH FORM "orders"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_shipvia_combo()
   LET arr_max = 1000
   LET where_clause = " orders.employeeid = ", empl_id
   CALL load_orders(where_clause)

   IF arr_size == 0 THEN
      CLOSE WINDOW viewOrdersWindow
      ERROR "No Orders found for this Employee"
      RETURN
   END IF

   CALL submenu_orders_view()

   CLOSE WINDOW viewOrdersWindow

END FUNCTION #view_orders_for_employee

-- =====================================================================
-- Function: submenu_orders_view
-- Purpose : View-only submenu for orders (no add/modify/delete)
-- =====================================================================
FUNCTION submenu_orders_view()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_orders(currentIdx)
       CALL display_curr_orders()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Orders View"
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
          COMMAND "Details" "View Order Details"
              CALL view_details_for_order(curr_orders.orderid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_orders_view

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
          COMMAND "Customer" "View Customer"
              CALL view_customer(curr_orders.customerid)
          COMMAND "Employee" "View Employee"
              CALL view_employee(curr_orders.employeeid)
          COMMAND "Shipper" "View Shipper"
              CALL view_shipper(curr_orders.shipvia)
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
        ON ACTION accept
            ACCEPT CONSTRUCT
        ON ACTION cancel
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
                   " orders.shipvia, orders.freight, orders.shipname, orders.shipaddress,",
                   " orders.shipcity, orders.shipregion, orders.shippostalcode, orders.shipcountry",
                   " FROM orders",
                   " LEFT OUTER JOIN customers ON customers.customerid = orders.customerid",
                   " LEFT OUTER JOIN employees e ON e.employeeid = orders.employeeid",
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
    DEFINE selected_customer_id LIKE customers.customerid
    DEFINE selected_customer_name LIKE customers.companyname
    DEFINE selected_employee_id LIKE employees.employeeid
    DEFINE selected_employee_name VARCHAR(32)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_orders()
    INPUT BY NAME curr_orders.*
        ATTRIBUTE(UNBUFFERED)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        ON ACTION zoom_customer
            CALL customer_lookup()
               RETURNING selected_customer_id, selected_customer_name
            IF selected_customer_id IS NOT NULL AND LENGTH(selected_customer_id) > 0 THEN
               LET curr_orders.customerid = selected_customer_id
               LET curr_orders.customername = selected_customer_name
            END IF
        ON ACTION zoom_employee
            CALL employee_lookup()
               RETURNING selected_employee_id, selected_employee_name
            IF selected_employee_id > 0 THEN
               LET curr_orders.employeeid = selected_employee_id
               LET curr_orders.employeename = selected_employee_name
            END IF

        AFTER FIELD customerid
            CALL validate_customer_field()
               RETURNING orders_valid, valid_msg
            IF NOT orders_valid THEN
               ERROR valid_msg
               NEXT FIELD customerid
            END IF

        AFTER FIELD employeeid
            CALL validate_employee_field()
               RETURNING orders_valid, valid_msg
            IF NOT orders_valid THEN
               ERROR valid_msg
               NEXT FIELD employeeid
            END IF

        AFTER FIELD shipvia
            CALL validate_shipvia_field()
               RETURNING orders_valid, valid_msg
            IF NOT orders_valid THEN
               ERROR valid_msg
               NEXT FIELD shipvia
            END IF

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
    DEFINE selected_customer_id LIKE customers.customerid
    DEFINE selected_customer_name LIKE customers.companyname
    DEFINE selected_employee_id LIKE employees.employeeid
    DEFINE selected_employee_name VARCHAR(32)

    LET int_flag = FALSE
    INPUT BY NAME curr_orders.customerid, curr_orders.employeeid,
                  curr_orders.orderdate, curr_orders.requireddate, curr_orders.shippeddate,
                  curr_orders.shipvia, curr_orders.freight,
                  curr_orders.shipname, curr_orders.shipaddress, curr_orders.shipcity,
                  curr_orders.shipregion, curr_orders.shippostalcode, curr_orders.shipcountry
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        ON ACTION zoom_customer
            CALL customer_lookup()
               RETURNING selected_customer_id, selected_customer_name
            IF selected_customer_id IS NOT NULL AND LENGTH(selected_customer_id) > 0 THEN
               LET curr_orders.customerid = selected_customer_id
               LET curr_orders.customername = selected_customer_name
            END IF
        ON ACTION zoom_employee
            CALL employee_lookup()
               RETURNING selected_employee_id, selected_employee_name
            IF selected_employee_id > 0 THEN
               LET curr_orders.employeeid = selected_employee_id
               LET curr_orders.employeename = selected_employee_name
            END IF

        AFTER FIELD customerid
            CALL validate_customer_field()
               RETURNING orders_valid, valid_msg
            IF NOT orders_valid THEN
               ERROR valid_msg
               NEXT FIELD customerid
            END IF

        AFTER FIELD employeeid
            CALL validate_employee_field()
               RETURNING orders_valid, valid_msg
            IF NOT orders_valid THEN
               ERROR valid_msg
               NEXT FIELD employeeid
            END IF

        AFTER FIELD shipvia
            CALL validate_shipvia_field()
               RETURNING orders_valid, valid_msg
            IF NOT orders_valid THEN
               ERROR valid_msg
               NEXT FIELD shipvia
            END IF

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

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
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
      VALUES (DEFAULT, curr_orders.customerid, curr_orders.employeeid,
              curr_orders.orderdate, curr_orders.requireddate, curr_orders.shippeddate,
              curr_orders.shipvia, curr_orders.freight, curr_orders.shipname,
              curr_orders.shipaddress, curr_orders.shipcity, curr_orders.shipregion,
              curr_orders.shippostalcode, curr_orders.shipcountry)
   LET curr_orders.orderid = sqlca.sqlerrd[2]
   CALL display_curr_orders()

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
   DEFINE validateStatus SMALLINT
   DEFINE errorMessage CHAR(60)

   IF mode == "C" THEN
      SELECT 1 INTO ordersExists FROM orders WHERE orders.orderid = curr_orders.orderid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Order ID is not found"
      END IF
   END IF
   IF curr_orders.orderdate IS NULL THEN
      RETURN FALSE, "Order Date is required"
   END IF
   IF curr_orders.customerid IS NOT NULL AND LENGTH(curr_orders.customerid) > 0 THEN
      CALL validate_customer_field()
         RETURNING validateStatus, errorMessage
      IF NOT validateStatus THEN
         RETURN validateStatus, errorMessage
      END IF
   ELSE
      RETURN FALSE, "Customer ID is missing"
   END IF
   IF curr_orders.employeeid IS NOT NULL THEN
      CALL validate_employee_field()
         RETURNING validateStatus, errorMessage
      IF NOT validateStatus THEN
         RETURN validateStatus, errorMessage
      END IF
   ELSE
      RETURN FALSE, "Employee ID is missing"
   END IF
   RETURN TRUE, "Okay"
END FUNCTION

FUNCTION validate_employee_field()
   DEFINE employee_name CHAR(32)

   IF curr_orders.employeeid IS NOT NULL THEN
      SELECT firstname || " " || lastname INTO employee_name
         FROM employees WHERE employees.employeeid = curr_orders.employeeid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Employee ID does not exist in employees table"
      END IF
      LET curr_orders.employeename = employee_name
   END IF
   RETURN TRUE, "Okay"

END FUNCTION #validate_employee_field

FUNCTION validate_customer_field()
   DEFINE customer_name LIKE customers.companyname

   IF curr_orders.customerid IS NOT NULL AND LENGTH(curr_orders.customerid) > 0 THEN
      SELECT companyname INTO customer_name FROM customers WHERE customers.customerid = curr_orders.customerid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Customer ID does not exist in customers table"
      END IF
      LET curr_orders.customername = customer_name
   END IF
   RETURN TRUE, "Okay"

END FUNCTION #validate_customer_field

FUNCTION validate_shipvia_field()

   IF curr_orders.shipvia IS NOT NULL THEN
      SELECT shipperid FROM shippers WHERE shippers.shipperid = curr_orders.shipvia
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Shipper ID does not exist in shippers table"
      END IF
   END IF
   RETURN TRUE, "Okay"

END FUNCTION #validate_shipvia_field

-- =====================================================================
-- Function: populate_shipvia_combo
-- Purpose : Populate the shipvia combobox from the shippers table
-- =====================================================================
FUNCTION populate_shipvia_combo()
   DEFINE cb ui.ComboBox
   DEFINE ship_id LIKE shippers.shipperid
   DEFINE ship_name LIKE shippers.companyname

   LET cb = ui.ComboBox.forName("shipvia")
   IF cb IS NULL THEN
      RETURN
   END IF
   CALL cb.clear()
   DECLARE c_shipvia CURSOR FOR
      SELECT shipperid, companyname FROM shippers ORDER BY companyname
   FOREACH c_shipvia INTO ship_id, ship_name
      CALL cb.addItem(ship_id, ship_name)
   END FOREACH

END FUNCTION #populate_shipvia_combo

-- =====================================================================
-- Function: order_lookup
-- Purpose : Open a lookup window for order selection
-- =====================================================================
FUNCTION order_lookup()
   DEFINE ord_id LIKE orders.orderid

   OPEN WINDOW lookupWindow WITH FORM "orders"
      ATTRIBUTES(STYLE="modulewindow")

   CALL populate_shipvia_combo()
   CALL order_lookup_menu()
      RETURNING ord_id

   CLOSE WINDOW lookupWindow

   RETURN ord_id

END FUNCTION #order_lookup

FUNCTION order_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER
   DEFINE save_arr_max INTEGER

   LET save_arr_max = arr_max
   LET arr_max = 1000
   CALL query_orders()
   IF arr_size == 0 THEN
      LET arr_max = save_arr_max
      RETURN 0
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= arr_size AND selectedIdx == 0

       CALL load_curr_orders(currentIdx)
       CALL display_curr_orders()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
       MESSAGE statusMessage

       MENU "Order Selection"
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
          COMMAND "Select" "Select the current order"
              LET selectedIdx = currentIdx
              CALL load_curr_orders(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   LET arr_max = save_arr_max

   IF selectedIdx > 0 THEN
      RETURN curr_orders.orderid
   END IF

   RETURN 0

END FUNCTION #order_lookup_menu
