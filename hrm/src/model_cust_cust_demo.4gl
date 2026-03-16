IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_cust_cust_demo RECORD
   customerid LIKE customers.customerid,
   companyname LIKE customers.companyname,
   customertypeid LIKE customerdemographics.customertypeid,
   customerdesc LIKE customerdemographics.customerdesc
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Customer Customer Demo Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current customer customer demo record
-- =====================================================================
PUBLIC FUNCTION (self t_cust_cust_demo) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE exists_count SMALLINT
   DEFINE valid_rec t_valid_rec

   IF self.customerid IS NULL OR LENGTH(self.customerid) == 0 THEN
      CALL valid_rec.failed("Customer ID is required")
      RETURN valid_rec
   END IF
   IF self.customertypeid IS NULL OR LENGTH(self.customertypeid) == 0 THEN
      CALL valid_rec.failed("Customer Type ID is required")
      RETURN valid_rec
   END IF

   -- Check for duplicate assignment
   SELECT COUNT(*) INTO exists_count
      FROM customercustomerdemo
      WHERE customerid = self.customerid
        AND customertypeid = self.customertypeid
   IF exists_count > 0 THEN
      CALL valid_rec.failed("This customer is already assigned to this type")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: validateCustomer
-- Purpose : Validate a customer ID and return the company name
-- =====================================================================
PUBLIC FUNCTION (self t_cust_cust_demo) validateCustomer() RETURNS (t_valid_rec)
   DEFINE valid_rec t_valid_rec

   SELECT companyname INTO self.companyname
      FROM customers
      WHERE customers.customerid = self.customerid
   IF sqlca.sqlcode == NOTFOUND THEN
      CALL valid_rec.failed("Customer ID is not found")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Customer found")
   RETURN valid_rec

END FUNCTION #validateCustomer

-- =====================================================================
-- Function: validateCustomerType
-- Purpose : Validate a customer type ID and return the description
-- =====================================================================
PUBLIC FUNCTION (self t_cust_cust_demo) validateCustomerType() RETURNS (t_valid_rec)
   DEFINE valid_rec t_valid_rec

   SELECT customerdesc INTO self.customerdesc
      FROM customerdemographics
      WHERE customerdemographics.customertypeid = self.customertypeid
   IF sqlca.sqlcode == NOTFOUND THEN
      CALL valid_rec.failed("Customer Type ID is not found")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Customer Type found")
   RETURN valid_rec

END FUNCTION #validateCustomerType

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the customer customer demo record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_cust_cust_demo) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO customercustomerdemo (customerid, customertypeid)
      VALUES (self.customerid, self.customertypeid)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: deleteRec
-- Purpose : Delete the customer customer demo record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_cust_cust_demo) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM customercustomerdemo
    WHERE customerid = self.customerid
      AND customertypeid = self.customertypeid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec
