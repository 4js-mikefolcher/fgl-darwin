IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_territory RECORD
   territoryid VARCHAR(20),
   territorydescription VARCHAR(20),
   regionid SMALLINT
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Territory Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current territory record
-- =====================================================================
PUBLIC FUNCTION (self t_territory) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE territoriesExists SMALLINT
   DEFINE valid_rec t_valid_rec

   SELECT 1 INTO territoriesExists FROM territories WHERE territories.territoryid = self.territoryid
   IF sqlca.sqlcode == NOTFOUND AND mode == "C" THEN
      CALL valid_rec.failed("Territory ID is not found")
      RETURN valid_rec
   END IF
   IF sqlca.sqlcode == 0 AND mode == "A" THEN
      CALL valid_rec.failed("Territory ID already exists")
      RETURN valid_rec
   END IF

   IF self.territoryid IS NULL OR LENGTH(self.territoryid) == 0 THEN
      CALL valid_rec.failed("Territory ID is required")
      RETURN valid_rec
   END IF
   IF self.territorydescription IS NULL OR LENGTH(self.territorydescription) == 0 THEN
      CALL valid_rec.failed("Territory Description is required")
      RETURN valid_rec
   END IF
   IF self.regionid IS NULL THEN
      CALL valid_rec.failed("Region is required")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the territory record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_territory) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO territories (territoryid, territorydescription, regionid)
      VALUES (self.territoryid, self.territorydescription, self.regionid)

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
-- Purpose : Update the territory record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_territory) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE territories
      SET territorydescription = self.territorydescription,
          regionid = self.regionid
    WHERE territoryid = self.territoryid

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
-- Purpose : Delete the territory record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_territory) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM territories
    WHERE territoryid = self.territoryid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec
