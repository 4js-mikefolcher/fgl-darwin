IMPORT FGL model_helper
SCHEMA northwind

PUBLIC TYPE t_employee RECORD
   employeeid LIKE employees.employeeid,
   lastname LIKE employees.lastname,
   firstname LIKE employees.firstname,
   title LIKE employees.title,
   titleofcourtesy LIKE employees.titleofcourtesy,
   birthdate LIKE employees.birthdate,
   hiredate LIKE employees.hiredate,
   address LIKE employees.address,
   city LIKE employees.city,
   region LIKE employees.region,
   postalcode LIKE employees.postalcode,
   country LIKE employees.country,
   homephone LIKE employees.homephone,
   extension LIKE employees.extension,
   reportsto LIKE employees.reportsto,
   fullname VARCHAR(32),
   photopath LIKE employees.photopath,
   notes LIKE employees.notes
END RECORD

PRIVATE CONSTANT cMessagePrefix = "Employee Record %1"

-- =====================================================================
-- Function: validateRec
-- Purpose : Validate the current employee record
-- =====================================================================
PUBLIC FUNCTION (self t_employee) validateRec(mode CHAR(1)) RETURNS (t_valid_rec)
   DEFINE employeeExists SMALLINT
   DEFINE fullname VARCHAR(32)
   DEFINE valid_rec t_valid_rec

   IF mode == "C" THEN
      SELECT 1 INTO employeeExists FROM employees WHERE employees.employeeid = self.employeeid
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Employee ID is not found")
         RETURN valid_rec
      END IF
   END IF

   IF self.firstname IS NULL OR LENGTH(self.firstname) == 0 THEN
      CALL valid_rec.failed("First name is missing")
      RETURN valid_rec
   END IF

   IF self.lastname IS NULL OR LENGTH(self.lastname) == 0 THEN
      CALL valid_rec.failed("Last name is missing")
      RETURN valid_rec
   END IF

   IF self.birthdate IS NULL THEN
      CALL valid_rec.failed("Birth date is missing")
      RETURN valid_rec
   END IF

   IF self.hiredate IS NULL THEN
      CALL valid_rec.failed("Hire date name is missing")
      RETURN valid_rec
   END IF

   IF self.hiredate <= self.birthdate THEN
      CALL valid_rec.failed("Hire date is before birth date")
      RETURN valid_rec
   END IF

   IF self.reportsto IS NOT NULL AND self.reportsto > 0 THEN
      SELECT RTRIM(firstname) || ' ' || RTRIM(lastname) INTO fullname
        FROM employees WHERE employees.employeeid = self.reportsto
      IF sqlca.sqlcode == NOTFOUND THEN
         CALL valid_rec.failed("Invalid reports to employee id value")
         RETURN valid_rec
      END IF
      LET self.fullname = fullname
   END IF

   CALL valid_rec.success("Okay")
   RETURN valid_rec

END FUNCTION #validateRec

-- =====================================================================
-- Function: insertRec
-- Purpose : Insert the employee record into the database
-- =====================================================================
PUBLIC FUNCTION (self t_employee) insertRec() RETURNS (t_valid_rec)
   DEFINE ins_status t_valid_rec

   INSERT INTO employees
      (employeeid, lastname, firstname, title, titleofcourtesy,
       birthdate, hiredate, address, city, region, postalcode, country,
       homephone, extension, reportsto, photopath, notes)
   VALUES
      (DEFAULT, self.lastname, self.firstname, self.title, self.titleofcourtesy,
       self.birthdate, self.hiredate, self.address, self.city, self.region,
       self.postalcode, self.country, self.homephone, self.extension,
       self.reportsto, self.photopath, self.notes)

   CALL ins_status.init()
   IF sqlca.sqlcode == 0 THEN
      CALL ins_status.success(SFMT(cMessagePrefix, "inserted"))
      LET self.employeeid = sqlca.sqlerrd[2]
   ELSE
      CALL ins_status.failed(SFMT(cMessagePrefix, "insert failed"))
   END IF
   RETURN ins_status

END FUNCTION #insertRec

-- =====================================================================
-- Function: updateRec
-- Purpose : Update the employee record in the database
-- =====================================================================
PUBLIC FUNCTION (self t_employee) updateRec() RETURNS (t_valid_rec)
   DEFINE upd_status t_valid_rec

   UPDATE employees
      SET lastname = self.lastname,
          firstname = self.firstname,
          title = self.title,
          titleofcourtesy = self.titleofcourtesy,
          birthdate = self.birthdate,
          hiredate = self.hiredate,
          address = self.address,
          city = self.city,
          region = self.region,
          postalcode = self.postalcode,
          country = self.country,
          homephone = self.homephone,
          extension = self.extension,
          notes = self.notes,
          reportsto = self.reportsto,
          photopath = self.photopath
    WHERE employeeid = self.employeeid

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
-- Purpose : Delete the employee record from the database
-- =====================================================================
PUBLIC FUNCTION (self t_employee) deleteRec() RETURNS (t_valid_rec)
   DEFINE del_status t_valid_rec

   DELETE FROM employees WHERE employeeid = self.employeeid

   CALL del_status.init()
   IF sqlca.sqlcode == 0 AND sqlca.sqlerrd[3] == 1 THEN
      CALL del_status.success(SFMT(cMessagePrefix, "deleted"))
   ELSE
      CALL del_status.failed(SFMT(cMessagePrefix, "delete failed"))
   END IF
   RETURN del_status

END FUNCTION #deleteRec
