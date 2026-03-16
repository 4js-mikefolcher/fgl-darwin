IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_suppliers
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- Lightweight record type using STRING for JSON serialization.
-- Avoids VARCHAR padding that causes truncated responses in getAll.
-- NOTE: If the definition of t_supplier in model_suppliers.4gl changes,
--       this t_supplier_json record type must be updated to match.
PRIVATE TYPE t_supplier_json RECORD
   supplierid   INTEGER,
   companyname  STRING,
   contactname  STRING,
   contacttitle STRING,
   address      STRING,
   city         STRING,
   region       STRING,
   postalcode   STRING,
   country      STRING,
   phone        STRING,
   fax          STRING,
   homepage     STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all supplier records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/suppliers",
      WSDescription = "Get all suppliers",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_supplier_json ATTRIBUTES(WSMedia = "application/json")

   DEFINE suppliers DYNAMIC ARRAY OF t_supplier_json
   DEFINE rec t_supplier_json
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_suppliers CURSOR FOR
      SELECT supplierid, companyname, contactname, contacttitle,
             address, city, region, postalcode, country, phone, fax, homepage
        FROM suppliers
       ORDER BY companyname
   FOREACH c_rest_suppliers INTO rec.supplierid, rec.companyname, rec.contactname,
      rec.contacttitle, rec.address, rec.city, rec.region, rec.postalcode,
      rec.country, rec.phone, rec.fax, rec.homepage
      LET i = i + 1
      LET suppliers[i] = rec
   END FOREACH

   RETURN suppliers
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single supplier by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_supplierid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/suppliers/{p_supplierid}",
      WSDescription = "Get a supplier by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_supplier ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_supplier

   SELECT supplierid, companyname, contactname, contacttitle,
          address, city, region, postalcode, country, phone, fax, homepage
     INTO rec.supplierid, rec.companyname, rec.contactname,
          rec.contacttitle, rec.address, rec.city, rec.region,
          rec.postalcode, rec.country, rec.phone, rec.fax, rec.homepage
     FROM suppliers
    WHERE supplierid = p_supplierid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Supplier with ID %1 not found", p_supplierid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new supplier record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_supplier)
   ATTRIBUTES(WSPost,
      WSPath = "/suppliers",
      WSDescription = "Create a new supplier",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_supplier ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing supplier record
-- =====================================================================
PUBLIC FUNCTION update(
   p_supplierid INTEGER ATTRIBUTES(WSParam),
   rec t_supplier)
   ATTRIBUTES(WSPut,
      WSPath = "/suppliers/{p_supplierid}",
      WSDescription = "Update a supplier",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_supplier ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.supplierid = p_supplierid

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
-- Purpose : Delete a supplier record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_supplierid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/suppliers/{p_supplierid}",
      WSDescription = "Delete a supplier",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_supplier
   DEFINE del_status t_valid_rec

   LET rec.supplierid = p_supplierid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
