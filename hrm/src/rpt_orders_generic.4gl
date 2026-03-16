IMPORT FGL main_lib
IMPORT FGL report_helper
DATABASE northwind

-- =====================================================================
-- Report: Generic Order Report (XML Output)
-- Produces XML output using PRINTX for all order-related data.
-- The CONSTRUCT dialog allows querying on orders, customers,
-- employees, products, and order detail fields.
-- =====================================================================

TYPE t_order_xml_rec RECORD
   -- Order header
   orderid       LIKE orders.orderid,
   customerid    LIKE orders.customerid,
   orderdate     LIKE orders.orderdate,
   requireddate  LIKE orders.requireddate,
   shippeddate   LIKE orders.shippeddate,
   shipvia       LIKE orders.shipvia,
   freight       LIKE orders.freight,
   shipname      LIKE orders.shipname,
   shipaddress   LIKE orders.shipaddress,
   shipcity      LIKE orders.shipcity,
   shipregion    LIKE orders.shipregion,
   shippostalcode LIKE orders.shippostalcode,
   shipcountry   LIKE orders.shipcountry,
   -- Customer
   companyname   LIKE customers.companyname,
   contactname   LIKE customers.contactname,
   contacttitle  LIKE customers.contacttitle,
   -- Employee
   employeeid    LIKE employees.employeeid,
   lastname      LIKE employees.lastname,
   firstname     LIKE employees.firstname,
   title         LIKE employees.title,
   -- Product / Detail
   productid     LIKE products.productid,
   productname   LIKE products.productname,
   unitprice     LIKE order_details.unitprice,
   quantity      LIKE order_details.quantity,
   discount      LIKE order_details.discount,
   linetotal     FLOAT
END RECORD

DEFINE m_row_count INTEGER

-- =====================================================================
-- Function: run_orders_generic
-- Purpose : Main entry point for the Generic Order Report (XML)
-- =====================================================================
FUNCTION run_orders_generic()
   DEFINE where_clause STRING
   DEFINE done SMALLINT

   LET done = FALSE

   OPEN WINDOW rptGenericWindow WITH FORM "rpt_orders_generic"
      ATTRIBUTES(STYLE="modulewindow")

   WHILE NOT done
      LET int_flag = FALSE

      CONSTRUCT BY NAME where_clause
         ON orders.orderid, orders.orderdate, orders.requireddate,
            orders.shippeddate, orders.freight, orders.shipvia,
            orders.shipname, orders.shipcity, orders.shipregion,
            orders.shipcountry, orders.shippostalcode,
            customers.customerid, customers.companyname,
            customers.contactname,
            employees.employeeid, employees.lastname,
            employees.firstname,
            order_details.productid, products.productname

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

      -- Execute the XML report
      CALL execute_generic_report(where_clause)

   END WHILE

   CLOSE WINDOW rptGenericWindow

END FUNCTION #run_orders_generic

-- =====================================================================
-- Function: execute_generic_report
-- Purpose : Query all order-related data and output as XML via PRINTX
-- =====================================================================
FUNCTION execute_generic_report(where_clause)
   DEFINE where_clause STRING
   DEFINE r t_order_xml_rec
   DEFINE sql_stmt STRING
   DEFINE rpt_file STRING

   LET m_row_count = 0
   LET rpt_file = generate_temp_filename("rpt_orders_xml", "xml")

   LET sql_stmt = "SELECT orders.orderid, orders.customerid,",
                  " orders.orderdate, orders.requireddate, orders.shippeddate,",
                  " orders.shipvia, orders.freight,",
                  " orders.shipname, orders.shipaddress, orders.shipcity,",
                  " orders.shipregion, orders.shippostalcode, orders.shipcountry,",
                  " customers.companyname, customers.contactname, customers.contacttitle,",
                  " employees.employeeid, employees.lastname, employees.firstname, employees.title,",
                  " products.productid, products.productname,",
                  " order_details.unitprice, order_details.quantity, order_details.discount,",
                  " order_details.unitprice * order_details.quantity * (1 + order_details.discount)",
                  " FROM orders",
                  " INNER JOIN customers ON orders.customerid = customers.customerid",
                  " INNER JOIN employees ON orders.employeeid = employees.employeeid",
                  " INNER JOIN order_details ON order_details.orderid = orders.orderid",
                  " INNER JOIN products ON products.productid = order_details.productid",
                  " WHERE ", where_clause CLIPPED,
                  " ORDER BY orders.orderid, products.productname"

   PREPARE p_rpt_generic FROM sql_stmt
   DECLARE c_rpt_generic CURSOR FOR p_rpt_generic

   START REPORT rpt_orders_xml TO XML HANDLER om.XmlWriter.createFileWriter(rpt_file)

   FOREACH c_rpt_generic INTO r.orderid, r.customerid,
      r.orderdate, r.requireddate, r.shippeddate,
      r.shipvia, r.freight,
      r.shipname, r.shipaddress, r.shipcity,
      r.shipregion, r.shippostalcode, r.shipcountry,
      r.companyname, r.contactname, r.contacttitle,
      r.employeeid, r.lastname, r.firstname, r.title,
      r.productid, r.productname,
      r.unitprice, r.quantity, r.discount,
      r.linetotal
      LET m_row_count = m_row_count + 1
      OUTPUT TO REPORT rpt_orders_xml(r)
   END FOREACH

   FINISH REPORT rpt_orders_xml

   IF m_row_count == 0 THEN
      MESSAGE "No orders found for the selected criteria."
   ELSE
      MESSAGE SFMT("%1 records written to %2", m_row_count, rpt_file)
      CALL display_report_file(rpt_file)
   END IF

END FUNCTION #execute_generic_report

-- =====================================================================
-- Report: rpt_orders_xml
-- Purpose : Format the Generic Order Report as XML using PRINTX
-- =====================================================================
REPORT rpt_orders_xml(r)
   DEFINE r t_order_xml_rec

   ORDER EXTERNAL BY r.orderid

   FORMAT

      ON EVERY ROW
         PRINTX NAME = order r.*

END REPORT #rpt_orders_xml
