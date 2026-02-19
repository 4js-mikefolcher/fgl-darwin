IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_usstate RECORD
   stateid SMALLINT,
   statename VARCHAR(100),
   stateabbr VARCHAR(2),
   stateregion VARCHAR(50)
END RECORD

PRIVATE CONSTANT cMessagePrefix = "State Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current state record
-- =====================================================================
PUBLIC FUNCTION (self t_usstate) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE stateExists SMALLINT
   DEFINE valid_rec t_valid_rec

   IF mode == "C" THEN
      SELECT 1 INTO stateExists FROM usstates WHERE usstates.stateid = self.stateid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("State ID is not found")
         RETURN valid_rec
      END IF
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the state record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_usstate) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO usstates (stateid, statename, stateabbr, stateregion)
      VALUES (DEFAULT, self.statename, self.stateabbr, self.stateregion)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
      LET self.stateid = sqlca.sqlerrd[2]
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: updateRec
-- Purpose : Update the state record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_usstate) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE usstates
      SET statename = self.statename,
          stateabbr = self.stateabbr,
          stateregion = self.stateregion
    WHERE stateid = self.stateid

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
-- Purpose : Delete the state record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_usstate) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM usstates
    WHERE stateid = self.stateid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec
