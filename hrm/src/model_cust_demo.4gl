IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_cust_demo RECORD
   customertypeid LIKE customerdemographics.customertypeid,
   customerdesc LIKE customerdemographics.customerdesc
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Customer Demographics Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current customer demographics record
-- =====================================================================
PUBLIC FUNCTION (self t_cust_demo) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE demoExists SMALLINT
   DEFINE valid_rec t_valid_rec

   IF self.customertypeid IS NULL OR LENGTH(self.customertypeid) == 0 THEN
      CALL valid_rec.failed("Customer Type ID is required")
      RETURN valid_rec
   END IF

   IF mode == "A" THEN
      SELECT 1 INTO demoExists FROM customerdemographics
       WHERE customerdemographics.customertypeid = self.customertypeid
      IF sqlca.sqlcode != NOTFOUND THEN
         CALL valid_rec.failed("Customer Type ID already exists")
         RETURN valid_rec
      END IF
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the customer demographics record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_cust_demo) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO customerdemographics (customertypeid, customerdesc)
      VALUES (self.customertypeid, self.customerdesc)

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
-- Purpose : Update the customer demographics record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_cust_demo) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE customerdemographics
      SET customerdesc = self.customerdesc
    WHERE customertypeid = self.customertypeid

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
-- Purpose : Delete the customer demographics record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_cust_demo) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM customerdemographics
    WHERE customertypeid = self.customertypeid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec
