IMPORT util
IMPORT FGL main_lib
IMPORT FGL dialog_prompt
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_orders
IMPORT FGL model_shippers
IMPORT FGL ui_customers
IMPORT FGL ui_employees
IMPORT FGL ui_order_details
IMPORT FGL model_helper
DATABASE northwind

TYPE t_order_list RECORD
   orderid LIKE orders.orderid,
   customername LIKE customers.companyname,
   employeename VARCHAR(30),
   orderdate LIKE orders.orderdate,
   shipvia LIKE orders.shipvia,
   freight LIKE orders.freight
END RECORD

DEFINE orders_arr DYNAMIC ARRAY OF t_order
DEFINE curr_orders t_order

-- =====================================================================
-- Function: get_config (PRIVATE)
-- Purpose : Return controller configuration for orders module
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS (t_controller_config)
   DEFINE cfg t_controller_config

   LET cfg.moduleName = "orders"
   LET cfg.formName = "orders"
   LET cfg.listFormName = "orders_list"
   LET cfg.windowTitle = "Orders Management"
   LET cfg.hasModify = TRUE
   LET cfg.hasQuery = TRUE
   LET cfg.hasLookup = TRUE
   LET cfg.entityName = "Order"
   -- View commands available for this module
   LET cfg.availableCommands = init_view_commands()

   RETURN cfg

END FUNCTION #get_config

-- =====================================================================
-- Function: init_view_commands (PRIVATE)
-- Purpose : Define which view commands are available for orders
-- =====================================================================
PRIVATE FUNCTION init_view_commands() RETURNS DYNAMIC ARRAY OF t_view_command
   DEFINE cmds DYNAMIC ARRAY OF t_view_command
   LET cmds[1].commandName  = "details"
   LET cmds[1].commandLabel = "Details"
   LET cmds[1].commandComment = "View Order Details"
   RETURN cmds
END FUNCTION #init_view_commands

-- =====================================================================
-- Function: submenu_orders
-- Purpose : Main entry point for orders management
-- =====================================================================
FUNCTION submenu_orders()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_orders

-- =====================================================================
-- Function: root_add_orders
-- Purpose : Entry point for orders add from root menu
-- =====================================================================
FUNCTION root_add_orders()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_orders

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

   CALL model_shippers.load_shipvia_combo(ui.ComboBox.forName("shipvia"))
   LET where_clause = " orders.customerid = '", cust_id CLIPPED, "'"
   CALL orders_do_load(where_clause)

   IF orders_arr.getLength() == 0 THEN
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

   CALL model_shippers.load_shipvia_combo(ui.ComboBox.forName("shipvia"))
   LET where_clause = " orders.employeeid = ", empl_id
   CALL orders_do_load(where_clause)

   IF orders_arr.getLength() == 0 THEN
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
--           Now delegates to the generic controller_navigate_view()
-- =====================================================================
FUNCTION submenu_orders_view()

   CALL controller_init(get_config())
   CALL controller_navigate_view()

END FUNCTION #submenu_orders_view

-- =====================================================================
-- Dispatch interface: orders_get_count
-- =====================================================================
FUNCTION orders_get_count()

   RETURN orders_arr.getLength()

END FUNCTION #orders_get_count

-- =====================================================================
-- Dispatch interface: orders_load_at
-- =====================================================================
FUNCTION orders_load_at(idx)
   DEFINE idx INTEGER

   INITIALIZE curr_orders.* TO NULL
   IF idx >= 1 AND idx <= orders_arr.getLength() THEN
      LET curr_orders = orders_arr[idx]
   END IF

END FUNCTION #orders_load_at

-- =====================================================================
-- Dispatch interface: orders_display_curr
-- =====================================================================
FUNCTION orders_display_curr()

   DISPLAY BY NAME curr_orders.*

END FUNCTION #orders_display_curr

-- =====================================================================
-- Dispatch interface: orders_clear_curr
-- =====================================================================
FUNCTION orders_clear_curr()

   INITIALIZE curr_orders.* TO NULL

END FUNCTION #orders_clear_curr

-- =====================================================================
-- Dispatch interface: orders_do_query
-- =====================================================================
FUNCTION orders_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL orders_clear_curr()
   CALL model_shippers.load_shipvia_combo(ui.ComboBox.forName("shipvia"))
   LET int_flag = FALSE
   CONSTRUCT where_clause ON orders.orderid, orders.customerid, orders.employeeid,
                             orders.orderdate, orders.requireddate, orders.shippeddate,
                             orders.shipvia, orders.freight,
                             orders.shipname, orders.shipaddress, orders.shipcity,
                             orders.shipregion, orders.shippostalcode, orders.shipcountry
      FROM s_orders.orderid, s_orders.customerid, s_orders.employeeid,
                             s_orders.orderdate, s_orders.requireddate, s_orders.shippeddate,
                             s_orders.shipvia, s_orders.freight,
                             s_orders.shipname, s_orders.shipaddress, s_orders.shipcity,
                             s_orders.shipregion, s_orders.shippostalcode, s_orders.shipcountry
      ON ACTION accept
         ACCEPT CONSTRUCT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL orders_clear_curr()
      CALL orders_arr.clear()
      RETURN
   END IF

   CALL orders_do_load(where_clause)

   IF orders_arr.getLength() == 0 THEN
      MESSAGE "No orders found."
      RETURN
   END IF

END FUNCTION #orders_do_query

-- =====================================================================
-- Function: orders_do_load (PRIVATE)
-- Purpose : Load orders into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION orders_do_load(where_clause)
   DEFINE where_clause VARCHAR(500)
   DEFINE sql_stmt VARCHAR(1024)

   LET sql_stmt = " SELECT orders.orderid, orders.customerid, customers.companyname,",
                  " orders.employeeid, RTRIM(e.firstname) || ' ' || RTRIM(e.lastname) as employeename, ",
                  " orders.orderdate, orders.requireddate, orders.shippeddate,",
                  " orders.shipvia, orders.freight, orders.shipname, orders.shipaddress,",
                  " orders.shipcity, orders.shipregion, orders.shippostalcode, orders.shipcountry",
                  " FROM orders",
                  " LEFT OUTER JOIN customers ON customers.customerid = orders.customerid",
                  " LEFT OUTER JOIN employees e ON e.employeeid = orders.employeeid",
                  " WHERE ", where_clause CLIPPED, " ORDER BY orders.orderid"

   CALL orders_arr.clear()

   PREPARE p_orders FROM sql_stmt
   DECLARE c_orders CURSOR FOR p_orders
   FOREACH c_orders INTO curr_orders.*
      CALL orders_arr.appendElement()
      LET orders_arr[orders_arr.getLength()] = curr_orders
   END FOREACH
   CALL orders_clear_curr()

END FUNCTION #orders_do_load

-- =====================================================================
-- Dispatch interface: orders_do_add_edit
-- =====================================================================
FUNCTION orders_do_add_edit(mode CHAR(1))
   DEFINE orders_valid SMALLINT
   DEFINE valid_msg CHAR(75)
   DEFINE selected_customer_id LIKE customers.customerid
   DEFINE selected_customer_name LIKE customers.companyname
   DEFINE selected_employee_id LIKE employees.employeeid
   DEFINE selected_employee_name VARCHAR(32)

   CLEAR FORM
   LET int_flag = FALSE
   IF mode == "A" THEN
      CALL orders_clear_curr()
   END IF
   CALL model_shippers.load_shipvia_combo(ui.ComboBox.forName("shipvia"))

   INPUT BY NAME curr_orders.*
      ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS=TRUE)
      BEFORE INPUT
         CALL DIALOG.setFieldActive("orderid", FALSE)
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
            CALL curr_orders.default_shipping_from_customer()
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
         ELSE
            CALL curr_orders.default_shipping_from_customer()
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
         VAR valid_status = curr_orders.validateRec(mode)
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      IF mode = "A" THEN
         ERROR "Order add canceled"
      ELSE
         ERROR "Order update canceled"
      END IF
      RETURN
   END IF

   VAR rec_status t_valid_rec
   IF mode = "A" THEN
      LET rec_status = curr_orders.insertRec()
   ELSE
      LET rec_status = curr_orders.updateRec()
   END IF

   IF rec_status.valid_status THEN
      CALL orders_display_curr()
      MESSAGE rec_status.valid_msg
   ELSE
      ERROR rec_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #orders_do_add_edit

-- =====================================================================
-- Dispatch interface: orders_do_delete
-- =====================================================================
FUNCTION orders_do_delete()

   LET int_flag = FALSE
   IF NOT dialog_prompt.delete_prompt() THEN
      ERROR "Order delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_orders.deleteRec()
   IF del_status.valid_status THEN
      MESSAGE del_status.valid_msg
   ELSE
      ERROR del_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #orders_do_delete

-- =====================================================================
-- Dispatch interface: orders_do_refresh
-- =====================================================================
FUNCTION orders_do_refresh(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL orders_arr.appendElement()
         LET orders_arr[orders_arr.getLength()] = curr_orders
      WHEN "C"
         LET orders_arr[currIdx] = curr_orders
      WHEN "D"
         FOR idx = 1 TO orders_arr.getLength()
            IF orders_arr[idx].orderid = curr_orders.orderid THEN
               CALL orders_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #orders_do_refresh

-- =====================================================================
-- Dispatch interface: orders_list_display
-- =====================================================================
FUNCTION orders_list_display()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER
   DEFINE list_arr DYNAMIC ARRAY OF t_order_list
   DEFINE idx INTEGER

   FOR idx = 1 TO orders_arr.getLength()
      CALL list_arr.appendElement()
      LET list_arr[idx].orderid = orders_arr[idx].orderid
      LET list_arr[idx].customername = orders_arr[idx].customername
      LET list_arr[idx].employeename = orders_arr[idx].employeename
      LET list_arr[idx].orderdate = orders_arr[idx].orderdate
      LET list_arr[idx].shipvia = orders_arr[idx].shipvia
      LET list_arr[idx].freight = orders_arr[idx].freight
   END FOR

   MESSAGE "Displayed ", list_arr.getLength() USING "<<<<<", " orders"

   DISPLAY ARRAY list_arr TO orders_list.*
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
      ON ACTION excel_export
         CALL list_view_helper.export_array_to_excel("orders_list", util.JSONArray.fromFGL(list_arr))
   END DISPLAY

   RETURN selectedIdx, selectedOption

END FUNCTION #orders_list_display

-- =====================================================================
-- Function: orders_do_command
-- Purpose : Execute a view command for orders
-- =====================================================================
FUNCTION orders_do_command(commandName STRING)
   CASE commandName
      WHEN "details"
         CALL view_details_for_order(curr_orders.orderid)
      OTHERWISE
         ERROR "Unknown command: ", commandName
   END CASE

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #orders_do_command

-- =====================================================================
-- Function: order_lookup
-- Purpose : Open a lookup window for order selection
-- =====================================================================
FUNCTION order_lookup()
   DEFINE ord_id LIKE orders.orderid

   OPEN WINDOW lookupWindow WITH FORM "orders"
      ATTRIBUTES(STYLE="modulewindow")

   CALL model_shippers.load_shipvia_combo(ui.ComboBox.forName("shipvia"))
   CALL order_lookup_menu()
      RETURNING ord_id

   CLOSE WINDOW lookupWindow

   RETURN ord_id

END FUNCTION #order_lookup

-- =====================================================================
-- Function: order_lookup_menu
-- Purpose : Navigate orders for selection
-- =====================================================================
FUNCTION order_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL orders_do_query()
   IF orders_arr.getLength() == 0 THEN
      RETURN 0
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= orders_arr.getLength() AND selectedIdx == 0

      CALL orders_load_at(currentIdx)
      CALL orders_display_curr()
      LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", orders_arr.getLength() USING "<<<<"
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
            IF currentIdx > orders_arr.getLength() THEN
               LET currentIdx = orders_arr.getLength()
            END IF
            EXIT MENU
         COMMAND "Last" "View last record in result set"
            LET currentIdx = orders_arr.getLength()
            EXIT MENU
         COMMAND "Select" "Select the current order"
            LET selectedIdx = currentIdx
            CALL orders_load_at(selectedIdx)
            EXIT MENU
         COMMAND "Exit" "Quit operation"
            LET currentIdx = 0
            EXIT MENU
      END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_orders.orderid
   END IF

   RETURN 0

END FUNCTION #order_lookup_menu



-- =====================================================================
-- Function: validate_employee_field (PRIVATE)
-- =====================================================================
PRIVATE FUNCTION validate_employee_field()
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

-- =====================================================================
-- Function: validate_customer_field (PRIVATE)
-- =====================================================================
PRIVATE FUNCTION validate_customer_field()
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

-- =====================================================================
-- Function: validate_shipvia_field (PRIVATE)
-- =====================================================================
PRIVATE FUNCTION validate_shipvia_field()

   IF curr_orders.shipvia IS NOT NULL THEN
      SELECT shipperid FROM shippers WHERE shippers.shipperid = curr_orders.shipvia
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Shipper ID does not exist in shippers table"
      END IF
   END IF
   RETURN TRUE, "Okay"

END FUNCTION #validate_shipvia_field

