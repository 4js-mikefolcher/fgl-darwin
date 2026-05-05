IMPORT FGL main_lib
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_customers
IMPORT FGL ui_orders
IMPORT FGL ui_cust_cust_demo
IMPORT FGL model_helper

DATABASE northwind

-- =====================================================================
-- Record Type Definitions
-- =====================================================================
TYPE t_customer_list RECORD
   customerid LIKE customers.customerid,
   companyname LIKE customers.companyname,
   contactname LIKE customers.contactname,
   contacttitle LIKE customers.contacttitle,
   phone LIKE customers.phone
END RECORD

-- =====================================================================
-- Global Variables
-- =====================================================================
DEFINE customers_arr DYNAMIC ARRAY OF t_customer
DEFINE curr_customers t_customer

-- =====================================================================
-- Function: get_config (PRIVATE)
-- Purpose : Return controller configuration for customers module
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS (t_controller_config)
   DEFINE cfg t_controller_config

   LET cfg.moduleName = "customers"
   LET cfg.formName = "customers"
   LET cfg.listFormName = "customers_list"
   LET cfg.windowTitle = "Customers Management"
   LET cfg.hasModify = TRUE
   LET cfg.hasQuery = TRUE
   LET cfg.hasLookup = TRUE
   LET cfg.entityName = "Customer"
   -- View commands available for this module
   LET cfg.availableCommands = init_view_commands()

   RETURN cfg

END FUNCTION #get_config

-- =====================================================================
-- Function: init_view_commands (PRIVATE)
-- Purpose : Define which view commands are available for customers
-- =====================================================================
PRIVATE FUNCTION init_view_commands() RETURNS DYNAMIC ARRAY OF t_view_command
   DEFINE cmds DYNAMIC ARRAY OF t_view_command
   LET cmds[1].commandName  = "orders"
   LET cmds[1].commandLabel = "Orders"
   LET cmds[1].commandComment = "View Orders for this Customer"
   LET cmds[2].commandName  = "cust_cust_demo"
   LET cmds[2].commandLabel = "Type Assignments"
   LET cmds[2].commandComment = "View Demographic Types for this Customer"
   RETURN cmds
END FUNCTION #init_view_commands

-- =====================================================================
-- Function: submenu_customers
-- Purpose : Main entry point for customers management
-- =====================================================================
FUNCTION submenu_customers()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_customers

-- =====================================================================
-- Function: root_add_customers
-- Purpose : Entry point for customers add from root menu
-- =====================================================================
FUNCTION root_add_customers()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_customers

-- =====================================================================
-- Function: view_customer
-- Purpose : View a specific customer record (called from other modules)
-- =====================================================================
FUNCTION view_customer(cust_id)
   DEFINE cust_id LIKE customers.customerid
   DEFINE where_clause VARCHAR(500)

   IF cust_id IS NULL OR LENGTH(cust_id) == 0 THEN
      ERROR "Customer ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewCustomerWindow WITH FORM "customers"
      ATTRIBUTES(STYLE="modulewindow")

   LET where_clause = " customers.customerid = '", cust_id CLIPPED, "'"
   CALL customers_do_load(where_clause)

   IF customers_arr.getLength() == 0 THEN
      CLOSE WINDOW viewCustomerWindow
      ERROR "Customer not found"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate_view()

   CLOSE WINDOW viewCustomerWindow

END FUNCTION #view_customer

-- =====================================================================
-- Dispatch interface: customers_get_count
-- =====================================================================
FUNCTION customers_get_count()

   RETURN customers_arr.getLength()

END FUNCTION #customers_get_count

-- =====================================================================
-- Dispatch interface: customers_load_at
-- =====================================================================
FUNCTION customers_load_at(idx)
   DEFINE idx INTEGER

   INITIALIZE curr_customers.* TO NULL
   IF idx >= 1 AND idx <= customers_arr.getLength() THEN
      LET curr_customers = customers_arr[idx]
   END IF

END FUNCTION #customers_load_at

-- =====================================================================
-- Dispatch interface: customers_display_curr
-- =====================================================================
FUNCTION customers_display_curr()

   DISPLAY BY NAME curr_customers.*

END FUNCTION #customers_display_curr

-- =====================================================================
-- Dispatch interface: customers_clear_curr
-- =====================================================================
FUNCTION customers_clear_curr()

   INITIALIZE curr_customers.* TO NULL

END FUNCTION #customers_clear_curr

-- =====================================================================
-- Dispatch interface: customers_do_query
-- =====================================================================
FUNCTION customers_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL customers_clear_curr()
   LET int_flag = FALSE
   CONSTRUCT where_clause ON customers.customerid, customers.companyname, customers.contactname,
                             customers.contacttitle, customers.address, customers.city,
                             customers.region, customers.postalcode, customers.country,
                             customers.phone, customers.fax
      FROM s_customers.*
      ON ACTION accept
         ACCEPT CONSTRUCT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL customers_clear_curr()
      CALL customers_arr.clear()
      RETURN
   END IF

   CALL customers_do_load(where_clause)

   IF customers_arr.getLength() == 0 THEN
      MESSAGE "No customers found."
      RETURN
   END IF

END FUNCTION #customers_do_query

-- =====================================================================
-- Function: customers_do_load (PRIVATE)
-- Purpose : Load customers into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION customers_do_load(where_clause)
   DEFINE where_clause VARCHAR(500)
   DEFINE sql_stmt VARCHAR(1024)
   DEFINE temp_customer t_customer

   LET sql_stmt = " SELECT customerid, companyname, contactname, contacttitle,",
                  " address, city, region, postalcode, country, phone, fax",
                  " FROM customers",
                  " WHERE ", where_clause CLIPPED, " ORDER BY companyname"

   CALL customers_arr.clear()

   PREPARE p_customers FROM sql_stmt
   DECLARE c_customers CURSOR FOR p_customers
   FOREACH c_customers INTO temp_customer.*
      CALL customers_arr.appendElement()
      LET customers_arr[customers_arr.getLength()] = temp_customer
   END FOREACH
   CALL customers_clear_curr()

END FUNCTION #customers_do_load

-- =====================================================================
-- Dispatch interface: customers_do_add_edit
-- =====================================================================
FUNCTION customers_do_add_edit(mode CHAR(1))

   CLEAR FORM
   LET int_flag = FALSE
   IF mode == "A" THEN
      CALL customers_clear_curr()
   END IF

   INPUT BY NAME curr_customers.*
      ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS=TRUE)
      BEFORE INPUT
         IF mode == "C" THEN
            CALL DIALOG.setFieldActive("customerid", FALSE)
         END IF
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         VAR valid_status = curr_customers.validateRec(mode)
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      IF mode = "A" THEN
         ERROR "Customer add canceled"
      ELSE
         ERROR "Customer update canceled"
      END IF
      RETURN
   END IF

   VAR rec_status t_valid_rec
   IF mode == "A" THEN
      LET rec_status = curr_customers.insertRec()
   ELSE
      LET rec_status = curr_customers.updateRec()
   END IF

   IF rec_status.valid_status THEN
      CALL customers_display_curr()
      MESSAGE rec_status.valid_msg
   ELSE
      ERROR rec_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #customers_do_add_edit

-- =====================================================================
-- Dispatch interface: customers_do_delete
-- =====================================================================
FUNCTION customers_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "Customer delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_customers.deleteRec()
   IF del_status.valid_status THEN
      MESSAGE del_status.valid_msg
   ELSE
      ERROR del_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #customers_do_delete

-- =====================================================================
-- Dispatch interface: customers_do_refresh
-- =====================================================================
FUNCTION customers_do_refresh(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL customers_arr.appendElement()
         LET customers_arr[customers_arr.getLength()] = curr_customers
      WHEN "C"
         LET customers_arr[currIdx] = curr_customers
      WHEN "D"
         FOR idx = 1 TO customers_arr.getLength()
            IF customers_arr[idx].customerid = curr_customers.customerid THEN
               CALL customers_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #customers_do_refresh

-- =====================================================================
-- Dispatch interface: customers_list_display
-- =====================================================================
FUNCTION customers_list_display()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER
   DEFINE list_arr DYNAMIC ARRAY OF t_customer_list
   DEFINE idx INTEGER

   FOR idx = 1 TO customers_arr.getLength()
      CALL list_arr.appendElement()
      LET list_arr[idx].customerid = customers_arr[idx].customerid
      LET list_arr[idx].companyname = customers_arr[idx].companyname
      LET list_arr[idx].contactname = customers_arr[idx].contactname
      LET list_arr[idx].contacttitle = customers_arr[idx].contacttitle
      LET list_arr[idx].phone = customers_arr[idx].phone
   END FOR

   MESSAGE "Displayed ", list_arr.getLength() USING "<<<<<", " customers"

   DISPLAY ARRAY list_arr TO customers_list.*
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

END FUNCTION #customers_list_display

-- =====================================================================
-- Function: customers_do_command
-- Purpose : Execute a view command for customers
-- =====================================================================
FUNCTION customers_do_command(commandName STRING)
   CASE commandName
      WHEN "orders"
         CALL view_orders_for_customer(curr_customers.customerid)
      WHEN "cust_cust_demo"
         CALL cust_demo_by_customer(curr_customers.customerid)
      OTHERWISE
         ERROR "Unknown command: ", commandName
   END CASE

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #customers_do_command

-- =====================================================================
-- Function: customer_lookup
-- Purpose : Open a lookup window for customer selection
-- =====================================================================
FUNCTION customer_lookup()
   DEFINE cust_id LIKE customers.customerid
   DEFINE cust_name LIKE customers.companyname

   OPEN WINDOW lookupWindow WITH FORM "customers"
      ATTRIBUTES(STYLE="modulewindow")

   CALL customer_lookup_menu()
      RETURNING cust_id, cust_name

   CLOSE WINDOW lookupWindow

   RETURN cust_id, cust_name

END FUNCTION #customer_lookup

-- =====================================================================
-- Function: customer_lookup_menu
-- Purpose : Navigate customers for selection
-- =====================================================================
FUNCTION customer_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL customers_do_query()
   IF customers_arr.getLength() == 0 THEN
      RETURN "", ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= customers_arr.getLength() AND selectedIdx == 0

      CALL customers_load_at(currentIdx)
      CALL customers_display_curr()
      LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", customers_arr.getLength() USING "<<<<"
      MESSAGE statusMessage

      MENU "Customer Selection"
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
            IF currentIdx > customers_arr.getLength() THEN
               LET currentIdx = customers_arr.getLength()
            END IF
            EXIT MENU
         COMMAND "Last" "View last record in result set"
            LET currentIdx = customers_arr.getLength()
            EXIT MENU
         COMMAND "List" "Switch to List View"
            LET currentIdx = customer_lookup_table(currentIdx)
            IF int_flag OR currentIdx < 1 THEN
               LET int_flag = FALSE
            ELSE
               LET selectedIdx = currentIdx
               CALL customers_load_at(selectedIdx)
            END IF
            EXIT MENU
         COMMAND "Select" "Select the current customer"
            LET selectedIdx = currentIdx
            CALL customers_load_at(selectedIdx)
            EXIT MENU
         COMMAND "Exit" "Quit operation"
            LET currentIdx = 0
            EXIT MENU
      END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_customers.customerid, curr_customers.companyname
   END IF

   RETURN "", ""

END FUNCTION #customer_lookup_menu

PRIVATE FUNCTION customer_lookup_table(currentIdx INTEGER) RETURNS (INTEGER)
   DEFINE list_arr DYNAMIC ARRAY OF t_customer_list
   DEFINE idx INTEGER

   OPEN WINDOW customers_list WITH FORM "customers_list"
      ATTRIBUTES(STYLE="modulewindow")

   FOR idx = 1 TO customers_arr.getLength()
      CALL list_arr.appendElement()
      LET list_arr[idx].customerid = customers_arr[idx].customerid
      LET list_arr[idx].companyname = customers_arr[idx].companyname
      LET list_arr[idx].contactname = customers_arr[idx].contactname
      LET list_arr[idx].contacttitle = customers_arr[idx].contacttitle
      LET list_arr[idx].phone = customers_arr[idx].phone
   END FOR

   MESSAGE "Displayed ", list_arr.getLength() USING "<<<<<", " customers"

   VAR first_time = TRUE
   DISPLAY ARRAY list_arr TO customers_list.*
      ATTRIBUTES(DOUBLECLICK=ACCEPT)
      BEFORE ROW
         IF first_time THEN
            CALL DIALOG.setCurrentRow("customers_list", currentIdx)
            LET first_time = FALSE
         ELSE
            LET currentIdx = arr_curr()
         END IF
      ON ACTION accept
         ACCEPT DISPLAY
      ON ACTION CANCEL
         LET int_flag = TRUE
         EXIT DISPLAY
   END DISPLAY

   CLOSE WINDOW customers_list

   RETURN currentIdx

END FUNCTION #customer_lookup_table

PRIVATE DEFINE load_cust_prepped BOOLEAN = FALSE
PUBLIC FUNCTION load_customers(cbx ui.ComboBox) RETURNS ()
   DEFINE cust_id LIKE customers.customerid
   DEFINE cust_name LIKE customers.companyname

   IF NOT load_cust_prepped THEN
      DECLARE curs_load_customers CURSOR FOR 
         SELECT customers.customerid, customers.companyname FROM customers 
         ORDER BY companyname
   END IF

   FOREACH curs_load_customers INTO cust_id, cust_name
      CALL cbx.addItem(cust_id, SFMT("%1 (%2)", cust_name, cust_id))
   END FOREACH

END FUNCTION #load_customers


