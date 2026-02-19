IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_category RECORD
   categoryid LIKE categories.categoryid,
   categoryname LIKE categories.categoryname,
   description LIKE categories.description
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Category Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current category record
-- =====================================================================
PUBLIC FUNCTION (self t_category) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE categoryExists SMALLINT
   DEFINE valid_rec t_valid_rec

   IF mode == "C" THEN
      SELECT 1 INTO categoryExists FROM categories WHERE categories.categoryid = self.categoryid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Category ID is not found")
         RETURN valid_rec
      END IF
   END IF
   IF self.categoryname IS NULL OR LENGTH(self.categoryname) == 0 THEN
      CALL valid_rec.failed("Category Name is required")
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

PUBLIC FUNCTION (self t_category) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO categories (categoryid, categoryname, description)
      VALUES (DEFAULT, self.categoryname, self.description)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
      LET self.categoryid = sqlca.sqlerrd[2]
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

FUNCTION (self t_category) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE categories
      SET categoryname = self.categoryname,
          description = self.description
    WHERE categoryid = self.categoryid

   CALL upd_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL upd_status.success(SFMT(cMessagePrefix, "updated"))
   ELSE
      CALL upd_status.failed(SFMT(cMessagePrefix, "update failed"))
   END IF
   RETURN upd_status

END FUNCTION #updateRec

PUBLIC FUNCTION (self t_category) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM categories
    WHERE categoryid = self.categoryid
   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec

