DATABASE northwind

-- =====================================================================
-- Report: Orders By Employee
-- Shows all orders and order details for selected employees
-- with line totals, order subtotals, and employee grand total.
-- Uses Genero REPORT engine for output.
-- =====================================================================

TYPE t_rpt_emp_rec RECORD
   orderid LIKE orders.orderid,
   orderdate LIKE orders.orderdate,
   productname LIKE products.productname,
   unitprice LIKE order_details.unitprice,
   quantity LIKE order_details.quantity,
   discount LIKE order_details.discount,
   linetotal FLOAT
END RECORD

DEFINE m_emp_count INTEGER

-- =====================================================================
-- Function: run_orders_by_employee
-- Purpose : Main entry point for the Orders By Employee report
-- =====================================================================
FUNCTION run_orders_by_employee()
   DEFINE where_clause STRING
   DEFINE done SMALLINT

   LET done = FALSE

   OPEN WINDOW rptEmpWindow WITH FORM "rpt_orders_by_employee"
      ATTRIBUTES(STYLE="modulewindow")

   WHILE NOT done
      LET int_flag = FALSE

      CONSTRUCT BY NAME where_clause
         ON employees.employeeid, employees.lastname, employees.firstname

         ON ACTION run
            ACCEPT CONSTRUCT

         ON ACTION cancel
            LET int_flag = TRUE
            EXIT CONSTRUCT

         ON ACTION exit
            LET done = TRUE
            LET int_flag = TRUE
            EXIT CONSTRUCT

      END CONSTRUCT

      IF int_flag THEN
         IF done THEN
            EXIT WHILE
         END IF
         CONTINUE WHILE
      END IF

      -- Execute report
      CALL execute_emp_report(where_clause)

   END WHILE

   CLOSE WINDOW rptEmpWindow

END FUNCTION #run_orders_by_employee

-- =====================================================================
-- Function: execute_emp_report
-- Purpose : Run the report for selected employees using REPORT engine
-- =====================================================================
FUNCTION execute_emp_report(where_clause)
   DEFINE where_clause STRING
   DEFINE r t_rpt_emp_rec
   DEFINE sql_stmt STRING
   DEFINE rpt_file STRING

   LET m_emp_count = 0
   LET rpt_file = generate_temp_filename("rpt_emp", "txt")

   LET sql_stmt = "SELECT orders.orderid, orders.orderdate, products.productname,",
                  " order_details.unitprice, order_details.quantity, order_details.discount,",
                  " order_details.unitprice * order_details.quantity * (1 + order_details.discount)",
                  " FROM orders, order_details, products, employees",
                  " WHERE orders.employeeid = employees.employeeid",
                  " AND order_details.orderid = orders.orderid",
                  " AND products.productid = order_details.productid",
                  " AND ", where_clause CLIPPED,
                  " ORDER BY orders.orderid, products.productname"

   PREPARE p_rpt_emp FROM sql_stmt
   DECLARE c_rpt_emp CURSOR FOR p_rpt_emp

   START REPORT rpt_orders_employee TO FILE rpt_file

   FOREACH c_rpt_emp INTO r.orderid, r.orderdate, r.productname,
      r.unitprice, r.quantity, r.discount, r.linetotal
      LET m_emp_count = m_emp_count + 1
      OUTPUT TO REPORT rpt_orders_employee(r)
   END FOREACH

   FINISH REPORT rpt_orders_employee

   IF m_emp_count == 0 THEN
      MESSAGE "No orders found for the selected criteria."
   ELSE
      MESSAGE SFMT("%1 records written to %2", m_emp_count, rpt_file)
      CALL display_report_file(rpt_file)
   END IF

END FUNCTION #execute_emp_report

-- =====================================================================
-- Report: rpt_orders_employee
-- Purpose : Format the Orders By Employee report output
-- =====================================================================
REPORT rpt_orders_employee(r)
   DEFINE r t_rpt_emp_rec

   OUTPUT
      PAGE LENGTH 66
      LEFT MARGIN 1

   ORDER EXTERNAL BY r.orderid

   FORMAT

      FIRST PAGE HEADER
         PRINT COLUMN 1, "==================================================================="
         PRINT COLUMN 1, "Orders By Employee Report"
         PRINT COLUMN 1, "Date: ", TODAY USING "mm/dd/yyyy"
         PRINT COLUMN 1, "==================================================================="
         SKIP 1 LINE
         PRINT COLUMN 1,  "Order ID",
               COLUMN 12, "Order Date",
               COLUMN 25, "Product",
               COLUMN 52, "Unit Price",
               COLUMN 65, "Qty",
               COLUMN 72, "Discount",
               COLUMN 83, "Line Total"
         PRINT COLUMN 1, "-------------------------------------------------------------------"

      PAGE HEADER
         PRINT COLUMN 1,  "Order ID",
               COLUMN 12, "Order Date",
               COLUMN 25, "Product",
               COLUMN 52, "Unit Price",
               COLUMN 65, "Qty",
               COLUMN 72, "Discount",
               COLUMN 83, "Line Total"
         PRINT COLUMN 1, "-------------------------------------------------------------------"

      BEFORE GROUP OF r.orderid
         SKIP 1 LINE

      ON EVERY ROW
         PRINT COLUMN 1,  r.orderid USING "<<<<<",
               COLUMN 12, r.orderdate USING "mm/dd/yyyy",
               COLUMN 25, r.productname CLIPPED,
               COLUMN 52, r.unitprice USING "##,##&.&&",
               COLUMN 65, r.quantity USING "####&",
               COLUMN 72, r.discount USING "#&.&&",
               COLUMN 83, r.linetotal USING "###,##&.&&"

      AFTER GROUP OF r.orderid
         PRINT COLUMN 52, "------------------------------"
         PRINT COLUMN 52, "Order Subtotal:",
               COLUMN 83, GROUP SUM(r.linetotal) USING "$###,##&.&&"

      ON LAST ROW
         SKIP 1 LINE
         PRINT COLUMN 1, "==================================================================="
         PRINT COLUMN 52, "Grand Total:",
               COLUMN 83, SUM(r.linetotal) USING "$###,###,##&.&&"
         PRINT COLUMN 1, "==================================================================="
         PRINT COLUMN 1, "Total Detail Lines: ", COUNT(*) USING "###,##&"

END REPORT #rpt_orders_employee


