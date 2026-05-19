IMPORT com
IMPORT util
IMPORT FGL model_helper
IMPORT FGL model_categories
SCHEMA northwind

PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- Purpose : Get all category records
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/categories",
      WSDescription = "Get all categories",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_category ATTRIBUTES(WSMedia = "application/json")

   DEFINE categories DYNAMIC ARRAY OF t_category
   DEFINE rec t_category
   DEFINE i INTEGER

   LET i = 0
   DECLARE c_rest_categories CURSOR FOR
      SELECT categoryid, categoryname, description FROM categories
       ORDER BY categoryname
   FOREACH c_rest_categories INTO rec.categoryid, rec.categoryname, rec.description
      LET i = i + 1
      LET categories[i] = rec
   END FOREACH

   RETURN categories
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- Purpose : Get a single category by ID
-- =====================================================================
PUBLIC FUNCTION getById(
   p_categoryid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/categories/{p_categoryid}",
      WSDescription = "Get a category by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_category ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_category

   SELECT categoryid, categoryname, description
     INTO rec.categoryid, rec.categoryname, rec.description
     FROM categories
    WHERE categoryid = p_categoryid

   IF sqlca.sqlcode == NOTFOUND THEN
      LET ws_error.message = SFMT("Category with ID %1 not found", p_categoryid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- Purpose : Create a new category record
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_category)
   ATTRIBUTES(WSPost,
      WSPath = "/categories",
      WSDescription = "Create a new category",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_category ATTRIBUTES(WSMedia = "application/json")

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
-- Purpose : Update an existing category record
-- =====================================================================
PUBLIC FUNCTION update(
   p_categoryid INTEGER ATTRIBUTES(WSParam),
   rec t_category)
   ATTRIBUTES(WSPut,
      WSPath = "/categories/{p_categoryid}",
      WSDescription = "Update a category",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_category ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   LET rec.categoryid = p_categoryid

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
-- Function: delete
-- Purpose : Delete a category record
-- =====================================================================
PUBLIC FUNCTION remove(
   p_categoryid INTEGER ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/categories/{p_categoryid}",
      WSDescription = "Delete a category",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_category
   DEFINE del_status t_valid_rec

   LET rec.categoryid = p_categoryid

   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   RETURN del_status.valid_msg
END FUNCTION #remove
