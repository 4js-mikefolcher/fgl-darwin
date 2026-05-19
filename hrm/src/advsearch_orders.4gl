PUBLIC FUNCTION advsearch_orders() RETURNS (STRING)
   DEFINE where_clause STRING

   OPEN WINDOW advsearch_window WITH FORM "advsearch_orders"

   LET int_flag = FALSE

   CONSTRUCT where_clause 
      ON orders.orderid, orders.customerid, customers.companyname,
         orders.employeeid, employees.firstname, employees.lastname,
         orders.orderdate, orders.requireddate, orders.shippeddate,
         orders.shipvia, orders.freight, orders.shipname, orders.shipaddress,
         orders.shipcity,orders.shipregion,orders.shippostalcode, orders.shipcountry
      FROM s_advsearch.*
      ATTRIBUTES(CANCEL = FALSE, ACCEPT = FALSE)

      ON ACTION cancel_search
         LET int_flag = TRUE
         EXIT CONSTRUCT

      ON ACTION do_search
         ACCEPT CONSTRUCT

   END CONSTRUCT

   CLOSE WINDOW advsearch_window

   IF int_flag THEN
      LET where_clause = ""
      LET int_flag = FALSE
   END IF

   RETURN where_clause

END FUNCTION #advsearch_orders