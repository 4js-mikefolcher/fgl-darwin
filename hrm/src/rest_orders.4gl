IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_orders
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all order records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/orders",
      WSDescription = "Get all orders",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_order ATTRIBUTES(WSMedia = "application/json")

   DEFINE orders DYNAMIC ARRAY OF t_order
   DEFINE rec t_order
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_orders CURSOR FOR
      SELECT o.orderid, o.customerid, c.companyname, o.employeeid,
             RTRIM(e.firstname) || ' ' || RTRIM(e.lastname),
             o.orderdate, o.requireddate, o.shippeddate,
             o.shipvia, o.freight, o.shipname, o.shipaddress,
             o.shipcity, o.shipregion, o.shippostalcode, o.shipcountry
        FROM orders o
        LEFT OUTER JOIN customers c ON c.customerid = o.customerid
        LEFT OUTER JOIN employees e ON e.employeeid = o.employeeid
       ORDER BY o.orderid
   FOREACH c_rest_orders INTO rec.orderid, rec.customerid, rec.customername,
      rec.employeeid, rec.employeename, rec.orderdate, rec.requireddate,
      rec.shippeddate, rec.shipvia, rec.freight, rec.shipname,
      rec.shipaddress, rec.shipcity, rec.shipregion, rec.shippostalcode,
      rec.shipcountry
      LET i = i + 1
      LET orders[i] = rec
   END FOREACH

   RETURN orders
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single order by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_orderid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/orders/{p_orderid}",
      WSDescription = "Get an order by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_order ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_order

   SELECT o.orderid, o.customerid, c.companyname, o.employeeid,
          RTRIM(e.firstname) || ' ' || RTRIM(e.lastname),
          o.orderdate, o.requireddate, o.shippeddate,
          o.shipvia, o.freight, o.shipname, o.shipaddress,
          o.shipcity, o.shipregion, o.shippostalcode, o.shipcountry
     INTO rec.orderid, rec.customerid, rec.customername,
          rec.employeeid, rec.employeename, rec.orderdate, rec.requireddate,
          rec.shippeddate, rec.shipvia, rec.freight, rec.shipname,
          rec.shipaddress, rec.shipcity, rec.shipregion, rec.shippostalcode,
          rec.shipcountry
     FROM orders o
     LEFT OUTER JOIN customers c ON c.customerid = o.customerid
     LEFT OUTER JOIN employees e ON e.employeeid = o.employeeid
    WHERE o.orderid = p_orderid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Order with ID %1 not found", p_orderid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new order record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_order)
   ATTRIBUTES(WSPost,
      WSPath = "/orders",
      WSDescription = "Create a new order",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_order ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing order record
-- =====================================================================
PUBLIC FUNCTION update(
   p_orderid INTEGER ATTRIBUTES(WSParam),
   rec t_order)
   ATTRIBUTES(WSPut,
      WSPath = "/orders/{p_orderid}",
      WSDescription = "Update an order",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_order ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.orderid = p_orderid

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
-- Purpose : Delete an order record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_orderid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/orders/{p_orderid}",
      WSDescription = "Delete an order",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_order
   DEFINE del_status t_valid_rec

   LET rec.orderid = p_orderid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
