IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_region
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all region records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/regions",
      WSDescription = "Get all regions",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_region ATTRIBUTES(WSMedia = "application/json")

   DEFINE regions DYNAMIC ARRAY OF t_region
   DEFINE rec t_region
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_regions CURSOR FOR
      SELECT regionid, regiondescription
        FROM region
       ORDER BY regiondescription
   FOREACH c_rest_regions INTO rec.regionid, rec.regiondescription
      LET i = i + 1
      LET regions[i] = rec
   END FOREACH

   RETURN regions
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single region by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_regionid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/regions/{p_regionid}",
      WSDescription = "Get a region by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_region ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_region

   SELECT regionid, regiondescription
     INTO rec.regionid, rec.regiondescription
     FROM region
    WHERE regionid = p_regionid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Region with ID %1 not found", p_regionid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new region record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_region)
   ATTRIBUTES(WSPost,
      WSPath = "/regions",
      WSDescription = "Create a new region",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_region ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing region record
-- =====================================================================
PUBLIC FUNCTION update(
   p_regionid INTEGER ATTRIBUTES(WSParam),
   rec t_region)
   ATTRIBUTES(WSPut,
      WSPath = "/regions/{p_regionid}",
      WSDescription = "Update a region",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_region ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.regionid = p_regionid

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
-- Purpose : Delete a region record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_regionid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/regions/{p_regionid}",
      WSDescription = "Delete a region",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_region
   DEFINE del_status t_valid_rec

   LET rec.regionid = p_regionid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
