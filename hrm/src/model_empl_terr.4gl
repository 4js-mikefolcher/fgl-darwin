IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_empl_terr RECORD
   employeeid LIKE employees.employeeid,
   fullname VARCHAR(32),
   territoryid LIKE territories.territoryid,
   territorydescription LIKE territories.territorydescription,
   regiondescription LIKE region.regiondescription
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Employee Territory Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current employee territory record
-- =====================================================================
PUBLIC FUNCTION (self t_empl_terr) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE exists_count SMALLINT
   DEFINE valid_rec t_valid_rec

   IF self.employeeid IS NULL THEN
      CALL valid_rec.failed("Employee ID is required")
      RETURN valid_rec
   END IF
   IF self.territoryid IS NULL OR LENGTH(self.territoryid) == 0 THEN
      CALL valid_rec.failed("Territory ID is required")
      RETURN valid_rec
   END IF

   -- Check for duplicate assignment
   SELECT COUNT(*) INTO exists_count
      FROM employeeterritories
      WHERE employeeid = self.employeeid
        AND territoryid = self.territoryid
   IF exists_count > 0 THEN
      CALL valid_rec.failed("This employee is already assigned to this territory")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: validate_territory
-- Purpose : Validate a territory ID and return its description and region
-- =====================================================================
PUBLIC FUNCTION (self t_empl_terr) validateTerritory() RETURNS (t_valid_rec)
   DEFINE valid_rec t_valid_rec

   SELECT territorydescription INTO self.territorydescription
      FROM territories
      WHERE territories.territoryid = self.territoryid
   IF sqlca.sqlcode == NOTFOUND THEN
      CALL valid_rec.failed("Territory ID is not found")
      RETURN valid_rec
   END IF

   SELECT regiondescription INTO self.regiondescription
      FROM region
      INNER JOIN territories ON territories.regionid = region.regionid
      WHERE territories.territoryid = self.territoryid
   CALL valid_rec.success("Territory found")

   RETURN valid_rec

END FUNCTION #validateTerritory

-- =====================================================================
-- Function: validate_empl_id
-- Purpose : Validate an employee ID and return the full name
-- =====================================================================
PUBLIC FUNCTION (self t_empl_terr) validateEmployee() RETURNS (t_valid_rec)
   DEFINE valid_rec t_valid_rec

   SELECT RTRIM(employees.firstname) || ' ' || RTRIM(employees.lastname) as fullname
      INTO self.fullname
      FROM employees
      WHERE employeeid = self.employeeid
   IF sqlca.sqlcode == NOTFOUND THEN
      CALL valid_rec.failed("Employee ID is not found")
      RETURN valid_rec
   END IF

   CALL valid_rec.success("Employee found")
   RETURN valid_rec

END FUNCTION #validateEmployee

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the employee territory record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_empl_terr) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO employeeterritories (employeeid, territoryid)
      VALUES (self.employeeid, self.territoryid)

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
-- Purpose : Delete the employee territory record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_empl_terr) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM employeeterritories
    WHERE employeeid = self.employeeid
      AND territoryid = self.territoryid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec
