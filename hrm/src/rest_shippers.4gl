IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_shippers
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all shipper records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/shippers",
      WSDescription = "Get all shippers",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_shipper ATTRIBUTES(WSMedia = "application/json")

   DEFINE shippers DYNAMIC ARRAY OF t_shipper
   DEFINE rec t_shipper
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_shippers CURSOR FOR
      SELECT shipperid, companyname, phone
        FROM shippers
       ORDER BY companyname
   FOREACH c_rest_shippers INTO rec.shipperid, rec.companyname, rec.phone
      LET i = i + 1
      LET shippers[i] = rec
   END FOREACH

   RETURN shippers
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single shipper by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_shipperid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/shippers/{p_shipperid}",
      WSDescription = "Get a shipper by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_shipper ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_shipper

   SELECT shipperid, companyname, phone
     INTO rec.shipperid, rec.companyname, rec.phone
     FROM shippers
    WHERE shipperid = p_shipperid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Shipper with ID %1 not found", p_shipperid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new shipper record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_shipper)
   ATTRIBUTES(WSPost,
      WSPath = "/shippers",
      WSDescription = "Create a new shipper",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_shipper ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing shipper record
-- =====================================================================
PUBLIC FUNCTION update(
   p_shipperid INTEGER ATTRIBUTES(WSParam),
   rec t_shipper)
   ATTRIBUTES(WSPut,
      WSPath = "/shippers/{p_shipperid}",
      WSDescription = "Update a shipper",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_shipper ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.shipperid = p_shipperid

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
-- Purpose : Delete a shipper record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_shipperid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/shippers/{p_shipperid}",
      WSDescription = "Delete a shipper",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_shipper
   DEFINE del_status t_valid_rec

   LET rec.shipperid = p_shipperid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
