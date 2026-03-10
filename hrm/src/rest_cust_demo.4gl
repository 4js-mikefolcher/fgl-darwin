-- ==========================================================================
-- Module: rest_cust_demo.4gl
-- Purpose: REST web service endpoint module for the customerdemographics
--          table.  Exposes CRUD operations (GET all, GET by ID, POST, PUT,
--          DELETE) under the /api/customer-demographics path.
--
-- How it works:
--   1. The main_rest_server.4gl program registers this module with the
--      Genero Web Services Engine via:
--        CALL com.WebServiceEngine.RegisterRestService("rest_cust_demo","api")
--   2. The engine introspects all PUBLIC functions that carry WS* attributes
--      and maps them to HTTP method + URL path combinations.
--   3. When an HTTP request arrives that matches a route, the engine
--      deserialises the JSON body / URL parameters, calls the matching
--      function, and serialises the return value back as the JSON response.
--   4. Errors are communicated by populating the ws_error record and
--      calling com.WebServiceEngine.SetRestError() with the appropriate
--      HTTP status code.
-- ==========================================================================

-- com   : provides com.WebServiceEngine for REST error handling
-- util  : provides util.JSON for serialization (used implicitly by the engine)
IMPORT com
IMPORT util

-- model_helper   : supplies the t_valid_rec type used for validation results
-- model_cust_demo: supplies the t_cust_demo record type and its CRUD methods
--                  (validateRec, insertRec, updateRec, deleteRec)
IMPORT FGL model_helper
IMPORT FGL model_cust_demo

-- SCHEMA directive tells the compiler which .sch file to use for
-- resolving unqualified table/column names in SQL statements
SCHEMA northwind

-- ws_error is the shared error payload returned to the client on failure.
-- The WSError = "error" attribute tells the engine to use this record
-- whenever a WSThrows status code is triggered via SetRestError().
PUBLIC DEFINE ws_error RECORD ATTRIBUTES(WSError = "error")
   message STRING
END RECORD

-- =====================================================================
-- Function: getAll
-- HTTP    : GET /api/customer-demographics
-- Purpose : Retrieve every row from the customerdemographics table and
--           return them as a JSON array.
--
-- Process:
--   1. Declare a SQL cursor that selects all columns ordered by the
--      primary key (customertypeid).
--   2. Iterate through the result set with FOREACH, appending each row
--      to a dynamic array.
--   3. Return the array — the engine serialises it to JSON automatically.
--      If the table is empty the client receives an empty JSON array [].
-- =====================================================================
PUBLIC FUNCTION getAll()
   ATTRIBUTES(WSGet,
      WSPath = "/customer-demographics",
      WSDescription = "Get all customer demographics",
      WSThrows = "500:@ws_error")
   RETURNS DYNAMIC ARRAY OF t_cust_demo ATTRIBUTES(WSMedia = "application/json")

   DEFINE demos DYNAMIC ARRAY OF t_cust_demo
   DEFINE rec t_cust_demo
   DEFINE i INTEGER

   -- Step 1: Initialise row counter
   LET i = 0

   -- Step 2: Declare and open a cursor for the full table scan
   DECLARE c_rest_cust_demo CURSOR FOR
      SELECT customertypeid, customerdesc
        FROM customerdemographics
       ORDER BY customertypeid

   -- Step 3: Loop through each row returned by the cursor
   FOREACH c_rest_cust_demo INTO rec.customertypeid, rec.customerdesc
      LET i = i + 1           -- Advance the array index
      LET demos[i] = rec      -- Copy the current row into the array
   END FOREACH

   -- Step 4: Return the populated array (engine converts to JSON)
   RETURN demos
END FUNCTION #getAll

-- =====================================================================
-- Function: getById
-- HTTP    : GET /api/customer-demographics/{p_customertypeid}
-- Purpose : Retrieve a single customerdemographics row by its primary
--           key (customertypeid) extracted from the URL path.
--
-- Process:
--   1. The engine extracts {p_customertypeid} from the URL and passes
--      it as the WSParam parameter.
--   2. Execute a SELECT ... WHERE to fetch the matching row.
--   3. If NOTFOUND, populate ws_error and send a 404 response.
--   4. Otherwise return the record as a JSON object.
-- =====================================================================
PUBLIC FUNCTION getById(
   p_customertypeid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSGet,
      WSPath = "/customer-demographics/{p_customertypeid}",
      WSDescription = "Get a customer demographics record by ID",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS t_cust_demo ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_cust_demo

   -- Step 1: Query the database for the requested primary key
   SELECT customertypeid, customerdesc
     INTO rec.customertypeid, rec.customerdesc
     FROM customerdemographics
    WHERE customertypeid = p_customertypeid

   -- Step 2: Check whether the row was found
   IF sqlca.sqlcode == NOTFOUND THEN
      -- No matching row — build a descriptive error message and
      -- tell the engine to respond with HTTP 404 Not Found
      LET ws_error.message = SFMT("Customer demographics type %1 not found", p_customertypeid)
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
   END IF

   -- Step 3: Return the record (populated on success, empty on 404)
   RETURN rec
END FUNCTION #getById

-- =====================================================================
-- Function: create
-- HTTP    : POST /api/customer-demographics
-- Purpose : Insert a new row into customerdemographics.  The JSON
--           request body is automatically deserialised into a
--           t_cust_demo record by the engine.
--
-- Process:
--   1. The engine deserialises the incoming JSON body into the `rec`
--      parameter (a t_cust_demo record).
--   2. Call the model's validateRec("A") to run add-mode validation
--      (e.g. required fields, duplicate key checks).
--   3. If validation fails, return HTTP 400 Bad Request with the
--      validation message.
--   4. Call insertRec() to perform the SQL INSERT.
--   5. If the insert fails, return HTTP 500 Internal Server Error.
--   6. On success, return the record (now persisted) as JSON.
-- =====================================================================
PUBLIC FUNCTION create(
   rec t_cust_demo)
   ATTRIBUTES(WSPost,
      WSPath = "/customer-demographics",
      WSDescription = "Create a new customer demographics record",
      WSThrows = "400:@ws_error,500:@ws_error")
   RETURNS t_cust_demo ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE ins_status t_valid_rec

   -- Step 1: Validate the incoming data in "Add" mode
   --   "A" tells validateRec this is a new record, so it checks for
   --   required fields and ensures the primary key does not already exist.
   LET valid_rec = rec.validateRec("A")
   IF NOT valid_rec.valid_status THEN
      -- Validation failed — report the reason as HTTP 400
      LET ws_error.message = valid_rec.valid_msg
      CALL com.WebServiceEngine.SetRestError(400, ws_error)
      RETURN rec
   END IF

   -- Step 2: Perform the database INSERT
   LET ins_status = rec.insertRec()
   IF NOT ins_status.valid_status THEN
      -- Insert failed (constraint violation, DB error, etc.) — HTTP 500
      LET ws_error.message = ins_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(500, ws_error)
   END IF

   -- Step 3: Return the persisted record as the response body
   RETURN rec
END FUNCTION #create

-- =====================================================================
-- Function: update
-- HTTP    : PUT /api/customer-demographics/{p_customertypeid}
-- Purpose : Replace/update an existing customerdemographics row.
--           The primary key comes from the URL path; the new field
--           values come from the JSON request body.
--
-- Process:
--   1. The engine extracts {p_customertypeid} from the URL path and
--      deserialises the JSON body into `rec`.
--   2. Override the record's PK with the URL value to ensure the path
--      and body are consistent (the URL is the authority for identity).
--   3. Validate in "Change" mode ("C") — checks that the record exists
--      and that the new field values are acceptable.
--   4. If validation fails, return HTTP 400.
--   5. Call updateRec() to execute the SQL UPDATE.
--   6. If the update fails, return HTTP 500.
--   7. On success, return the updated record as JSON.
-- =====================================================================
PUBLIC FUNCTION update(
   p_customertypeid VARCHAR(20) ATTRIBUTES(WSParam),
   rec t_cust_demo)
   ATTRIBUTES(WSPut,
      WSPath = "/customer-demographics/{p_customertypeid}",
      WSDescription = "Update a customer demographics record",
      WSThrows = "400:@ws_error,404:@ws_error,500:@ws_error")
   RETURNS t_cust_demo ATTRIBUTES(WSMedia = "application/json")

   DEFINE valid_rec t_valid_rec
   DEFINE upd_status t_valid_rec

   -- Step 1: Set the PK from the URL path parameter so the record
   --         identity is authoritative regardless of what was in the body
   LET rec.customertypeid = p_customertypeid

   -- Step 2: Validate in "Change" mode — confirms the row exists and
   --         that the submitted field values pass business rules
   LET valid_rec = rec.validateRec("C")
   IF NOT valid_rec.valid_status THEN
      -- Validation failed — return HTTP 400 with the reason
      LET ws_error.message = valid_rec.valid_msg
      CALL com.WebServiceEngine.SetRestError(400, ws_error)
      RETURN rec
   END IF

   -- Step 3: Execute the SQL UPDATE via the model method
   LET upd_status = rec.updateRec()
   IF NOT upd_status.valid_status THEN
      -- Update failed at the database level — HTTP 500
      LET ws_error.message = upd_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(500, ws_error)
   END IF

   -- Step 4: Return the updated record as the response body
   RETURN rec
END FUNCTION #update

-- =====================================================================
-- Function: remove
-- HTTP    : DELETE /api/customer-demographics/{p_customertypeid}
-- Purpose : Delete a single customerdemographics row identified by its
--           primary key in the URL path.
--
-- Process:
--   1. Extract the primary key from the URL path parameter.
--   2. Set it on a local record so the model's deleteRec() method
--      knows which row to target.
--   3. Call deleteRec() which executes:
--        DELETE FROM customerdemographics
--         WHERE customertypeid = <pk>
--      and checks sqlca.sqlerrd[3] to confirm exactly one row was
--      removed.
--   4. If the delete fails (row not found, FK constraint, etc.),
--      return HTTP 404 with the error message.
--   5. On success, return a confirmation message as a JSON string.
-- =====================================================================
PUBLIC FUNCTION remove(
   p_customertypeid VARCHAR(20) ATTRIBUTES(WSParam))
   ATTRIBUTES(WSDelete,
      WSPath = "/customer-demographics/{p_customertypeid}",
      WSDescription = "Delete a customer demographics record",
      WSThrows = "404:@ws_error,500:@ws_error")
   RETURNS STRING ATTRIBUTES(WSMedia = "application/json")

   DEFINE rec t_cust_demo
   DEFINE del_status t_valid_rec

   -- Step 1: Build a record with the PK from the URL so deleteRec()
   --         knows which row to target
   LET rec.customertypeid = p_customertypeid

   -- Step 2: Execute the SQL DELETE via the model method
   LET del_status = rec.deleteRec()
   IF NOT del_status.valid_status THEN
      -- Delete failed — most likely the row does not exist, or a
      -- foreign key constraint prevented removal.  Return HTTP 404.
      LET ws_error.message = del_status.valid_msg
      CALL com.WebServiceEngine.SetRestError(404, ws_error)
      RETURN del_status.valid_msg
   END IF

   -- Step 3: Return the success message (e.g. "Customer Demo deleted")
   RETURN del_status.valid_msg
END FUNCTION #remove
