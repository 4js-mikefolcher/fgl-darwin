IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_products
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all product records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/products",
      WSDescription = "Get all products",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_product ATTRIBUTES(WSMedia = "application/json")

   DEFINE products DYNAMIC ARRAY OF t_product
   DEFINE rec t_product
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_products CURSOR FOR
      SELECT productid, productname, supplierid, categoryid,
             quantityperunit, unitprice, unitsinstock, unitsonorder,
             reorderlevel, discontinued
        FROM products
       ORDER BY productname
   FOREACH c_rest_products INTO rec.productid, rec.productname, rec.supplierid,
      rec.categoryid, rec.quantityperunit, rec.unitprice, rec.unitsinstock,
      rec.unitsonorder, rec.reorderlevel, rec.discontinued
      LET i = i + 1
      LET products[i] = rec
   END FOREACH

   RETURN products
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single product by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_productid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/products/{p_productid}",
      WSDescription = "Get a product by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_product ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_product

   SELECT productid, productname, supplierid, categoryid,
          quantityperunit, unitprice, unitsinstock, unitsonorder,
          reorderlevel, discontinued
     INTO rec.productid, rec.productname, rec.supplierid,
          rec.categoryid, rec.quantityperunit, rec.unitprice,
          rec.unitsinstock, rec.unitsonorder, rec.reorderlevel,
          rec.discontinued
     FROM products
    WHERE productid = p_productid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Product with ID %1 not found", p_productid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new product record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_product)
   ATTRIBUTES(WSPost,
      WSPath = "/products",
      WSDescription = "Create a new product",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_product ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing product record
-- =====================================================================
PUBLIC FUNCTION update(
   p_productid INTEGER ATTRIBUTES(WSParam),
   rec t_product)
   ATTRIBUTES(WSPut,
      WSPath = "/products/{p_productid}",
      WSDescription = "Update a product",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_product ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

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
-- Purpose : Delete a product record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_productid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/products/{p_productid}",
      WSDescription = "Delete a product",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_product
   DEFINE del_status t_valid_rec

   LET rec.productid = p_productid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
