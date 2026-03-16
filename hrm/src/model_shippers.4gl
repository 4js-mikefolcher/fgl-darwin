IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_shipper RECORD
   shipperid SMALLINT,
   companyname VARCHAR(40),
   phone VARCHAR(24)
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Shipper Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current shipper record
-- =====================================================================
PUBLIC FUNCTION (self t_shipper) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE shipperExists SMALLINT
   DEFINE valid_rec t_valid_rec

   IF mode == "C" THEN
      SELECT 1 INTO shipperExists FROM shippers WHERE shippers.shipperid = self.shipperid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Shipper ID is not found")
         RETURN valid_rec
      END IF
   END IF
   IF self.companyname IS NULL OR LENGTH(self.companyname) == 0 THEN
      CALL valid_rec.failed("Company Name is required")
      RETURN valid_rec
   END IF
   IF NVL(self.phone, "NULL") == "NULL" THEN
      CALL valid_rec.failed("Phone number is required")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the shipper record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_shipper) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO shippers (shipperid, companyname, phone)
      VALUES (DEFAULT, self.companyname, self.phone)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
      LET self.shipperid = sqlca.sqlerrd[2]
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: updateRec
-- Purpose : Update the shipper record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_shipper) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE shippers
      SET companyname = self.companyname,
          phone = self.phone
    WHERE shipperid = self.shipperid

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
-- Purpose : Delete the shipper record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_shipper) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM shippers
    WHERE shipperid = self.shipperid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec

-- =====================================================================
-- Function: validate_shipvia (PUBLIC)
-- =====================================================================
PUBLIC FUNCTION validate_shipvia(shipperid LIKE shippers.shipperid) RETURNS (t_valid_rec)
   DEFINE valid_status t_valid_rec

   IF shipperid IS NOT NULL THEN
      SELECT shipperid FROM shippers WHERE shippers.shipperid = $shipperid
      IF sqlca.sqlcode == 0 THEN
         CALL valid_status.success("Okay!")
      ELSE
         CALL valid_status.failed("Shipper ID does not exist in shippers table")
      END IF
   ELSE
      CALL valid_status.success("Okay!")
   END IF
   RETURN valid_status

END FUNCTION #validate_shipvia
