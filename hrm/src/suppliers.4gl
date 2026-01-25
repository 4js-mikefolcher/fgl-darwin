DATABASE northwind

DEFINE suppliers_arr ARRAY[1000] OF RECORD
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

DEFINE curr_suppliers RECORD
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

DEFINE arr_size INTEGER
DEFINE arr_max INTEGER

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

   LET arr_max = 1000
   LET where_clause = " suppliers.supplierid = ", supp_id
   CALL load_suppliers(where_clause)

   IF arr_size == 0 THEN
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

   LET arr_max = 1000
   CALL query_suppliers()
   IF arr_size == 0 THEN
      RETURN
   END IF

   LET currentIdx = 1
   WHILE currentIdx > 0 AND currentIdx <= arr_size

       CALL load_curr_suppliers(currentIdx)
       CALL display_curr_suppliers()
       LET statusMessage = "Viewing ", currentIdx USING "<<<<", " of ", arr_size USING "<<<<"
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
              IF currentIdx > arr_size THEN
                 LET currentIdx = arr_size
              END IF
              EXIT MENU
          COMMAND "Last" "View last record in result set"
              LET currentIdx = arr_size
              EXIT MENU
          COMMAND "Add" "Add a new supplier"
              CALL add_suppliers()
              IF int_flag == FALSE THEN
                 CALL refresh_suppliers(currentIdx, "A")
                 LET currentIdx = arr_size
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
                 IF currentIdx > arr_size THEN
                    LET currentIdx = arr_size
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
        ON KEY (ACCEPT)
            ACCEPT CONSTRUCT
        ON KEY (CONTROL-P)
            LET int_flag = TRUE
            EXIT CONSTRUCT
    END CONSTRUCT

    IF int_flag THEN
       CALL clear_curr_suppliers()
       CALL clear_suppliers()
       RETURN
    END IF

    CALL load_suppliers(where_clause)

    IF arr_size == 0 THEN
        MESSAGE "No suppliers found."
        RETURN
    END IF

END FUNCTION

FUNCTION load_suppliers(where_clause)
    DEFINE where_clause VARCHAR(500)
    DEFINE sql_stmt VARCHAR(1024)
    DEFINE idx INTEGER

    LET sql_stmt = " SELECT supplierid, companyname, contactname, contacttitle,",
                   " address, city, region, postalcode, country, phone, fax, homepage",
                   " FROM suppliers",
                   " WHERE ", where_clause CLIPPED, " ORDER BY companyname"

    CALL clear_suppliers()

    LET idx = 0
    PREPARE p_suppliers FROM sql_stmt
    DECLARE c_suppliers CURSOR FOR p_suppliers
    FOREACH c_suppliers INTO curr_suppliers.*
        LET idx = idx + 1
        LET suppliers_arr[idx] = curr_suppliers
    END FOREACH
    CALL clear_curr_suppliers()
    LET arr_size = idx

END FUNCTION

FUNCTION clear_suppliers()
   DEFINE idx INTEGER

   FOR idx = 1 TO arr_max
      INITIALIZE suppliers_arr[idx].* TO NULL
   END FOR
   LET arr_size = 0

END FUNCTION #clear_suppliers

FUNCTION add_suppliers()
    DEFINE suppliers_valid SMALLINT
    DEFINE valid_msg CHAR(75)

    CLEAR FORM
    LET int_flag = FALSE
    CALL clear_curr_suppliers()
    INPUT BY NAME curr_suppliers.*
        ATTRIBUTE(UNBUFFERED)
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
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
        ON KEY (ACCEPT)
            ACCEPT INPUT
        ON KEY (CONTROL-P)
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
    DEFINE answer CHAR(1)

    LET int_flag = FALSE
    PROMPT "Are you sure you want to delete this record? (Y/N)" FOR answer
    IF answer != "Y" THEN
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
   IF currIdx > 0 AND currIdx <= arr_size THEN
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
   DEFINE newIdx INTEGER
   DEFINE idx INTEGER
   DEFINE replaceRec SMALLINT

   CASE operation
      WHEN "A"
         LET newIdx = arr_size + 1
         LET suppliers_arr[newIdx] = curr_suppliers
         LET arr_size = newIdx
      WHEN "C"
         LET suppliers_arr[currIdx] = curr_suppliers
      WHEN "D"
           LET newIdx = 0
           LET replaceRec = FALSE

           FOR idx = 1 TO arr_size
              IF suppliers_arr[idx].supplierid = curr_suppliers.supplierid THEN
                 LET replaceRec = TRUE
                 CONTINUE FOR
              END IF
              LET newIdx = newIdx + 1
              LET suppliers_arr[newIdx] = suppliers_arr[idx]
           END FOR

           IF replaceRec THEN
              INITIALIZE suppliers_arr[arr_size].* TO NULL
              LET arr_size = arr_size - 1
           END IF
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
