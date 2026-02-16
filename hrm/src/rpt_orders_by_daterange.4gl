DATABASE northwind

-- =====================================================================
-- Report: Orders By Date Range
-- Shows all orders within a date range sorted by order date ascending
-- with order total dollar amount and quantity for each order,
-- plus overall totals.
-- Uses Genero REPORT engine for output.
-- =====================================================================

TYPE t_rpt_date_rec RECORD
   orderid LIKE orders.orderid,
   orderdate LIKE orders.orderdate,
   companyname LIKE customers.companyname,
   totalqty INTEGER,
   totalamt FLOAT
END RECORD

DEFINE m_date_count INTEGER

-- =====================================================================
-- Function: run_orders_by_daterange
-- Purpose : Main entry point for the Orders By Date Range report
-- =====================================================================
FUNCTION run_orders_by_daterange()
   DEFINE where_clause STRING
   DEFINE done SMALLINT

   LET done = FALSE

   OPEN WINDOW rptDateWindow WITH FORM "rpt_orders_by_daterange"
      ATTRIBUTES(STYLE="modulewindow")

   WHILE NOT done
      LET int_flag = FALSE

      CONSTRUCT BY NAME where_clause
         ON orders.orderdate

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
      CALL execute_daterange_report(where_clause)

   END WHILE

   CLOSE WINDOW rptDateWindow

END FUNCTION #run_orders_by_daterange

-- =====================================================================
-- Function: execute_daterange_report
-- Purpose : Run the report using REPORT engine
-- =====================================================================
FUNCTION execute_daterange_report(where_clause)
   DEFINE where_clause STRING
   DEFINE r t_rpt_date_rec
   DEFINE sql_stmt STRING
   DEFINE rpt_file STRING

   LET m_date_count = 0
   LET rpt_file = generate_temp_filename("rpt_date", "txt")

   LET sql_stmt = "SELECT orders.orderid, orders.orderdate, customers.companyname,",
                  " SUM(order_details.quantity),",
                  " SUM(order_details.unitprice * order_details.quantity * (1 + order_details.discount))",
                  " FROM orders, order_details, customers",
                  " WHERE orders.orderid = order_details.orderid",
                  " AND orders.customerid = customers.customerid",
                  " AND ", where_clause CLIPPED,
                  " GROUP BY orders.orderid, orders.orderdate, customers.companyname",
                  " ORDER BY orders.orderdate, orders.orderid"

   PREPARE p_rpt_date FROM sql_stmt
   DECLARE c_rpt_date CURSOR FOR p_rpt_date

   START REPORT rpt_orders_daterange TO FILE rpt_file

   FOREACH c_rpt_date INTO r.orderid, r.orderdate, r.companyname,
      r.totalqty, r.totalamt
      LET m_date_count = m_date_count + 1
      OUTPUT TO REPORT rpt_orders_daterange(r)
   END FOREACH

   FINISH REPORT rpt_orders_daterange

   IF m_date_count == 0 THEN
      MESSAGE "No orders found for the selected criteria."
   ELSE
      MESSAGE SFMT("%1 records written to %2", m_date_count, rpt_file)
      CALL display_report_file(rpt_file)
   END IF

END FUNCTION #execute_daterange_report

-- =====================================================================
-- Report: rpt_orders_daterange
-- Purpose : Format the Orders By Date Range report output
-- =====================================================================
REPORT rpt_orders_daterange(r)
   DEFINE r t_rpt_date_rec

   OUTPUT
      PAGE LENGTH 66
      LEFT MARGIN 1

   ORDER EXTERNAL BY r.orderdate, r.orderid

   FORMAT

      FIRST PAGE HEADER
         PRINT COLUMN 1, "======================================================================="
         PRINT COLUMN 1, "Orders By Date Range Report"
         PRINT COLUMN 1, "Report Date: ", TODAY USING "mm/dd/yyyy"
         PRINT COLUMN 1, "======================================================================="
         SKIP 1 LINE
         PRINT COLUMN 1,  "Order ID",
               COLUMN 12, "Order Date",
               COLUMN 25, "Customer",
               COLUMN 58, "Total Qty",
               COLUMN 72, "Order Total"
         PRINT COLUMN 1, "-----------------------------------------------------------------------"

      PAGE HEADER
         PRINT COLUMN 1,  "Order ID",
               COLUMN 12, "Order Date",
               COLUMN 25, "Customer",
               COLUMN 58, "Total Qty",
               COLUMN 72, "Order Total"
         PRINT COLUMN 1, "-----------------------------------------------------------------------"

      ON EVERY ROW
         PRINT COLUMN 1,  r.orderid USING "<<<<<",
               COLUMN 12, r.orderdate USING "mm/dd/yyyy",
               COLUMN 25, r.companyname CLIPPED,
               COLUMN 58, r.totalqty USING "#####&",
               COLUMN 72, r.totalamt USING "###,##&.&&"

      ON LAST ROW
         SKIP 1 LINE
         PRINT COLUMN 1, "======================================================================="
         PRINT COLUMN 25, "Totals:",
               COLUMN 40, "Orders: ", COUNT(*) USING "###,##&",
               COLUMN 58, SUM(r.totalqty) USING "#####&",
               COLUMN 72, SUM(r.totalamt) USING "$###,###,##&.&&"
         PRINT COLUMN 1, "======================================================================="

END REPORT #rpt_orders_daterange
