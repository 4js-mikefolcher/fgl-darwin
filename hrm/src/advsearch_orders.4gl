PUBLIC FUNCTION advsearch_orders() RETURNS (STRING)
   DEFINE where_clause STRING

   OPEN WINDOW advsearch_window WITH FORM "advsearch_orders"

   LET int_flag = FALSE

   -- BY NAME resolves screen-field -> column via the form's ATTRIBUTES
   -- section. UI module lists only form field names; the table.column
   -- bindings live in advsearch_orders.per.
   CONSTRUCT BY NAME where_clause
      ON orderid, customerid, companyname,
         employeeid, firstname, lastname,
         orderdate, requireddate, shippeddate,
         shipvia, freight, shipname, shipaddress,
         shipcity, shipregion, shippostalcode, shipcountry
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