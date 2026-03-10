IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_order_details
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all order detail records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/order-details",
      WSDescription = "Get all order details",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_order_detail ATTRIBUTES(WSMedia = "application/json")

   DEFINE details DYNAMIC ARRAY OF t_order_detail
   DEFINE rec t_order_detail
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_order_details CURSOR FOR
      SELECT od.orderid, od.productid, p.productname,
             od.unitprice, od.quantity, od.discount,
             od.unitprice * od.quantity * (1 - od.discount)
        FROM order_details od
        LEFT OUTER JOIN products p ON p.productid = od.productid
       ORDER BY od.orderid, od.productid
   FOREACH c_rest_order_details INTO rec.orderid, rec.productid, rec.productname,
      rec.unitprice, rec.quantity, rec.discount, rec.totalprice
      LET i = i + 1
      LET details[i] = rec
   END FOREACH

   RETURN details
END FUNCTION #getAll

-- =====================================================================
-- Function: getByOrderId
-- Purpose : Get all order details for a specific order
-- =====================================================================
PUBLIC FUNCTION getByOrderId(
   p_orderid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/order-details/order/{p_orderid}",
      WSDescription = "Get order details by order ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_order_detail ATTRIBUTES(WSMedia = "application/json")

   DEFINE details DYNAMIC ARRAY OF t_order_detail
   DEFINE rec t_order_detail
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_od_by_order CURSOR FOR
      SELECT od.orderid, od.productid, p.productname,
             od.unitprice, od.quantity, od.discount,
             od.unitprice * od.quantity * (1 - od.discount)
        FROM order_details od
        LEFT OUTER JOIN products p ON p.productid = od.productid
       WHERE od.orderid = p_orderid
       ORDER BY od.productid
   FOREACH c_rest_od_by_order INTO rec.orderid, rec.productid, rec.productname,
      rec.unitprice, rec.quantity, rec.discount, rec.totalprice
      LET i = i + 1
      LET details[i] = rec
   END FOREACH

   RETURN details
END FUNCTION #getByOrderId

-- =====================================================================
-- Function: getById
-- Purpose : Get a single order detail by composite key
-- =====================================================================
PUBLIC FUNCTION getById(
   p_orderid INTEGER ATTRIBUTES(WSParam),
   p_productid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/order-details/{p_orderid}/{p_productid}",
      WSDescription = "Get an order detail by order ID and product ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_order_detail ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_order_detail

   SELECT od.orderid, od.productid, p.productname,
          od.unitprice, od.quantity, od.discount,
          od.unitprice * od.quantity * (1 - od.discount)
     INTO rec.orderid, rec.productid, rec.productname,
          rec.unitprice, rec.quantity, rec.discount, rec.totalprice
     FROM order_details od
     LEFT OUTER JOIN products p ON p.productid = od.productid
    WHERE od.orderid = p_orderid
      AND od.productid = p_productid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Order detail with order ID %1 and product ID %2 not found", p_orderid, p_productid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new order detail record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_order_detail)
   ATTRIBUTES(WSPost,
      WSPath = "/order-details",
      WSDescription = "Create a new order detail",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_order_detail ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing order detail record
-- =====================================================================
PUBLIC FUNCTION update(
   p_orderid INTEGER ATTRIBUTES(WSParam),
   p_productid INTEGER ATTRIBUTES(WSParam),
   rec t_order_detail)
   ATTRIBUTES(WSPut,
      WSPath = "/order-details/{p_orderid}/{p_productid}",
      WSDescription = "Update an order detail",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_order_detail ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.orderid = p_orderid
   LET rec.productid = p_productid

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
-- Purpose : Delete an order detail record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_orderid INTEGER ATTRIBUTES(WSParam),
   p_productid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/order-details/{p_orderid}/{p_productid}",
      WSDescription = "Delete an order detail",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_order_detail
   DEFINE del_status t_valid_rec

   LET rec.orderid = p_orderid
   LET rec.productid = p_productid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
