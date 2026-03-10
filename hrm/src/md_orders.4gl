IMPORT FGL main_lib
IMPORT FGL model_helper
IMPORT FGL model_orders
IMPORT FGL model_order_details
DATABASE northwind

DEFINE g_order t_order
DEFINE g_details DYNAMIC ARRAY OF t_order_detail

-- =====================================================================
-- Main entry point for master-detail orders
-- =====================================================================
PUBLIC FUNCTION master_detail_orders()
   DEFINE where_clause VARCHAR(500)
   DEFINE sql_stmt VARCHAR(1000)
   DEFINE order_id INTEGER
   DEFINE query_arr DYNAMIC ARRAY OF RECORD
      orderid INTEGER
   END RECORD
   DEFINE search_cust VARCHAR(100)
   DEFINE search_emp VARCHAR(100)
   DEFINE i INTEGER

   OPEN WINDOW mdOrderWindow WITH FORM "md_orders"
      ATTRIBUTES(BORDER)

   -- Main loop for query and edit
   WHILE TRUE
      -- Query dialog for search criteria
      LET search_cust = NULL
      LET search_emp = NULL

      INPUT BY NAME search_cust, search_emp
         ATTRIBUTES(UNBUFFERED)
         ON ACTION accept
            EXIT INPUT
         ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
      END INPUT

      IF int_flag THEN
         EXIT WHILE
      END IF

      -- Build the WHERE clause based on search criteria
      LET where_clause = "1 = 1"

      IF search_cust IS NOT NULL AND search_cust <> "" THEN
         LET where_clause = where_clause || " AND customers.customername LIKE '%" ||
            search_cust || "%'"
      END IF
      IF search_emp IS NOT NULL AND search_emp <> "" THEN
         LET where_clause = where_clause || " AND employees.firstname || ' ' || employees.lastname LIKE '%" ||
            search_emp || "%'"
      END IF

      LET sql_stmt = "SELECT orderid FROM orders " ||
         "LEFT JOIN customers ON orders.customerid = customers.customerid " ||
         "LEFT JOIN employees ON orders.employeeid = employees.employeeid " ||
         "WHERE " || where_clause || " ORDER BY orders.orderid"

      INITIALIZE query_arr TO NULL
      DECLARE c_results CURSOR FROM sql_stmt
      LET i = 0
      FOREACH c_results INTO order_id
         LET i = i + 1
         LET query_arr[i].orderid = order_id
      END FOREACH

      -- Display results and allow selection
      DISPLAY ARRAY query_arr TO orders.*
         BEFORE ROW
            -- Load and edit the selected order
            CALL load_and_edit_order(query_arr[ARR_CURR()].orderid)
            IF int_flag THEN
               LET int_flag = FALSE
               EXIT DISPLAY
            END IF

         ON ACTION exit
            LET int_flag = TRUE
            EXIT DISPLAY
      END DISPLAY

      IF int_flag THEN
         EXIT WHILE
      END IF
   END WHILE

   CLOSE WINDOW mdOrderWindow

END FUNCTION

-- =====================================================================
-- Load and edit a single order with its details
-- =====================================================================
PRIVATE FUNCTION load_and_edit_order(p_orderid INTEGER)
   DEFINE detail_rec t_order_detail

   -- Initialize detail array
   INITIALIZE g_details TO NULL

   -- Load the order header
   SELECT * INTO g_order.* FROM orders WHERE orderid = p_orderid
   IF SQLCA.SQLCODE <> 0 THEN
      MESSAGE "Error loading order"
      RETURN
   END IF

   -- Load customer name if available
   IF g_order.customerid IS NOT NULL THEN
      SELECT customername INTO g_order.customername FROM customers
         WHERE customerid = g_order.customerid
   END IF

   -- Load employee name if available
   IF g_order.employeeid IS NOT NULL THEN
      SELECT firstname || ' ' || lastname INTO g_order.employeename FROM employees
         WHERE employeeid = g_order.employeeid
   END IF

   -- Load detail records
   DECLARE c_details CURSOR FOR
      SELECT order_details.orderid, order_details.productid,
             products.productname, order_details.unitprice,
             order_details.quantity, order_details.discount
      FROM order_details
      LEFT JOIN products ON order_details.productid = products.productid
      WHERE order_details.orderid = p_orderid
      ORDER BY order_details.productid

   FOREACH c_details INTO detail_rec.*
      LET g_details[g_details.getLength() + 1] = detail_rec
   END FOREACH

   -- Display the header fields
   DISPLAY BY NAME
      g_order.orderid,
      g_order.customername,
      g_order.employeename,
      g_order.orderdate,
      g_order.shipname,
      g_order.shipaddress,
      g_order.shipcity,
      g_order.shipregion,
      g_order.shippostalcode,
      g_order.shipcountry

   -- Edit detail lines
   INPUT ARRAY g_details FROM sr_order_details.*
      ATTRIBUTES(UNBUFFERED)

      BEFORE ROW
         MESSAGE "Edit order detail lines"

      ON ACTION add_detail
         LET g_details[ARR_CURR()].orderid = p_orderid

      ON ACTION delete_detail
         CALL delete_detail_line(ARR_CURR())

      AFTER ROW
         -- Validate and save after each row edit
         IF g_details[ARR_CURR()].productid > 0 THEN
            CALL save_detail_line(ARR_CURR(), p_orderid)
         END IF
   END INPUT

END FUNCTION

-- =====================================================================
-- Save a detail line
-- =====================================================================
PRIVATE FUNCTION save_detail_line(p_idx INTEGER, p_orderid INTEGER)
   DEFINE result t_valid_rec

   IF p_idx > 0 AND p_idx <= g_details.getLength() THEN
      LET g_details[p_idx].orderid = p_orderid
      
      IF g_details[p_idx].productid > 0 THEN
         LET result = g_details[p_idx].validateRec("C")
         IF NOT result.valid_status THEN
            MESSAGE result.valid_msg
         ELSE
            LET result = g_details[p_idx].updateRec()
         END IF
      END IF
   END IF
END FUNCTION

-- =====================================================================
-- Delete a detail line
-- =====================================================================
PRIVATE FUNCTION delete_detail_line(p_idx INTEGER)
   DEFINE result t_valid_rec
   
   IF p_idx > 0 AND p_idx <= g_details.getLength() THEN
      IF g_details[p_idx].orderid > 0 THEN
         LET result = g_details[p_idx].deleteRec()
      END IF
      CALL g_details.deleteElement(p_idx)
   END IF
END FUNCTION
