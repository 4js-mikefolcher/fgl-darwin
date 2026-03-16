IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_employees
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all employee records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/employees",
      WSDescription = "Get all employees",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_employee ATTRIBUTES(WSMedia = "application/json")

   DEFINE employees DYNAMIC ARRAY OF t_employee
   DEFINE rec t_employee
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_employees CURSOR FOR
      SELECT e.employeeid, e.lastname, e.firstname, e.title, e.titleofcourtesy,
             e.birthdate, e.hiredate, e.address, e.city, e.region,
             e.postalcode, e.country, e.homephone, e.extension,
             e.reportsto, e.photopath, e.notes,
             RTRIM(m.firstname) || ' ' || RTRIM(m.lastname)
        FROM employees e
        LEFT OUTER JOIN employees m ON m.employeeid = e.reportsto
       ORDER BY e.lastname, e.firstname
   FOREACH c_rest_employees INTO rec.employeeid, rec.lastname, rec.firstname,
      rec.title, rec.titleofcourtesy, rec.birthdate, rec.hiredate,
      rec.address, rec.city, rec.region, rec.postalcode, rec.country,
      rec.homephone, rec.extension, rec.reportsto, rec.photopath, rec.notes,
      rec.fullname
      LET i = i + 1
      LET employees[i] = rec
   END FOREACH

   RETURN employees
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single employee by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_employeeid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/employees/{p_employeeid}",
      WSDescription = "Get an employee by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_employee ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_employee

   SELECT e.employeeid, e.lastname, e.firstname, e.title, e.titleofcourtesy,
          e.birthdate, e.hiredate, e.address, e.city, e.region,
          e.postalcode, e.country, e.homephone, e.extension,
          e.reportsto, e.photopath, e.notes,
          RTRIM(m.firstname) || ' ' || RTRIM(m.lastname)
     INTO rec.employeeid, rec.lastname, rec.firstname,
          rec.title, rec.titleofcourtesy, rec.birthdate, rec.hiredate,
          rec.address, rec.city, rec.region, rec.postalcode, rec.country,
          rec.homephone, rec.extension, rec.reportsto, rec.photopath, rec.notes,
          rec.fullname
     FROM employees e
     LEFT OUTER JOIN employees m ON m.employeeid = e.reportsto
    WHERE e.employeeid = p_employeeid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Employee with ID %1 not found", p_employeeid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new employee record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_employee)
   ATTRIBUTES(WSPost,
      WSPath = "/employees",
      WSDescription = "Create a new employee",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_employee ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE ins_status t_valid_rec

   LET valid_rec = rec.validateRec("A")
   IF NOT valid_rec.valid_status THEN
      LET ws_error.message = valid_rec.valid_msg
      CALL com.WebServiceEngine.SetRestError(400, ws_error)
      RETURN rec
   END IF

   LET ins_status = rec.insertRec()
   IF NOT ins_status.valid_status THEN
      LET ws_error.message = ins_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(500, ws_error)
   END IF

   RETURN rec
END FUNCTION #create

-- =====================================================================
-- Function: update
-- Purpose : Update an existing employee record
-- =====================================================================
PUBLIC FUNCTION update(
   p_employeeid INTEGER ATTRIBUTES(WSParam),
   rec t_employee)
   ATTRIBUTES(WSPut,
      WSPath = "/employees/{p_employeeid}",
      WSDescription = "Update an employee",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_employee ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.employeeid = p_employeeid

   LET valid_rec = rec.validateRec("C")
   IF NOT valid_rec.valid_status THEN
      LET ws_error.message = valid_rec.valid_msg
      CALL com.WebServiceEngine.SetRestError(400, ws_error)
      RETURN rec
   END IF

   LET upd_status = rec.updateRec()
   IF NOT upd_status.valid_status THEN
      LET ws_error.message = upd_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(500, ws_error)
   END IF

   RETURN rec
END FUNCTION #update

-- =====================================================================
-- Function: remove
-- Purpose : Delete an employee record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_employeeid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/employees/{p_employeeid}",
      WSDescription = "Delete an employee",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_employee
   DEFINE del_status t_valid_rec

   LET rec.employeeid = p_employeeid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
