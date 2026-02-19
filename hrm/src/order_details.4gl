IMPORT FGL list_view_helper
IMPORT FGL controller
IMPORT FGL model_order_details
DATABASE northwind

DEFINE order_details_arr DYNAMIC ARRAY OF t_order_detail

TYPE t_order_detail_list RECORD
   orderid LIKE order_details.orderid,
   productname LIKE products.productname,
   unitprice LIKE order_details.unitprice,
   quantity LIKE order_details.quantity,
   discount LIKE order_details.discount
END RECORD

DEFINE curr_order_details t_order_detail

DEFINE skip_query SMALLINT
DEFINE default_order_id LIKE order_details.orderid

-- =====================================================================
-- Function: get_config (PRIVATE)
-- Purpose : Return controller configuration for order_details module
-- =====================================================================
PRIVATE FUNCTION get_config() RETURNS (t_controller_config)
   DEFINE cfg t_controller_config

   LET cfg.moduleName = "order_details"
   LET cfg.formName = "order_details"
   LET cfg.listFormName = "order_details_list"
   LET cfg.windowTitle = "Order Details Management"
   LET cfg.hasModify = TRUE
   LET cfg.hasQuery = TRUE
   LET cfg.hasLookup = FALSE
   LET cfg.entityName = "Order Detail"

   RETURN cfg

END FUNCTION #get_config

-- =====================================================================
-- Function: view_details_for_order
-- Purpose : View order details for a specific order (with auto-add loop)
-- =====================================================================
FUNCTION view_details_for_order(order_id)
   DEFINE order_id LIKE order_details.orderid
   DEFINE where_clause VARCHAR(500)

   OPEN WINDOW subWindow WITH FORM "order_details"
      ATTRIBUTES(STYLE="modulewindow")

   LET skip_query = TRUE
   LET default_order_id = order_id
   LET where_clause = " order_details.orderid = ", order_id

   CALL order_details_do_load(where_clause)

   WHILE order_details_arr.getLength() == 0

      CALL order_details_do_add()
      IF int_flag == TRUE THEN
         EXIT WHILE
      END IF
      CALL order_details_do_load(where_clause)

   END WHILE

   IF order_details_arr.getLength() > 0 THEN
      CALL controller_init(get_config())
      IF skip_query THEN
         CALL controller_navigate()
      ELSE
         CALL controller_query_then_navigate()
      END IF
   END IF

   LET skip_query = FALSE
   LET default_order_id = 0
   CLOSE WINDOW subWindow

END FUNCTION #view_details_for_order

-- =====================================================================
-- Function: submenu_order_details
-- Purpose : Main entry point for order details management
-- =====================================================================
FUNCTION submenu_order_details()

   LET skip_query = FALSE
   LET default_order_id = 0
   CALL controller_init(get_config())
   CALL controller_query_then_navigate()

END FUNCTION #submenu_order_details

-- =====================================================================
-- Function: root_add_order_details
-- Purpose : Entry point for order details add from root menu
-- =====================================================================
FUNCTION root_add_order_details()

   LET skip_query = FALSE
   LET default_order_id = 0
   CALL controller_init(get_config())
   CALL controller_add()

END FUNCTION #root_add_order_details

-- =====================================================================
-- Dispatch interface: order_details_get_count
-- =====================================================================
FUNCTION order_details_get_count()

   RETURN order_details_arr.getLength()

END FUNCTION #order_details_get_count

-- =====================================================================
-- Dispatch interface: order_details_load_at
-- =====================================================================
FUNCTION order_details_load_at(idx)
   DEFINE idx INTEGER

   INITIALIZE curr_order_details.* TO NULL
   IF default_order_id IS NOT NULL AND default_order_id > 0 THEN
      LET curr_order_details.orderid = default_order_id
   END IF
   IF idx >= 1 AND idx <= order_details_arr.getLength() THEN
      LET curr_order_details = order_details_arr[idx]
   END IF

END FUNCTION #order_details_load_at

-- =====================================================================
-- Dispatch interface: order_details_display_curr
-- =====================================================================
FUNCTION order_details_display_curr()

   DISPLAY BY NAME curr_order_details.*

END FUNCTION #order_details_display_curr

-- =====================================================================
-- Dispatch interface: order_details_clear_curr
-- =====================================================================
FUNCTION order_details_clear_curr()

   INITIALIZE curr_order_details.* TO NULL
   IF default_order_id IS NOT NULL AND default_order_id > 0 THEN
      LET curr_order_details.orderid = default_order_id
   END IF

END FUNCTION #order_details_clear_curr

-- =====================================================================
-- Dispatch interface: order_details_do_query
-- =====================================================================
FUNCTION order_details_do_query()
   DEFINE where_clause VARCHAR(500)

   CLEAR FORM
   CALL order_details_clear_curr()
   LET int_flag = FALSE
   CONSTRUCT where_clause ON order_details.orderid, order_details.productid,
                             order_details.unitprice, order_details.quantity, order_details.discount
      FROM s_order_details.orderid, s_order_details.productid,
           s_order_details.unitprice, s_order_details.quantity, s_order_details.discount
      ON ACTION accept
         ACCEPT CONSTRUCT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT CONSTRUCT
   END CONSTRUCT

   IF int_flag THEN
      CALL order_details_clear_curr()
      CALL order_details_arr.clear()
      RETURN
   END IF

   CALL order_details_do_load(where_clause)

   IF order_details_arr.getLength() == 0 THEN
      MESSAGE "No order details found."
      RETURN
   END IF

END FUNCTION #order_details_do_query

-- =====================================================================
-- Function: order_details_do_load (PRIVATE)
-- Purpose : Load order details into dynamic array based on WHERE clause
-- =====================================================================
PRIVATE FUNCTION order_details_do_load(where_clause)
   DEFINE where_clause VARCHAR(500)
   DEFINE sql_stmt VARCHAR(1024)

   LET sql_stmt = " SELECT order_details.orderid, order_details.productid, products.productname,",
                  " order_details.unitprice, order_details.quantity, order_details.discount",
                  " FROM order_details",
                  " LEFT OUTER JOIN products ON products.productid = order_details.productid",
                  " WHERE ", where_clause CLIPPED, " ORDER BY order_details.orderid, order_details.productid"

   CALL order_details_arr.clear()

   PREPARE p_order_details FROM sql_stmt
   DECLARE c_order_details CURSOR FOR p_order_details
   FOREACH c_order_details INTO curr_order_details.*
      CALL order_details_arr.appendElement()
      LET order_details_arr[order_details_arr.getLength()] = curr_order_details
   END FOREACH
   CALL order_details_clear_curr()

END FUNCTION #order_details_do_load

-- =====================================================================
-- Dispatch interface: order_details_do_add
-- =====================================================================
FUNCTION order_details_do_add()
   DEFINE order_details_valid SMALLINT
   DEFINE valid_msg CHAR(75)
   DEFINE selected_order_id LIKE orders.orderid
   DEFINE selected_product_id LIKE products.productid
   DEFINE selected_product_name LIKE products.productname

   CLEAR FORM
   LET int_flag = FALSE
   CALL order_details_clear_curr()
   INPUT BY NAME curr_order_details.*
      ATTRIBUTE(UNBUFFERED)
      BEFORE INPUT
         IF curr_order_details.orderid > 0 THEN
            NEXT FIELD productid
         END IF
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      ON ACTION zoom_order
         CALL order_lookup()
            RETURNING selected_order_id
         IF selected_order_id > 0 THEN
            LET curr_order_details.orderid = selected_order_id
         END IF
      ON ACTION zoom_product
         CALL product_lookup()
            RETURNING selected_product_id, selected_product_name
         IF selected_product_id > 0 THEN
            LET curr_order_details.productid = selected_product_id
            LET curr_order_details.productname = selected_product_name
         END IF

      AFTER FIELD orderid
         CALL validate_orderid_field()
            RETURNING order_details_valid, valid_msg
         IF NOT order_details_valid THEN
            ERROR valid_msg
            NEXT FIELD orderid
         END IF

      AFTER FIELD productid
         CALL validate_productid_field()
            RETURNING order_details_valid, valid_msg
         IF NOT order_details_valid THEN
            ERROR valid_msg
            NEXT FIELD productid
         END IF

      AFTER INPUT
         VAR valid_status = curr_order_details.validateRec("A")
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      ERROR "Order detail add canceled"
      RETURN
   END IF

   VAR ins_status = curr_order_details.insertRec()
   IF ins_status.valid_status THEN
      CALL order_details_display_curr()
      MESSAGE ins_status.valid_msg
   ELSE
      ERROR ins_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #order_details_do_add

-- =====================================================================
-- Dispatch interface: order_details_do_edit
-- =====================================================================
FUNCTION order_details_do_edit()

   LET int_flag = FALSE
   INPUT BY NAME curr_order_details.unitprice, curr_order_details.quantity, curr_order_details.discount
      ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
      ON ACTION accept
         ACCEPT INPUT
      ON ACTION cancel
         LET int_flag = TRUE
         EXIT INPUT
      AFTER INPUT
         VAR valid_status = curr_order_details.validateRec("C")
         IF NOT valid_status.valid_status THEN
            ERROR valid_status.valid_msg
            CONTINUE INPUT
         END IF
   END INPUT

   IF int_flag THEN
      ERROR "Order detail update canceled"
      RETURN
   END IF

   VAR upd_status = curr_order_details.updateRec()
   IF upd_status.valid_status THEN
      MESSAGE upd_status.valid_msg
   ELSE
      ERROR upd_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #order_details_do_edit

-- =====================================================================
-- Dispatch interface: order_details_do_delete
-- =====================================================================
FUNCTION order_details_do_delete()

   LET int_flag = FALSE
   IF NOT confirm_delete() THEN
      ERROR "Order detail delete canceled"
      LET int_flag = TRUE
      RETURN
   END IF

   VAR del_status = curr_order_details.deleteRec()
   IF del_status.valid_status THEN
      MESSAGE del_status.valid_msg
   ELSE
      ERROR del_status.valid_msg
      LET int_flag = TRUE
   END IF

END FUNCTION #order_details_do_delete

-- =====================================================================
-- Dispatch interface: order_details_do_refresh
-- =====================================================================
FUNCTION order_details_do_refresh(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL order_details_arr.appendElement()
         LET order_details_arr[order_details_arr.getLength()] = curr_order_details
      WHEN "C"
         LET order_details_arr[currIdx] = curr_order_details
      WHEN "D"
         FOR idx = 1 TO order_details_arr.getLength()
            IF order_details_arr[idx].orderid = curr_order_details.orderid
               AND order_details_arr[idx].productid = curr_order_details.productid THEN
               CALL order_details_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #order_details_do_refresh

-- =====================================================================
-- Dispatch interface: order_details_list_display
-- =====================================================================
FUNCTION order_details_list_display()
   DEFINE selectedIdx INTEGER
   DEFINE selectedOption INTEGER
   DEFINE list_arr DYNAMIC ARRAY OF t_order_detail_list
   DEFINE idx INTEGER

   FOR idx = 1 TO order_details_arr.getLength()
      CALL list_arr.appendElement()
      LET list_arr[idx].orderid = order_details_arr[idx].orderid
      LET list_arr[idx].productname = order_details_arr[idx].productname
      LET list_arr[idx].unitprice = order_details_arr[idx].unitprice
      LET list_arr[idx].quantity = order_details_arr[idx].quantity
      LET list_arr[idx].discount = order_details_arr[idx].discount
   END FOR

   MESSAGE "Displayed ", list_arr.getLength() USING "<<<<<", " order details"

   DISPLAY ARRAY list_arr TO order_details_list.*
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

END FUNCTION #order_details_list_display

-- =====================================================================
-- Function: order_details_do_command
-- Purpose : Execute a view command for order details (none available)
-- =====================================================================
FUNCTION order_details_do_command(commandName STRING)
   ERROR "Unknown command: ", commandName

   #Re-initialize the right config to the controller
   CALL controller_init(get_config())

END FUNCTION #order_details_do_command



-- =====================================================================
-- Function: validate_orderid_field (PRIVATE)
-- =====================================================================
PRIVATE FUNCTION validate_orderid_field()

   IF curr_order_details.orderid IS NOT NULL THEN
      SELECT 1 FROM orders WHERE orders.orderid = curr_order_details.orderid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Order ID does not exist in orders table"
      END IF
   END IF
   RETURN TRUE, "Okay"

END FUNCTION #validate_orderid_field

-- =====================================================================
-- Function: validate_productid_field (PRIVATE)
-- =====================================================================
PRIVATE FUNCTION validate_productid_field()
   DEFINE product_name LIKE products.productname

   IF curr_order_details.productid IS NOT NULL THEN
      SELECT productname INTO product_name FROM products WHERE products.productid = curr_order_details.productid
      IF sqlca.sqlcode == NOTFOUND THEN
         RETURN FALSE, "Product ID does not exist in products table"
      END IF
      LET curr_order_details.productname = product_name
   END IF
   RETURN TRUE, "Okay"

END FUNCTION #validate_productid_field
