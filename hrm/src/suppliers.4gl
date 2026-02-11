DATABASE northwind

-- =====================================================================
-- Record Type Definitions
-- =====================================================================
TYPE t_supplier RECORD
   supplierid LIKE suppliers.supplierid,
   companyname LIKE suppliers.companyname,
   contactname LIKE suppliers.contactname,
   contacttitle LIKE suppliers.contacttitle,
   address LIKE suppliers.address,
   city LIKE suppliers.city,
   region LIKE suppliers.region,
   postalcode LIKE suppliers.postalcode,
   country LIKE suppliers.country,
   phone LIKE suppliers.phone,
   fax LIKE suppliers.fax,
   homepage LIKE suppliers.homepage
END RECORD

-- =====================================================================
-- Global Variables
-- =====================================================================
DEFINE suppliers_arr DYNAMIC ARRAY OF t_supplier
DEFINE curr_suppliers t_supplier

-- =====================================================================
-- Function: view_supplier
-- Purpose : View a specific supplier record (called from other modules)
-- =====================================================================
FUNCTION view_supplier(supp_id)
   DEFINE supp_id LIKE suppliers.supplierid
   DEFINE where_clause VARCHAR(500)

   IF supp_id IS NULL OR supp_id < 1 THEN
      ERROR "Supplier ID is missing or invalid"
      RETURN
   END IF

   OPEN WINDOW viewSupplierWindow AT 5,5 WITH FORM "suppliers"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   LET where_clause = " suppliers.supplierid = ", supp_id
   CALL load_suppliers(where_clause)

   IF suppliers_arr.getLength() == 0 THEN
      ERROR "Supplier not found"
      CLOSE WINDOW viewSupplierWindow
      RETURN
   END IF

   CALL load_curr_suppliers(1)
   CALL display_curr_suppliers()

   MENU "Supplier View"
      COMMAND "Products" "View Products from this Supplier"
         CALL view_products_for_supplier(curr_suppliers.supplierid)
      COMMAND "Exit" "Quit operation"
         EXIT MENU
   END MENU

   CLOSE WINDOW viewSupplierWindow

END FUNCTION #view_supplier

FUNCTION submenu_suppliers()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)

   CALL query_suppliers()
   IF suppliers_arr.getLength() == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= suppliers_arr.getLength()

       CALL load_curr_suppliers(currentIdx)
       CALL display_curr_suppliers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", suppliers_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Suppliers Management"
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
              IF currentIdx > suppliers_arr.getLength() THEN
                 LET currentIdx = suppliers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = suppliers_arr.getLength()
              EXIT MENU
          COMMAND "Add" "Add a new supplier"
              CALL add_suppliers()
              IF int_flag == FALSE THEN
                 CALL refresh_suppliers(currentIdx, "A")
                 LET currentIdx = suppliers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Modify" "Edit an existing supplier"
              CALL edit_suppliers()
              IF int_flag == FALSE THEN
                 CALL refresh_suppliers(currentIdx, "C")
              END IF
              EXIT MENU
          COMMAND "Delete" "Delete a supplier"
              CALL delete_suppliers()
              IF int_flag == FALSE THEN
                 CALL refresh_suppliers(currentIdx, "D")
                 IF currentIdx > suppliers_arr.getLength() THEN
                    LET currentIdx = suppliers_arr.getLength()
                 END IF
              END IF
              EXIT MENU
          COMMAND "Products" "View Products from this Supplier"
              CALL view_products_for_supplier(curr_suppliers.supplierid)
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

END FUNCTION #submenu_suppliers

FUNCTION query_suppliers()
    DEFINE where_clause VARCHAR(500)

    CLEAR FORM
    CALL clear_curr_suppliers()
    LET int_flag = FALSE
    CONSTRUCT where_clause ON suppliers.supplierid, suppliers.companyname, suppliers.contactname,
                              suppliers.contacttitle, suppliers.address, suppliers.city,
                              suppliers.region, suppliers.postalcode, suppliers.country,
                              suppliers.phone, suppliers.fax, suppliers.homepage
       FROM s_suppliers.*
        ON ACTION accept
            ACCEPT CONSTRUCT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_suppliers()
       CALL clear_suppliers()
       RETURN
    END IF

    CALL load_suppliers(where_clause)

    IF suppliers_arr.getLength() == 0 THEN
        MESSAGE "No suppliers found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_suppliers(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE temp_supplier t_supplier

    LET sql_stmt = " SELECT supplierid, companyname, contactname, contacttitle,",
                   " address, city, region, postalcode, country, phone, fax, homepage",
                   " FROM suppliers",
                   " WHERE ", where_clause CLIPPED, " ORDER BY companyname"

    CALL clear_suppliers()

    PREPARE p_suppliers FROM sql_stmt
    DECLARE c_suppliers CURSOR FOR p_suppliers
    FOREACH c_suppliers INTO temp_supplier.*
        CALL suppliers_arr.appendElement()
        LET suppliers_arr[suppliers_arr.getLength()] = temp_supplier
    END FOREACH
    CALL clear_curr_suppliers()

END FUNCTION

FUNCTION clear_suppliers()
   CALL suppliers_arr.clear()

END FUNCTION #clear_suppliers

FUNCTION add_suppliers()
    DEFINE suppliers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_suppliers()
    INPUT BY NAME curr_suppliers.*
        ATTRIBUTE(UNBUFFERED)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_suppliers("A")
               RETURNING suppliers_valid, valid_msg
            IF NOT suppliers_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Supplier add canceled"
       RETURN
    END IF

    CALL insert_curr_suppliers()
    MESSAGE "Supplier record added"

END FUNCTION

FUNCTION edit_suppliers()
    DEFINE suppliers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    LET int_flag = FALSE
    INPUT BY NAME curr_suppliers.companyname, curr_suppliers.contactname, curr_suppliers.contacttitle,
                  curr_suppliers.address, curr_suppliers.city, curr_suppliers.region,
                  curr_suppliers.postalcode, curr_suppliers.country, curr_suppliers.phone,
                  curr_suppliers.fax, curr_suppliers.homepage
        ATTRIBUTE(UNBUFFERED, WITHOUT DEFAULTS)
        ON ACTION accept
            ACCEPT INPUT
        ON ACTION cancel
            LET int_flag = TRUE
            EXIT INPUT
        AFTER INPUT
            CALL validate_suppliers("C")
               RETURNING suppliers_valid, valid_msg
            IF NOT suppliers_valid THEN
                ERROR valid_msg
                CONTINUE INPUT
            END IF
    END INPUT

    IF int_flag THEN
       ERROR "Supplier update canceled"
       RETURN
    END IF

    CALL update_curr_suppliers()
    MESSAGE "Supplier record updated"

END FUNCTION

FUNCTION delete_suppliers()

    LET int_flag = FALSE
    IF NOT confirm_delete() THEN
        ERROR "Supplier delete canceled"
        LET int_flag = TRUE
        RETURN
    END IF

    CALL delete_curr_suppliers()
    MESSAGE "Supplier record deleted"

END FUNCTION

FUNCTION load_curr_suppliers(currIdx)
   DEFINE currIdx INTEGER

   CALL clear_curr_suppliers()
   IF currIdx > 0 AND currIdx <= suppliers_arr.getLength() THEN
      LET curr_suppliers = suppliers_arr[currIdx]
   END IF

END FUNCTION

FUNCTION display_curr_suppliers()

   DISPLAY BY NAME curr_suppliers.*

END FUNCTION

FUNCTION clear_curr_suppliers()

   INITIALIZE curr_suppliers.* TO NULL

END FUNCTION

FUNCTION insert_curr_suppliers()

   INSERT INTO suppliers (supplierid, companyname, contactname, contacttitle,
                          address, city, region, postalcode, country, phone, fax, homepage)
      VALUES (curr_suppliers.supplierid, curr_suppliers.companyname, curr_suppliers.contactname,
              curr_suppliers.contacttitle, curr_suppliers.address, curr_suppliers.city,
              curr_suppliers.region, curr_suppliers.postalcode, curr_suppliers.country,
              curr_suppliers.phone, curr_suppliers.fax, curr_suppliers.homepage)

END FUNCTION

FUNCTION update_curr_suppliers()

   UPDATE suppliers
      SET companyname = curr_suppliers.companyname,
          contactname = curr_suppliers.contactname,
          contacttitle = curr_suppliers.contacttitle,
          address = curr_suppliers.address,
          city = curr_suppliers.city,
          region = curr_suppliers.region,
          postalcode = curr_suppliers.postalcode,
          country = curr_suppliers.country,
          phone = curr_suppliers.phone,
          fax = curr_suppliers.fax,
          homepage = curr_suppliers.homepage
    WHERE supplierid = curr_suppliers.supplierid

END FUNCTION

FUNCTION delete_curr_suppliers()

   DELETE FROM suppliers
    WHERE supplierid = curr_suppliers.supplierid

END FUNCTION

FUNCTION refresh_suppliers(currIdx, operation)
   DEFINE currIdx INTEGER
   DEFINE operation CHAR(1)
   DEFINE idx INTEGER

   CASE operation
      WHEN "A"
         CALL suppliers_arr.appendElement()
         LET suppliers_arr[suppliers_arr.getLength()] = curr_suppliers
      WHEN "C"
         LET suppliers_arr[currIdx] = curr_suppliers
      WHEN "D"
         FOR idx = 1 TO suppliers_arr.getLength()
            IF suppliers_arr[idx].supplierid = curr_suppliers.supplierid THEN
               CALL suppliers_arr.deleteElement(idx)
               EXIT FOR
            END IF
         END FOR
   END CASE

END FUNCTION #refresh_suppliers

FUNCTION validate_suppliers(mode)
   DEFINE mode CHAR(1)
   DEFINE supplierExists SMALLINT

   SELECT 1 INTO supplierExists FROM suppliers WHERE suppliers.supplierid = curr_suppliers.supplierid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      RETURN FALSE, "Supplier ID is not found"
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      RETURN FALSE, "Supplier ID already exists"
   END IF
   IF curr_suppliers.supplierid IS NULL THEN
      RETURN FALSE, "Supplier ID is required"
   END IF
   IF curr_suppliers.companyname IS NULL OR LENGTH(curr_suppliers.companyname) == 0 THEN
      RETURN FALSE, "Company Name is required"
   END IF

   RETURN TRUE, "Okay"
END FUNCTION

-- =====================================================================
-- Function: supplier_lookup
-- Purpose : Open a lookup window for supplier selection
-- =====================================================================
FUNCTION supplier_lookup()
   DEFINE supp_id LIKE suppliers.supplierid
   DEFINE supp_name LIKE suppliers.companyname

   OPEN WINDOW lookupWindow AT 5,5 WITH FORM "suppliers"
      ATTRIBUTES(BORDER, MESSAGE LINE LAST, ERROR LINE LAST)

   CALL supplier_lookup_menu()
      RETURNING supp_id, supp_name

   CLOSE WINDOW lookupWindow

   RETURN supp_id, supp_name

END FUNCTION #supplier_lookup

FUNCTION supplier_lookup_menu()
   DEFINE currentIdx INTEGER
   DEFINE statusMessage CHAR(60)
   DEFINE selectedIdx INTEGER

   CALL query_suppliers()
   IF suppliers_arr.getLength() == 0 THEN
      RETURN 0, ""
   END IF

   LET currentIdx = 1
   LET selectedIdx = 0
   WHILE currentIdx > 0 AND currentIdx <= suppliers_arr.getLength() AND selectedIdx == 0

       CALL load_curr_suppliers(currentIdx)
       CALL display_curr_suppliers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", suppliers_arr.getLength() USING "<<<<"
       MESSAGE statusMessage

       MENU "Supplier Selection"
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
              IF currentIdx > suppliers_arr.getLength() THEN
                 LET currentIdx = suppliers_arr.getLength()
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = suppliers_arr.getLength()
              EXIT MENU
          COMMAND "Select" "Select the current supplier"
              LET selectedIdx = currentIdx
              CALL load_curr_suppliers(selectedIdx)
              EXIT MENU
          COMMAND "Exit" "Quit operation"
              LET currentIdx = 0
              EXIT MENU
       END MENU

   END WHILE

   IF selectedIdx > 0 THEN
      RETURN curr_suppliers.supplierid, curr_suppliers.companyname
   END IF

   RETURN 0, ""

END FUNCTION #supplier_lookup_menu
