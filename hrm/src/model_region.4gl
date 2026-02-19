IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_region RECORD
   regionid LIKE region.regionid,
   regiondescription LIKE region.regiondescription
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Region Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current region record
-- =====================================================================
PUBLIC FUNCTION (self t_region) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE regionExists SMALLINT
   DEFINE valid_rec t_valid_rec

   IF mode == "C" THEN
      SELECT 1 INTO regionExists FROM region WHERE region.regionid = self.regionid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Region ID is not found")
         RETURN valid_rec
      END IF
   END IF

   IF self.regiondescription IS NULL OR LENGTH(self.regiondescription) == 0 THEN
      CALL valid_rec.failed("Region Description is required")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the region record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_region) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO region (regionid, regiondescription)
      VALUES (DEFAULT, self.regiondescription)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
      LET self.regionid = sqlca.sqlerrd[2]
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: updateRec
-- Purpose : Update the region record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_region) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE region
      SET regiondescription = self.regiondescription
    WHERE regionid = self.regionid

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
-- Purpose : Delete the region record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_region) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM region
    WHERE regionid = self.regionid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec
