IMPORT FGL main_lib
IMPORT FGL report_helper
DATABASE northwind

-- =====================================================================
-- Report: Employees With Order Detail Totals
-- Shows all employees with total order amounts for each employee.
-- Subtotals per employee, grand total overall.
-- Sorted by employee last name, then first name.
-- Uses Genero REPORT engine for output.
-- =====================================================================

TYPE t_rpt_emp_totals_rec RECORD
   employeeid LIKE employees.employeeid,
   lastname LIKE employees.lastname,
   firstname LIKE employees.firstname,
   orderscount INTEGER,
   orderdetailscount INTEGER,
   totalamount FLOAT
END RECORD

DEFINE m_emp_rec_count INTEGER

-- =====================================================================
-- Function: run_employees_with_totals
-- Purpose : Main entry point for Employees With Totals report
-- =====================================================================
FUNCTION run_employees_with_totals()
   DEFINE where_clause STRING
   DEFINE done SMALLINT

   LET done = FALSE

   OPEN WINDOW rptEmpTotalsWindow WITH FORM "rpt_employees_with_totals"
      ATTRIBUTES(BORDER, STYLE="noactions")

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
      CALL execute_emp_totals_report(where_clause)

   END WHILE

   CLOSE WINDOW rptEmpTotalsWindow

END FUNCTION #run_employees_with_totals

-- =====================================================================
-- Function: execute_emp_totals_report
-- Purpose : Run the report using REPORT engine
-- =====================================================================
FUNCTION execute_emp_totals_report(where_clause)
   DEFINE where_clause STRING
   DEFINE r t_rpt_emp_totals_rec
   DEFINE sql_stmt STRING
   DEFINE rpt_file STRING

   LET m_emp_rec_count = 0
   LET rpt_file = generate_temp_filename("rpt_emp_totals", "txt")

   LET sql_stmt = "SELECT employees.employeeid, employees.lastname, employees.firstname,",
                  " COUNT(DISTINCT orders.orderid),",
                  " COUNT(DISTINCT order_details.orderid),",
                  " SUM(order_details.unitprice * order_details.quantity * (1 + order_details.discount))",
                  " FROM employees",
                  " LEFT JOIN orders ON employees.employeeid = orders.employeeid",
                  " LEFT JOIN order_details ON orders.orderid = order_details.orderid",
                  " WHERE ", where_clause CLIPPED,
                  " GROUP BY employees.employeeid, employees.lastname, employees.firstname",
                  " ORDER BY employees.lastname, employees.firstname"

   PREPARE p_rpt_emp_totals FROM sql_stmt
   DECLARE c_rpt_emp_totals CURSOR FOR p_rpt_emp_totals

   START REPORT rpt_employees_totals TO FILE rpt_file

   FOREACH c_rpt_emp_totals INTO r.employeeid, r.lastname, r.firstname,
      r.orderscount, r.orderdetailscount, r.totalamount
      LET m_emp_rec_count = m_emp_rec_count + 1
      OUTPUT TO REPORT rpt_employees_totals(r)
   END FOREACH

   FINISH REPORT rpt_employees_totals

   IF m_emp_rec_count == 0 THEN
      MESSAGE "No employees found for the selected criteria."
   ELSE
      MESSAGE SFMT("%1 records written to %2", m_emp_rec_count, rpt_file)
      CALL display_report_file(rpt_file)
   END IF

END FUNCTION #execute_emp_totals_report

-- =====================================================================
-- Report: rpt_employees_totals
-- Purpose : Format the Employees With Totals report output
-- =====================================================================
REPORT rpt_employees_totals(r)
   DEFINE r t_rpt_emp_totals_rec

   OUTPUT
      PAGE LENGTH 66
      LEFT MARGIN 1

   ORDER EXTERNAL BY r.lastname, r.firstname

   FORMAT

      FIRST PAGE HEADER
         PRINT COLUMN 1, "======================================================================="
         PRINT COLUMN 1, "Employees With Order Detail Totals Report"
         PRINT COLUMN 1, "Date: ", TODAY USING "mm/dd/yyyy"
         PRINT COLUMN 1, "======================================================================="
         SKIP 1 LINE
         PRINT COLUMN 1,  "ID",
               COLUMN 5, "Last Name",
               COLUMN 25, "First Name",
               COLUMN 45, "# Orders",
               COLUMN 60, "# Items",
               COLUMN 75, "Total Amount"
         PRINT COLUMN 1, "-----------------------------------------------------------------------"

      PAGE HEADER
         PRINT COLUMN 1,  "ID",
               COLUMN 5, "Last Name",
               COLUMN 25, "First Name",
               COLUMN 45, "# Orders",
               COLUMN 60, "# Items",
               COLUMN 75, "Total Amount"
         PRINT COLUMN 1, "-----------------------------------------------------------------------"

      ON EVERY ROW
         PRINT COLUMN 1,  r.employeeid USING "##&",
               COLUMN 5, r.lastname CLIPPED,
               COLUMN 25, r.firstname CLIPPED,
               COLUMN 45, r.orderscount USING "####&",
               COLUMN 60, r.orderdetailscount USING "####&",
               COLUMN 75, r.totalamount USING "###,##&.&&"

      ON LAST ROW
         SKIP 1 LINE
         PRINT COLUMN 1, "======================================================================="
         PRINT COLUMN 45, "Grand Totals:",
               COLUMN 45, SUM(r.orderscount) USING "####&",
               COLUMN 60, SUM(r.orderdetailscount) USING "####&",
               COLUMN 75, SUM(r.totalamount) USING "$###,###,##&.&&"
         PRINT COLUMN 1, "======================================================================="
         PRINT COLUMN 1, "Total Employees: ", COUNT(*) USING "###,##&"

END REPORT #rpt_employees_totals
