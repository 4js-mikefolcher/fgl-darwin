IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_supplier RECORD
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

PRIVATE CONSTANT cMessagePrefix = "Supplier Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current supplier record
-- =====================================================================
PUBLIC FUNCTION (self t_supplier) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE supplierExists SMALLINT
   DEFINE valid_rec t_valid_rec

   IF mode == "C" THEN
      SELECT 1 INTO supplierExists FROM suppliers WHERE suppliers.supplierid = self.supplierid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Supplier ID is not found")
         RETURN valid_rec
      END IF
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
-- Purpose : Insert the supplier record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_supplier) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO suppliers (supplierid, companyname, contactname, contacttitle,
                          address, city, region, postalcode, country, phone, fax, homepage)
      VALUES (DEFAULT, self.companyname, self.contactname,
              self.contacttitle, self.address, self.city,
              self.region, self.postalcode, self.country,
              self.phone, self.fax, self.homepage)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
      LET self.supplierid = sqlca.sqlerrd[2]
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: updateRec
-- Purpose : Update the supplier record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_supplier) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE suppliers
      SET companyname = self.companyname,
          contactname = self.contactname,
          contacttitle = self.contacttitle,
          address = self.address,
          city = self.city,
          region = self.region,
          postalcode = self.postalcode,
          country = self.country,
          phone = self.phone,
          fax = self.fax,
          homepage = self.homepage
    WHERE supplierid = self.supplierid

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
-- Purpose : Delete the supplier record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_supplier) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM suppliers
    WHERE supplierid = self.supplierid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec
