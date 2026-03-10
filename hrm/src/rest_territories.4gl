IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_territories
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all territory records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/territories",
      WSDescription = "Get all territories",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_territory ATTRIBUTES(WSMedia = "application/json")

   DEFINE territories DYNAMIC ARRAY OF t_territory
   DEFINE rec t_territory
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_territories CURSOR FOR
      SELECT territoryid, territorydescription, regionid
        FROM territories
       ORDER BY territorydescription
   FOREACH c_rest_territories INTO rec.territoryid, rec.territorydescription, rec.regionid
      LET i = i + 1
      LET territories[i] = rec
   END FOREACH

   RETURN territories
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single territory by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_territoryid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/territories/{p_territoryid}",
      WSDescription = "Get a territory by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_territory ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_territory

   SELECT territoryid, territorydescription, regionid
     INTO rec.territoryid, rec.territorydescription, rec.regionid
     FROM territories
    WHERE territoryid = p_territoryid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Territory with ID %1 not found", p_territoryid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new territory record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_territory)
   ATTRIBUTES(WSPost,
      WSPath = "/territories",
      WSDescription = "Create a new territory",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_territory ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing territory record
-- =====================================================================
PUBLIC FUNCTION update(
   p_territoryid VARCHAR(20) ATTRIBUTES(WSParam),
   rec t_territory)
   ATTRIBUTES(WSPut,
      WSPath = "/territories/{p_territoryid}",
      WSDescription = "Update a territory",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_territory ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.territoryid = p_territoryid

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
-- Purpose : Delete a territory record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_territoryid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/territories/{p_territoryid}",
      WSDescription = "Delete a territory",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_territory
   DEFINE del_status t_valid_rec

   LET rec.territoryid = p_territoryid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
