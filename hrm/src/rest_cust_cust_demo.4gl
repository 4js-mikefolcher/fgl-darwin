IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_cust_cust_demo
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all customer-to-customer-demographics assignments
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/customer-customer-demo",
      WSDescription = "Get all customer demographics assignments",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_cust_cust_demo ATTRIBUTES(WSMedia = "application/json")

   DEFINE cust_demos DYNAMIC ARRAY OF t_cust_cust_demo
   DEFINE rec t_cust_cust_demo
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_cust_cust_demo CURSOR FOR
      SELECT ccd.customerid,
             c.companyname,
             ccd.customertypeid,
             cd.customerdesc
        FROM customercustomerdemo ccd
        LEFT OUTER JOIN customers c ON c.customerid = ccd.customerid
        LEFT OUTER JOIN customerdemographics cd ON cd.customertypeid = ccd.customertypeid
       ORDER BY c.companyname, ccd.customertypeid
   FOREACH c_rest_cust_cust_demo INTO rec.customerid, rec.companyname,
         rec.customertypeid, rec.customerdesc
      LET i = i + 1
      LET cust_demos[i] = rec
   END FOREACH

   RETURN cust_demos
END FUNCTION #getAll

-- =====================================================================
-- Function: getByCustomer
-- Purpose : Get all demographics assignments for a specific customer
-- =====================================================================
PUBLIC FUNCTION getByCustomer(
   p_customerid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/customer-customer-demo/customer/{p_customerid}",
      WSDescription = "Get all demographics assignments for a customer",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_cust_cust_demo ATTRIBUTES(WSMedia = "application/json")

   DEFINE cust_demos DYNAMIC ARRAY OF t_cust_cust_demo
   DEFINE rec t_cust_cust_demo
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_cust_cust_demo_cid CURSOR FOR
      SELECT ccd.customerid,
             c.companyname,
             ccd.customertypeid,
             cd.customerdesc
        FROM customercustomerdemo ccd
        LEFT OUTER JOIN customers c ON c.customerid = ccd.customerid
        LEFT OUTER JOIN customerdemographics cd ON cd.customertypeid = ccd.customertypeid
       WHERE ccd.customerid = p_customerid
       ORDER BY ccd.customertypeid
   FOREACH c_rest_cust_cust_demo_cid USING p_customerid
         INTO rec.customerid, rec.companyname,
              rec.customertypeid, rec.customerdesc
      LET i = i + 1
      LET cust_demos[i] = rec
   END FOREACH

   IF cust_demos.getLength() == 0 THEN
      LET ws_error.message = SFMT("No demographics assignments found for customer %1", p_customerid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN cust_demos
END FUNCTION #getByCustomer

-- =====================================================================
-- Function: getById
-- Purpose : Get a single customer demographics assignment by composite key
-- =====================================================================
PUBLIC FUNCTION getById(
   p_customerid VARCHAR(20) ATTRIBUTES(WSParam),
   p_customertypeid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/customer-customer-demo/{p_customerid}/{p_customertypeid}",
      WSDescription = "Get a customer demographics assignment",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_cust_cust_demo ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_cust_cust_demo

   SELECT ccd.customerid,
          c.companyname,
          ccd.customertypeid,
          cd.customerdesc
     INTO rec.customerid, rec.companyname,
          rec.customertypeid, rec.customerdesc
     FROM customercustomerdemo ccd
     LEFT OUTER JOIN customers c ON c.customerid = ccd.customerid
     LEFT OUTER JOIN customerdemographics cd ON cd.customertypeid = ccd.customertypeid
    WHERE ccd.customerid = p_customerid
      AND ccd.customertypeid = p_customertypeid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Customer demographics assignment %1/%2 not found", p_customerid, p_customertypeid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new customer demographics assignment
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_cust_cust_demo)
   ATTRIBUTES(WSPost,
      WSPath = "/customer-customer-demo",
      WSDescription = "Create a new customer demographics assignment",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_cust_cust_demo ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Delete a customer demographics assignment
-- =====================================================================
PUBLIC FUNCTION remove(
   p_customerid VARCHAR(20) ATTRIBUTES(WSParam),
   p_customertypeid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/customer-customer-demo/{p_customerid}/{p_customertypeid}",
      WSDescription = "Delete a customer demographics assignment",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_cust_cust_demo
   DEFINE del_status t_valid_rec

   LET rec.customerid = p_customerid
   LET rec.customertypeid = p_customertypeid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
