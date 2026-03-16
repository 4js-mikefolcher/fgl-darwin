IMPORT FGL main_lib
IMPORT FGL report_helper
DATABASE northwind

-- =====================================================================
-- Report: Products By Category
-- Shows total sales amount for each product, grouped by category.
-- Subtotals per category, grand total overall.
-- Uses Genero REPORT engine for output.
-- =====================================================================

TYPE t_rpt_prod_cat_rec RECORD
   categoryname LIKE categories.categoryname,
   productname LIKE products.productname,
   ordercount INTEGER,
   totalqty INTEGER,
   totalamt FLOAT
END RECORD

DEFINE m_prod_count INTEGER

-- =====================================================================
-- Function: run_products_by_category
-- Purpose : Main entry point for Products By Category report
-- =====================================================================
FUNCTION run_products_by_category()
   DEFINE where_clause STRING
   DEFINE done SMALLINT

   LET done = FALSE

   OPEN WINDOW rptProdCatWindow WITH FORM "rpt_products_by_category"
      ATTRIBUTES(BORDER, STYLE="noactions")

   WHILE NOT done
      LET int_flag = FALSE

      CONSTRUCT BY NAME where_clause
         ON categories.categoryname, products.productname

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
      CALL execute_prod_cat_report(where_clause)

   END WHILE

   CLOSE WINDOW rptProdCatWindow

END FUNCTION #run_products_by_category

-- =====================================================================
-- Function: execute_prod_cat_report
-- Purpose : Run the report using REPORT engine
-- =====================================================================
FUNCTION execute_prod_cat_report(where_clause)
   DEFINE where_clause STRING
   DEFINE r t_rpt_prod_cat_rec
   DEFINE sql_stmt STRING
   DEFINE rpt_file STRING

   LET m_prod_count = 0
   LET rpt_file = generate_temp_filename("rpt_prod_cat", "txt")

   LET sql_stmt = "SELECT categories.categoryname, products.productname,",
                  " COUNT(DISTINCT order_details.orderid),",
                  " SUM(order_details.quantity),",
                  " SUM(order_details.unitprice * order_details.quantity * (1 + order_details.discount))",
                  " FROM order_details, products, categories",
                  " WHERE order_details.productid = products.productid",
                  " AND products.categoryid = categories.categoryid",
                  " AND ", where_clause CLIPPED,
                  " GROUP BY categories.categoryname, products.productname",
                  " ORDER BY categories.categoryname, products.productname"

   PREPARE p_rpt_prod_cat FROM sql_stmt
   DECLARE c_rpt_prod_cat CURSOR FOR p_rpt_prod_cat

   START REPORT rpt_products_category TO FILE rpt_file

   FOREACH c_rpt_prod_cat INTO r.categoryname, r.productname,
      r.ordercount, r.totalqty, r.totalamt
      LET m_prod_count = m_prod_count + 1
      OUTPUT TO REPORT rpt_products_category(r)
   END FOREACH

   FINISH REPORT rpt_products_category

   IF m_prod_count == 0 THEN
      MESSAGE "No data found for the selected criteria."
   ELSE
      MESSAGE SFMT("%1 records written to %2", m_prod_count, rpt_file)
      CALL display_report_file(rpt_file)
   END IF

END FUNCTION #execute_prod_cat_report

-- =====================================================================
-- Report: rpt_products_category
-- Purpose : Format the Products By Category report output
-- =====================================================================
REPORT rpt_products_category(r)
   DEFINE r t_rpt_prod_cat_rec

   OUTPUT
      PAGE LENGTH 66
      LEFT MARGIN 1

   ORDER EXTERNAL BY r.categoryname, r.productname

   FORMAT

      FIRST PAGE HEADER
         PRINT COLUMN 1, "======================================================================="
         PRINT COLUMN 1, "Products By Category Report"
         PRINT COLUMN 1, "Date: ", TODAY USING "mm/dd/yyyy"
         PRINT COLUMN 1, "======================================================================="
         SKIP 1 LINE
         PRINT COLUMN 1,  "Category",
               COLUMN 18, "Product",
               COLUMN 50, "# Orders",
               COLUMN 62, "Total Qty",
               COLUMN 76, "Total Sales"
         PRINT COLUMN 1, "-----------------------------------------------------------------------"

      PAGE HEADER
         PRINT COLUMN 1,  "Category",
               COLUMN 18, "Product",
               COLUMN 50, "# Orders",
               COLUMN 62, "Total Qty",
               COLUMN 76, "Total Sales"
         PRINT COLUMN 1, "-----------------------------------------------------------------------"

      BEFORE GROUP OF r.categoryname
         SKIP 1 LINE
         PRINT COLUMN 1, "Category: ", r.categoryname CLIPPED
         PRINT COLUMN 1, "-----------------------------------------------------------------------"

      ON EVERY ROW
         PRINT COLUMN 3,  r.categoryname CLIPPED,
               COLUMN 18, r.productname CLIPPED,
               COLUMN 50, r.ordercount USING "####&",
               COLUMN 62, r.totalqty USING "#####&",
               COLUMN 76, r.totalamt USING "###,##&.&&"

      AFTER GROUP OF r.categoryname
         PRINT COLUMN 18, "---------------------------------------"
         PRINT COLUMN 18, "Category Subtotal:",
               COLUMN 50, GROUP SUM(r.ordercount) USING "####&",
               COLUMN 62, GROUP SUM(r.totalqty) USING "#####&",
               COLUMN 76, GROUP SUM(r.totalamt) USING "$###,##&.&&"

      ON LAST ROW
         SKIP 1 LINE
         PRINT COLUMN 1, "======================================================================="
         PRINT COLUMN 18, "Grand Total:",
               COLUMN 50, SUM(r.ordercount) USING "####&",
               COLUMN 62, SUM(r.totalqty) USING "#####&",
               COLUMN 76, SUM(r.totalamt) USING "$###,###,##&.&&"
         PRINT COLUMN 1, "======================================================================="
         PRINT COLUMN 1, "Total Products: ", COUNT(*) USING "###,##&"

END REPORT #rpt_products_category
