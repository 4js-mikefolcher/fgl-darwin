IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_customer RECORD
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

PRIVATE CONSTANT cMessagePrefix = "Customer Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current customer record
-- =====================================================================
PUBLIC FUNCTION (self t_customer) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE customerExists SMALLINT
   DEFINE valid_rec t_valid_rec

   SELECT 1 INTO customerExists FROM customers WHERE customers.customerid = self.customerid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      CALL valid_rec.failed("Customer ID is not found")
      RETURN valid_rec
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      CALL valid_rec.failed("Customer ID already exists")
      RETURN valid_rec
   END IF
   IF self.customerid IS NULL OR LENGTH(self.customerid) == 0 THEN
      CALL valid_rec.failed("Customer ID is required")
      RETURN valid_rec
   END IF
   IF self.companyname IS NULL OR LENGTH(self.companyname) == 0 THEN
      CALL valid_rec.failed("Company Name is required")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the customer record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_customer) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO customers (customerid, companyname, contactname, contacttitle,
                          address, city, region, postalcode, country, phone, fax)
      VALUES (self.customerid, self.companyname, self.contactname,
              self.contacttitle, self.address, self.city,
              self.region, self.postalcode, self.country,
              self.phone, self.fax)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: updateRec
-- Purpose : Update the customer record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_customer) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE customers
      SET companyname = self.companyname,
          contactname = self.contactname,
          contacttitle = self.contacttitle,
          address = self.address,
          city = self.city,
          region = self.region,
          postalcode = self.postalcode,
          country = self.country,
          phone = self.phone,
          fax = self.fax
    WHERE customerid = self.customerid

   CALL upd_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL upd_status.success(SFMT(cMessagePrefix, "updated"))
   ELSE
      CALL upd_status.failed(SFMT(cMessagePrefix, "update failed"))
   END IF
   RETURN upd_status

END FUNCTION #updateRec

-- =====================================================================
-- Function: deleteRec
-- Purpose : Delete the customer record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_customer) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM customers
    WHERE customerid = self.customerid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec

-- =====================================================================
-- Function: validate_customer (PUBLIC)
-- =====================================================================
PUBLIC FUNCTION validate_customer(customerid LIKE customers.customerid) RETURNS (t_valid_rec)
   DEFINE customer_name STRING
   DEFINE valid_status t_valid_rec

   IF customerid IS NOT NULL AND LENGTH(customerid) > 0 THEN
      SELECT companyname INTO customer_name FROM customers WHERE customers.customerid = $customerid
      IF sqlca.sqlcode == 0 THEN
         CALL valid_status.success(customer_name)
      ELSE
         CALL valid_status.failed("Customer ID does not exist in customers table")
      END IF
   ELSE
      CALL valid_status.success("")
   END IF
   RETURN valid_status

END FUNCTION #validate_customer
