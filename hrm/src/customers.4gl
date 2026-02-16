DATABASE northwind

-- =====================================================================
-- Record Type Definitions
-- =====================================================================
TYPE t_customer RECORD
   customerid LIKE customers.customerid,
   companyname LIKE customers.companyname,
   contactname LIKE customers.contactname,
   contacttitle LIKE customers.contacttitle,
   address LIKE customers.address,
   city LIKE customers.city,
   region LIKE customers.region,
   postalcode LIKE customers.postalcode,
   country LIKE customers.country,
   phone LIKE customers.phone,
   fax LIKE customers.fax
END RECORD

-- =====================================================================
-- Global Variables
-- =====================================================================
DEFINE customers_arr DYNAMIC ARRAY OF t_customer
DEFINE curr_customers t_customer

-- =====================================================================
-- Function: view_customer
-- Purpose : View a specific customer record (called from other modules)
-- =====================================================================
FUNCTION view_customer(cust_id)
   DEFINE cust_id LIKE customers.customerid
   DEFINE where_clause VARCHAR(500)

   IF cust_id IS NULL OR LENGTH(cust_id) == 0 THEN
      ERROR "Customer ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewCustomerWindow WITH FORM "customers"
      ATTRIBUTES(STYLE="modulewindow")

   LET where_clause = " customers.customerid = '", cust_id CLIPPED, "'"
   CALL load_customers(where_clause)

   IF customers_arr.getLength() == 0 THEN
      CLOSE WINDOW viewCustomerWindow
      ERROR "Customer not found"
      RETURN
   END IF

   CALL load_curr_customers(1)
   CALL display_curr_customers()

   MENU "Customer View"
      COMMAND "Orders" "View Orders for this Customer"
         CALL view_orders_for_customer(curr_customers.customerid)
      COMMAND "Exit" "Quit operation"
         EXIT MENU
   END MENU

   CLOSE WINDOW viewCustomerWindow

END FUNCTION #view_customer

FUNCTION submenu_customers()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL query_customers()
   IF customers_arr.getLength() == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= customers_arr.getLength()

       CALL load_curr_customers(currentIdx)
       CALL display_curr_customers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", customers_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Customers Management"
          COMMAND "First" "View first record in result set"
              LET currentIdx = 1
              EXIT MENU
          COMMAND "Previous" "View previous record in result set"
              LET currentIdx = currentIdx - 1
              IF currentIdx < 1 THEN
                 LET currentIdx = 1
              END IF
              EXIT MENU
          COMMAND "Next" "View next record in result set"
              LET currentIdx = currentIdx + 1
              IF currentIdx > customers_arr.getLength() THEN
                 LET currentIdx = customers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = customers_arr.getLength()
              EXIT MENU
          COMMAND "Add" "Add a new customer"
              CALL add_customers()
              IF int_flag == FALSE THEN
                 CALL refresh_customers(currentIdx, "A")
                 LET currentIdx = customers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing customer"
              CALL edit_customers()
              IF int_flag == FALSE THEN
                 CALL refresh_customers(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete a customer"
              CALL delete_customers()
              IF int_flag == FALSE THEN
                 CALL refresh_customers(currentIdx, "D")
                 IF currentIdx > customers_arr.getLength() THEN
                    LET currentIdx = customers_arr.getLength()
                 END IF
              END IF
              EXIT MENU
          COMMAND "Orders" "View Orders for this Customer"
              CALL view_orders_for_customer(curr_customers.customerid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_customers

FUNCTION query_customers()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_customers()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON customers.customerid, customers.companyname, customers.contactname,
                              customers.contacttitle, customers.address, customers.city,
                              customers.region, customers.postalcode, customers.country,
                              customers.phone, customers.fax
       FROM s_customers.*
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_customers()
       CALL clear_customers()
       RETURN
    END IF

    CALL load_customers(where_clause)

    IF customers_arr.getLength() == 0 THEN
        MESSAGE "No customers found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_customers(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE temp_customer t_customer

    LET sql_stmt = " SELECT customerid, companyname, contactname, contacttitle,",
                   " address, city, region, postalcode, country, phone, fax",
                   " FROM customers",
                   " WHERE ", where_clause CLIPPED, " ORDER BY companyname"

    CALL clear_customers()

    PREPARE p_customers FROM sql_stmt
    DECLARE c_customers CURSOR FOR p_customers
    FOREACH c_customers INTO temp_customer.*
        CALL customers_arr.appendElement()
        LET customers_arr[customers_arr.getLength()] = temp_customer
    END FOREACH
    CALL clear_curr_customers()

END FUNCTION

FUNCTION clear_customers()
   CALL customers_arr.clear()

END FUNCTION #clear_customers

FUNCTION add_customers()
    DEFINE customers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_customers()
    INPUT BY NAME curr_customers.*
        ATTRIBUTE(UNBUFFERED)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_customers("A")
               RETURNING customers_valid, valid_msg
            IF NOT customers_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Customer add canceled"
       RETURN
    END IF

    CALL insert_curr_customers()
    MESSAGE "Customer record added"

END FUNCTION

FUNCTION edit_customers()
    DEFINE customers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_customers.companyname, curr_customers.contactname, curr_customers.contacttitle,
                  curr_customers.address, curr_customers.city, curr_customers.region,
                  curr_customers.postalcode, curr_customers.country, curr_customers.phone, curr_customers.fax
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_customers("C")
               RETURNING customers_valid, valid_msg
            IF NOT customers_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Customer update canceled"
       RETURN
    END IF

    CALL update_curr_customers()
    MESSAGE "Customer record updated"

END FUNCTION

FUNCTION delete_customers()

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
        ERROR "Customer delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_customers()
    MESSAGE "Customer record deleted"

END FUNCTION

FUNCTION load_curr_customers(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_customers()
   IF currIdx > 0 AND currIdx <= customers_arr.getLength() THEN
      LET curr_customers = customers_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_customers()

   DISPLAY BY NAME curr_customers.*

END FUNCTION

FUNCTION clear_curr_customers()

   INITIALIZE curr_customers.* TO NULL

END FUNCTION

FUNCTION insert_curr_customers()

   INSERT INTO customers (customerid, companyname, contactname, contacttitle,
                          address, city, region, postalcode, country, phone, fax)
      VALUES (curr_customers.customerid, curr_customers.companyname, curr_customers.contactname,
              curr_customers.contacttitle, curr_customers.address, curr_customers.city,
              curr_customers.region, curr_customers.postalcode, curr_customers.country,
              curr_customers.phone, curr_customers.fax)

END FUNCTION

FUNCTION update_curr_customers()

   UPDATE customers
      SET companyname = curr_customers.companyname,
          contactname = curr_customers.contactname,
          contacttitle = curr_customers.contacttitle,
          address = curr_customers.address,
          city = curr_customers.city,
          region = curr_customers.region,
          postalcode = curr_customers.postalcode,
          country = curr_customers.country,
          phone = curr_customers.phone,
          fax = curr_customers.fax
    WHERE customerid = curr_customers.customerid

END FUNCTION

FUNCTION delete_curr_customers()

   DELETE FROM customers
    WHERE customerid = curr_customers.customerid

END FUNCTION

FUNCTION refresh_customers(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL customers_arr.appendElement()
         LET customers_arr[customers_arr.getLength()] = curr_customers
      WHEN "C"
         LET customers_arr[currIdx] = curr_customers
      WHEN "D"
         FOR idx = 1 TO customers_arr.getLength()
            IF customers_arr[idx].customerid = curr_customers.customerid THEN
               CALL customers_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #refresh_customers

FUNCTION validate_customers(mode)
   DEFINE mode CHAR(1)
   DEFINE customerExists SMALLINT

   SELECT 1 INTO customerExists FROM customers WHERE customers.customerid = curr_customers.customerid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      RETURN FALSE, "Customer ID is not found"
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      RETURN FALSE, "Customer ID already exists"
   END IF
   IF curr_customers.customerid IS NULL OR LENGTH(curr_customers.customerid) == 0 THEN
      RETURN FALSE, "Customer ID is required"
   END IF
   IF curr_customers.companyname IS NULL OR LENGTH(curr_customers.companyname) == 0 THEN
      RETURN FALSE, "Company Name is required"
   END IF

   RETURN TRUE, "Okay"
END FUNCTION

-- =====================================================================
-- Function: customer_lookup
-- Purpose : Open a lookup window for customer selection
-- =====================================================================
FUNCTION customer_lookup()
   DEFINE cust_id LIKE customers.customerid
   DEFINE cust_name LIKE customers.companyname

   OPEN WINDOW lookupWindow WITH FORM "customers"
      ATTRIBUTES(STYLE="modulewindow")

   CALL customer_lookup_menu()
      RETURNING cust_id, cust_name

   CLOSE WINDOW lookupWindow

   RETURN cust_id, cust_name

END FUNCTION #customer_lookup

FUNCTION customer_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL query_customers()
   IF customers_arr.getLength() == 0 THEN
      RETURN "", ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= customers_arr.getLength() AND selectedIdx == 0

       CALL load_curr_customers(currentIdx)
       CALL display_curr_customers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", customers_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Customer Selection"
          COMMAND "First" "View first record in result set"
              LET currentIdx = 1
              EXIT MENU
          COMMAND "Previous" "View previous record in result set"
              LET currentIdx = currentIdx - 1
              IF currentIdx < 1 THEN
                 LET currentIdx = 1
              END IF
              EXIT MENU
          COMMAND "Next" "View next record in result set"
              LET currentIdx = currentIdx + 1
              IF currentIdx > customers_arr.getLength() THEN
                 LET currentIdx = customers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = customers_arr.getLength()
              EXIT MENU
          COMMAND "Select" "Select the current customer"
              LET selectedIdx = currentIdx
              CALL load_curr_customers(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_customers.customerid, curr_customers.companyname
   END IF

   RETURN "", ""

END FUNCTION
