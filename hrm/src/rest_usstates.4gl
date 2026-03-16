IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_usstates
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all US state records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/usstates",
      WSDescription = "Get all US states",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_usstate ATTRIBUTES(WSMedia = "application/json")

   DEFINE usstates DYNAMIC ARRAY OF t_usstate
   DEFINE rec t_usstate
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_usstates CURSOR FOR
      SELECT stateid, statename, stateabbr, stateregion
        FROM usstates
       ORDER BY statename
   FOREACH c_rest_usstates INTO rec.stateid, rec.statename, rec.stateabbr, rec.stateregion
      LET i = i + 1
      LET usstates[i] = rec
   END FOREACH

   RETURN usstates
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single US state by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_stateid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/usstates/{p_stateid}",
      WSDescription = "Get a US state by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_usstate ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_usstate

   SELECT stateid, statename, stateabbr, stateregion
     INTO rec.stateid, rec.statename, rec.stateabbr, rec.stateregion
     FROM usstates
    WHERE stateid = p_stateid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("US state with ID %1 not found", p_stateid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new US state record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_usstate)
   ATTRIBUTES(WSPost,
      WSPath = "/usstates",
      WSDescription = "Create a new US state",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_usstate ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing US state record
-- =====================================================================
PUBLIC FUNCTION update(
   p_stateid INTEGER ATTRIBUTES(WSParam),
   rec t_usstate)
   ATTRIBUTES(WSPut,
      WSPath = "/usstates/{p_stateid}",
      WSDescription = "Update a US state",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_usstate ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.stateid = p_stateid

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
-- Purpose : Delete a US state record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_stateid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/usstates/{p_stateid}",
      WSDescription = "Delete a US state",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_usstate
   DEFINE del_status t_valid_rec

   LET rec.stateid = p_stateid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
