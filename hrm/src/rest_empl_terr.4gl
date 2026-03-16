IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_empl_terr
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all employee territory assignments
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/employee-territories",
      WSDescription = "Get all employee territory assignments",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_empl_terr ATTRIBUTES(WSMedia = "application/json")

   DEFINE empl_terrs DYNAMIC ARRAY OF t_empl_terr
   DEFINE rec t_empl_terr
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_empl_terr CURSOR FOR
      SELECT et.employeeid,
             RTRIM(e.firstname) || ' ' || RTRIM(e.lastname) AS fullname,
             et.territoryid,
             t.territorydescription,
             r.regiondescription
        FROM employeeterritories et
        LEFT OUTER JOIN employees e ON e.employeeid = et.employeeid
        LEFT OUTER JOIN territories t ON t.territoryid = et.territoryid
        LEFT OUTER JOIN region r ON r.regionid = t.regionid
       ORDER BY fullname, t.territorydescription
   FOREACH c_rest_empl_terr INTO rec.employeeid, rec.fullname,
         rec.territoryid, rec.territorydescription, rec.regiondescription
      LET i = i + 1
      LET empl_terrs[i] = rec
   END FOREACH

   RETURN empl_terrs
END FUNCTION #getAll

-- =====================================================================
-- Function: getByEmployee
-- Purpose : Get all territory assignments for a specific employee
-- =====================================================================
PUBLIC FUNCTION getByEmployee(
   p_employeeid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/employee-territories/employee/{p_employeeid}",
      WSDescription = "Get all territory assignments for an employee",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_empl_terr ATTRIBUTES(WSMedia = "application/json")

   DEFINE empl_terrs DYNAMIC ARRAY OF t_empl_terr
   DEFINE rec t_empl_terr
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_empl_terr_emp CURSOR FOR
      SELECT et.employeeid,
             RTRIM(e.firstname) || ' ' || RTRIM(e.lastname) AS fullname,
             et.territoryid,
             t.territorydescription,
             r.regiondescription
        FROM employeeterritories et
        LEFT OUTER JOIN employees e ON e.employeeid = et.employeeid
        LEFT OUTER JOIN territories t ON t.territoryid = et.territoryid
        LEFT OUTER JOIN region r ON r.regionid = t.regionid
       WHERE et.employeeid = p_employeeid
       ORDER BY t.territorydescription
   FOREACH c_rest_empl_terr_emp USING p_employeeid
         INTO rec.employeeid, rec.fullname,
              rec.territoryid, rec.territorydescription, rec.regiondescription
      LET i = i + 1
      LET empl_terrs[i] = rec
   END FOREACH

   IF empl_terrs.getLength() == 0 THEN
      LET ws_error.message = SFMT("No territory assignments found for employee %1", p_employeeid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN empl_terrs
END FUNCTION #getByEmployee

-- =====================================================================
-- Function: getById
-- Purpose : Get a single employee territory assignment by composite key
-- =====================================================================
PUBLIC FUNCTION getById(
   p_employeeid INTEGER ATTRIBUTES(WSParam),
   p_territoryid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/employee-territories/{p_employeeid}/{p_territoryid}",
      WSDescription = "Get an employee territory assignment",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_empl_terr ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_empl_terr

   SELECT et.employeeid,
          RTRIM(e.firstname) || ' ' || RTRIM(e.lastname) AS fullname,
          et.territoryid,
          t.territorydescription,
          r.regiondescription
     INTO rec.employeeid, rec.fullname,
          rec.territoryid, rec.territorydescription, rec.regiondescription
     FROM employeeterritories et
     LEFT OUTER JOIN employees e ON e.employeeid = et.employeeid
     LEFT OUTER JOIN territories t ON t.territoryid = et.territoryid
     LEFT OUTER JOIN region r ON r.regionid = t.regionid
    WHERE et.employeeid = p_employeeid
      AND et.territoryid = p_territoryid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Employee territory assignment %1/%2 not found", p_employeeid, p_territoryid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new employee territory assignment
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_empl_terr)
   ATTRIBUTES(WSPost,
      WSPath = "/employee-territories",
      WSDescription = "Create a new employee territory assignment",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_empl_terr ATTRIBUTES(WSMedia = "application/json")

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
-- Function: remove
-- Purpose : Delete an employee territory assignment
-- =====================================================================
PUBLIC FUNCTION remove(
   p_employeeid INTEGER ATTRIBUTES(WSParam),
   p_territoryid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/employee-territories/{p_employeeid}/{p_territoryid}",
      WSDescription = "Delete an employee territory assignment",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_empl_terr
   DEFINE del_status t_valid_rec

   LET rec.employeeid = p_employeeid
   LET rec.territoryid = p_territoryid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
