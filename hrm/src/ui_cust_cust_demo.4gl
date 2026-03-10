IMPORT FGL main_lib
IMPORT FGL model_helper
IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_cust_cust_demo
IMPORT FGL ui_customers
IMPORT FGL ui_cust_demo

DATABASE northwind

DEFINE cust_cust_demo_arr DYNAMIC ARRAY OF t_cust_cust_demo
DEFINE curr_cust_cust_demo t_cust_cust_demo
DEFINE contrl_cust_id LIKE customers.customerid

-- =====================================================================
-- Function: get_config
-- Purpose : Return the controller configuration for customer customer demo
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS t_controller_config
   DEFINE cfg t_controller_config
   LET cfg.moduleName   = "cust_cust_demo"
   LET cfg.formName     = "cust_cust_demo"
   LET cfg.listFormName = "cust_cust_demo_list"
   LET cfg.windowTitle  = "Customer Type Assignments"
   LET cfg.hasModify    = FALSE
   LET cfg.hasQuery     = TRUE
   LET cfg.hasLookup    = FALSE
   LET cfg.entityName   = "Customer Type Assignment"
   RETURN cfg
END FUNCTION #get_config

-- =====================================================================
-- Function: cust_demo_by_customer
-- Purpose : Open customer type assignments in a sub-window for a given customer
-- =====================================================================
FUNCTION cust_demo_by_customer(cust_id)
   DEFINE cust_id LIKE customers.customerid
   DEFINE where_clause VARCHAR(500)

   OPEN WINDOW subw2 WITH FORM "cust_cust_demo"
      ATTRIBUTES(STYLE="modulewindow")

   LET contrl_cust_id = cust_id
   LET where_clause = " customercustomerdemo.customerid = '", cust_id CLIPPED, "'"
   CALL cust_cust_demo_do_load(where_clause)

   IF cust_cust_demo_arr.getLength() == 0 THEN
      LET contrl_cust_id = ""
      CLOSE WINDOW subw2
      ERROR "No Type Assignments found for this Customer"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate()

   LET contrl_cust_id = ""
   CLOSE WINDOW subw2

END FUNCTION #cust_demo_by_customer

-- =====================================================================
-- Function: cust_demo_by_type
-- Purpose : Open customer assignments in a sub-window for a given type
-- =====================================================================
FUNCTION cust_demo_by_type(type_id)
   DEFINE type_id LIKE customerdemographics.customertypeid
   DEFINE where_clause VARCHAR(500)

   OPEN WINDOW subw3 WITH FORM "cust_cust_demo"
      ATTRIBUTES(STYLE="modulewindow")

   LET where_clause = " customercustomerdemo.customertypeid = '", type_id CLIPPED, "'"
   CALL cust_cust_demo_do_load(where_clause)

   IF cust_cust_demo_arr.getLength() == 0 THEN
      CLOSE WINDOW subw3
      ERROR "No Customer Assignments found for this Type"
      RETURN
   END IF

   CALL controller_init(get_config())
   CALL controller_navigate()

   CLOSE WINDOW subw3

END FUNCTION #cust_demo_by_type

-- =====================================================================
-- Function: submenu_cust_cust_demo
-- Purpose : Standard entry point — query then navigate using controller
-- =====================================================================
FUNCTION submenu_cust_cust_demo()

   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_cust_cust_demo

-- =====================================================================
-- Function: root_add_cust_cust_demo
-- Purpose : Entry point for customer type assignment add from root menu
-- =====================================================================
FUNCTION root_add_cust_cust_demo()

   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_cust_cust_demo

-- =====================================================================
-- Dispatch Interface: Functions called by the controller via dispatch
-- =====================================================================

-- Return the number of records in the result set
FUNCTION cust_cust_demo_get_count() RETURNS INTEGER
   RETURN cust_cust_demo_arr.getLength()
END FUNCTION #cust_cust_demo_get_count

-- Load the record at index into the current record
FUNCTION cust_cust_demo_load_at(idx INTEGER)
   INITIALIZE curr_cust_cust_demo.* TO NULL
   IF idx > 0 AND idx <= cust_cust_demo_arr.getLength() THEN
      LET curr_cust_cust_demo = cust_cust_demo_arr[idx]
   END IF
END FUNCTION #cust_cust_demo_load_at

-- Display the current record on the form
FUNCTION cust_cust_demo_display_curr()
   DISPLAY BY NAME curr_cust_cust_demo.*
END FUNCTION #cust_cust_demo_display_curr

-- Clear the current record and form
FUNCTION cust_cust_demo_clear_curr()
   INITIALIZE curr_cust_cust_demo.* TO NULL
END FUNCTION #cust_cust_demo_clear_curr

-- =====================================================================
-- Function: cust_cust_demo_do_query
-- Purpose : Search using CONSTRUCT and load results
-- =====================================================================
FUNCTION cust_cust_demo_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL cust_cust_demo_clear_curr()
   LET int_flag = FALSE
   CONSTRUCT where_clause ON customercustomerdemo.customerid,
                             customers.companyname,
                             customercustomerdemo.customertypeid,
                             customerdemographics.customerdesc
      FROM s_cust_cust_demo.*

      BEFORE FIELD companyname
         MESSAGE "Enter search criteria for the customer's company name"
      AFTER FIELD companyname
         MESSAGE ""

      ON ACTION accept
          ACCEPT CONSTRUCT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT CONSTRUCT

   END CONSTRUCT

   IF int_flag THEN
      CALL cust_cust_demo_clear_curr()
      CALL cust_cust_demo_arr.clear()
      RETURN
   END IF

   CALL cust_cust_demo_do_load(where_clause)

   IF cust_cust_demo_arr.getLength() == 0 THEN
      MESSAGE "No customer type assignments found."
   END IF

END FUNCTION #cust_cust_demo_do_query

-- =====================================================================
-- Function: cust_cust_demo_do_load
-- Purpose : Load customer type assignments into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION cust_cust_demo_do_load(where_clause VARCHAR(500))
   DEFINE sql_stmt VARCHAR(2000)
   DEFINE l_rec t_cust_cust_demo

   LET sql_stmt = " SELECT customercustomerdemo.customerid,",
                  " customers.companyname,",
                  " customercustomerdemo.customertypeid,",
                  " customerdemographics.customerdesc",
                  " FROM customercustomerdemo",
                  " INNER JOIN customers ON customers.customerid = customercustomerdemo.customerid",
                  " INNER JOIN customerdemographics ON customerdemographics.customertypeid = customercustomerdemo.customertypeid",
                  " WHERE ", where_clause,
                  " ORDER BY customercustomerdemo.customerid, customercustomerdemo.customertypeid"

   CALL cust_cust_demo_arr.clear()

   PREPARE p_cust_cust_demo FROM sql_stmt
   DECLARE c_cust_cust_demo CURSOR FOR p_cust_cust_demo
   FOREACH c_cust_cust_demo INTO l_rec.*
      CALL cust_cust_demo_arr.appendElement()
      LET cust_cust_demo_arr[cust_cust_demo_arr.getLength()] = l_rec
   END FOREACH

END FUNCTION #cust_cust_demo_do_load

-- =====================================================================
-- Function: cust_cust_demo_do_add
-- Purpose : Add a new customer type assignment
-- =====================================================================
FUNCTION cust_cust_demo_do_add()
   DEFINE selected_cust_id LIKE customers.customerid
   DEFINE selected_companyname LIKE customers.companyname
   DEFINE selected_type_id LIKE customerdemographics.customertypeid
   DEFINE selected_type_desc LIKE customerdemographics.customerdesc
   DEFINE cust_cust_demo_valid t_valid_rec

   CLEAR FORM
   LET int_flag = FALSE
   CALL cust_cust_demo_clear_curr()

   -- Pre-fill customer id when launched from customer context
   IF contrl_cust_id IS NOT NULL AND LENGTH(contrl_cust_id) > 0 THEN
      LET curr_cust_cust_demo.customerid = contrl_cust_id
      LET cust_cust_demo_valid = curr_cust_cust_demo.validateCustomer()
      CALL cust_cust_demo_display_curr()
   END IF

   INPUT BY NAME curr_cust_cust_demo.customerid, curr_cust_cust_demo.customertypeid
      ATTRIBUTES(UNBUFFERED)

      ON ACTION zoom_customer INFIELD customerid
         CALL customer_lookup()
            RETURNING selected_cust_id, selected_companyname
         IF selected_cust_id IS NOT NULL AND LENGTH(selected_cust_id) > 0 THEN
            LET curr_cust_cust_demo.customerid = selected_cust_id
            LET curr_cust_cust_demo.companyname = selected_companyname
            DISPLAY BY NAME curr_cust_cust_demo.companyname
         END IF

      ON ACTION zoom_cust_type INFIELD customertypeid
         CALL cust_demo_lookup()
            RETURNING selected_type_id, selected_type_desc
         IF selected_type_id IS NOT NULL AND LENGTH(selected_type_id) > 0 THEN
            LET curr_cust_cust_demo.customertypeid = selected_type_id
            LET curr_cust_cust_demo.customerdesc = selected_type_desc
            DISPLAY BY NAME curr_cust_cust_demo.customerdesc
         END IF

      AFTER FIELD customerid
         IF curr_cust_cust_demo.customerid IS NOT NULL
            AND LENGTH(curr_cust_cust_demo.customerid) > 0 THEN
            LET cust_cust_demo_valid = curr_cust_cust_demo.validateCustomer()
            IF cust_cust_demo_valid.valid_status THEN
               DISPLAY BY NAME curr_cust_cust_demo.companyname
            ELSE
               ERROR cust_cust_demo_valid.valid_msg
               NEXT FIELD customerid
            END IF
         END IF

      AFTER FIELD customertypeid
         IF curr_cust_cust_demo.customertypeid IS NOT NULL
            AND LENGTH(curr_cust_cust_demo.customertypeid) > 0 THEN
            LET cust_cust_demo_valid = curr_cust_cust_demo.validateCustomerType()
            IF cust_cust_demo_valid.valid_status THEN
               DISPLAY BY NAME curr_cust_cust_demo.customerdesc
            ELSE
               ERROR cust_cust_demo_valid.valid_msg
               NEXT FIELD customertypeid
            END IF
         END IF

      ON ACTION accept
          ACCEPT INPUT
      ON ACTION cancel
          LET int_flag = TRUE
          EXIT INPUT

      AFTER INPUT
         VAR valid_status = curr_cust_cust_demo.validateRec("A")
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      ERROR "Customer type assignment add canceled"
      RETURN
   END IF

   VAR ins_status = curr_cust_cust_demo.insertRec()
   IF ins_status.valid_status THEN
      MESSAGE ins_status.valid_msg
   ELSE
      ERROR ins_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #cust_cust_demo_do_add

-- =====================================================================
-- Function: cust_cust_demo_do_edit
-- Purpose : Edit not supported for customer type assignments (no-op)
-- =====================================================================
FUNCTION cust_cust_demo_do_edit()
   LET int_flag = TRUE
END FUNCTION #cust_cust_demo_do_edit

-- =====================================================================
-- Function: cust_cust_demo_do_delete
-- Purpose : Delete an existing customer type assignment record
-- =====================================================================
FUNCTION cust_cust_demo_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "Customer type assignment delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_cust_cust_demo.deleteRec()
   IF del_status.valid_status THEN
      MESSAGE del_status.valid_msg
   ELSE
      ERROR del_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #cust_cust_demo_do_delete

-- =====================================================================
-- Function: cust_cust_demo_do_refresh
-- Purpose : Refresh the array after add or delete operations
-- =====================================================================
FUNCTION cust_cust_demo_do_refresh(currIdx INTEGER, operation CHAR(1))
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL cust_cust_demo_arr.appendElement()
         LET cust_cust_demo_arr[cust_cust_demo_arr.getLength()] = curr_cust_cust_demo
      WHEN "D"
         FOR idx = 1 TO cust_cust_demo_arr.getLength()
            IF cust_cust_demo_arr[idx].customerid == curr_cust_cust_demo.customerid
               AND cust_cust_demo_arr[idx].customertypeid == curr_cust_cust_demo.customertypeid THEN
               CALL cust_cust_demo_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #cust_cust_demo_do_refresh

-- =====================================================================
-- Function: cust_cust_demo_list_display
-- Purpose : DISPLAY ARRAY list view for customer type assignments
-- =====================================================================
FUNCTION cust_cust_demo_list_display() RETURNS (INTEGER, INTEGER)
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER

   LET selectedIdx = 0
   LET selectedOption = 0
   LET int_flag = FALSE

   MESSAGE "Displayed ", cust_cust_demo_arr.getLength() USING "<<<<<", " customer type assignments"

   DISPLAY ARRAY cust_cust_demo_arr TO cust_cust_demo_list.*
      ON ACTION add
         LET selectedOption = cAddRecord
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

END FUNCTION #cust_cust_demo_list_display

-- =====================================================================
-- Function: cust_cust_demo_do_command
-- Purpose : Execute a view command for customer type assignments (none available)
-- =====================================================================
FUNCTION cust_cust_demo_do_command(commandName STRING)
   ERROR "Unknown command: ", commandName

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #cust_cust_demo_do_command
