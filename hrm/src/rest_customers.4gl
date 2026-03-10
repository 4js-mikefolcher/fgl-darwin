IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_customers
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all customer records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/customers",
      WSDescription = "Get all customers",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_customer ATTRIBUTES(WSMedia = "application/json")

   DEFINE customers DYNAMIC ARRAY OF t_customer
   DEFINE rec t_customer
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_customers CURSOR FOR
      SELECT customerid, companyname, contactname, contacttitle,
             address, city, region, postalcode, country, phone, fax
        FROM customers
       ORDER BY companyname
   FOREACH c_rest_customers INTO rec.customerid, rec.companyname, rec.contactname,
      rec.contacttitle, rec.address, rec.city, rec.region, rec.postalcode,
      rec.country, rec.phone, rec.fax
      LET i = i + 1
      LET customers[i] = rec
   END FOREACH

   RETURN customers
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single customer by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_customerid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/customers/{p_customerid}",
      WSDescription = "Get a customer by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_customer ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_customer

   SELECT customerid, companyname, contactname, contacttitle,
          address, city, region, postalcode, country, phone, fax
     INTO rec.customerid, rec.companyname, rec.contactname,
          rec.contacttitle, rec.address, rec.city, rec.region,
          rec.postalcode, rec.country, rec.phone, rec.fax
     FROM customers
    WHERE customerid = p_customerid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Customer with ID '%1' not found", p_customerid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new customer record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_customer)
   ATTRIBUTES(WSPost,
      WSPath = "/customers",
      WSDescription = "Create a new customer",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_customer ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing customer record
-- =====================================================================
PUBLIC FUNCTION update(
   p_customerid VARCHAR(20) ATTRIBUTES(WSParam),
   rec t_customer)
   ATTRIBUTES(WSPut,
      WSPath = "/customers/{p_customerid}",
      WSDescription = "Update a customer",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_customer ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.customerid = p_customerid

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
-- Purpose : Delete a customer record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_customerid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/customers/{p_customerid}",
      WSDescription = "Delete a customer",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_customer
   DEFINE del_status t_valid_rec

   LET rec.customerid = p_customerid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
