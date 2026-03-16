-- =============================================================================
-- Module: test_rest_usstates.4gl
-- Purpose: REST client to test the rest_usstates web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_usstates.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_usstate RECORD
   stateid     INTEGER,
   statename   STRING,
   stateabbr   STRING,
   stateregion STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/st/usstates"
   END IF
   CALL test_rest_lib.init_test_suite("REST US States Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_usstate()
   CALL test_update_usstate()
   CALL test_delete_usstate()
   CALL test_full_lifecycle()

   -- Negative/error tests last
   CALL test_update_not_found()
   CALL test_delete_not_found()
   CALL test_create_empty()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Test: GET /usstates — returns a list of US states
-- =============================================================================
FUNCTION test_get_all()
   DEFINE states DYNAMIC ARRAY OF t_usstate
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /usstates (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, states)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   IF states.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one state, got 0")
      RETURN
   END IF

   IF states[1].statename IS NULL OR states[1].statename.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("First state has NULL/empty statename")
      RETURN
   END IF

   -- DB validation: compare REST count with database count
   SELECT COUNT(*) INTO db_count FROM usstates
   IF db_count != states.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 states but DB has %2",
         states.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 states (matches DB)", states.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /usstates/{id} — returns a single state
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE st t_usstate
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_name STRING
   DEFINE db_abbr STRING

   DISPLAY "TEST: GET /usstates/1 (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/1", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, st)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF st.stateid != 1 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected stateid=1, got %1", st.stateid))
      RETURN
   END IF

   IF st.statename IS NULL OR st.statename.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("State statename is NULL/empty")
      RETURN
   END IF

   -- DB validation: compare REST response with database record
   SELECT statename, stateabbr INTO db_name, db_abbr
      FROM usstates WHERE stateid = 1
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("State ID=1 not found in database")
      RETURN
   END IF
   IF st.statename != db_name THEN
      CALL test_rest_lib.test_fail(SFMT("REST name '%1' != DB name '%2'",
         st.statename, db_name))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got state: %1 (%2) (matches DB)", st.statename, db_abbr))
END FUNCTION

-- =============================================================================
-- Test: GET /usstates/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /usstates/99999 (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /usstates — create a new state
-- =============================================================================
FUNCTION test_create_usstate()
   DEFINE new_st t_usstate
   DEFINE created_st t_usstate
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_name STRING

   DISPLAY "TEST: POST /usstates (create) ..."

   LET new_st.statename = "Test State"
   LET new_st.stateabbr = "TS"
   LET new_st.stateregion = "test"

   LET json_body = util.JSON.stringify(new_st)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_st)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   IF created_st.stateid IS NULL OR created_st.stateid = 0 THEN
      CALL test_rest_lib.test_fail("Created state has no ID assigned")
      RETURN
   END IF

   IF created_st.statename != "Test State" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Test State', got '%1'", created_st.statename))
      RETURN
   END IF

   -- DB validation: verify record exists in database
   SELECT statename INTO db_name
      FROM usstates WHERE stateid = created_st.stateid
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created state ID=%1 not found in database",
         created_st.stateid))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_st.stateid))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Test State" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Test State'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_st.stateid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_st.stateid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Created state ID=%1, verified in DB, cleaned up",
      created_st.stateid))
END FUNCTION

-- =============================================================================
-- Test: POST /usstates — create with empty fields (minimal validation)
-- =============================================================================
FUNCTION test_create_empty()
   DEFINE new_st t_usstate
   DEFINE created_st t_usstate
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: POST /usstates (empty fields) ..."

   -- usstates has minimal validation - empty fields may succeed
   LET json_body = '{"statename":"","stateabbr":"","stateregion":""}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   -- Accept either 200/201 (minimal validation) or 400 (if validation was added)
   IF status_code >= 200 AND status_code <= 201 THEN
      TRY
         CALL util.JSON.parse(response_body, created_st)
         IF created_st.stateid > 0 THEN
            CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_st.stateid))
               RETURNING status_code, response_body
         END IF
      CATCH
      END TRY
      CALL test_rest_lib.test_pass("Create with empty fields succeeded (minimal validation)")
   ELSE
      IF status_code = 400 THEN
         CALL test_rest_lib.test_pass("Got 400 validation error for empty fields")
      ELSE
         CALL test_rest_lib.test_fail(SFMT("Unexpected status %1", status_code))
      END IF
   END IF
END FUNCTION

-- =============================================================================
-- Test: PUT /usstates/{id} — update an existing state
-- =============================================================================
FUNCTION test_update_usstate()
   DEFINE new_st t_usstate
   DEFINE updated_st t_usstate
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING
   DEFINE db_abbr STRING

   DISPLAY "TEST: PUT /usstates/{id} (update) ..."

   -- Create a record to update
   LET new_st.statename = "Update Test State"
   LET new_st.stateabbr = "UT"
   LET new_st.stateregion = "test"
   LET json_body = util.JSON.stringify(new_st)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create state, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_st)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created state")
      RETURN
   END TRY
   LET created_id = new_st.stateid

   -- Update it
   LET new_st.statename = "Updated State"
   LET new_st.stateabbr = "US"
   LET new_st.stateregion = "updated"
   LET json_body = util.JSON.stringify(new_st)

   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_st)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_st.statename != "Updated State" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Updated State', got '%1'", updated_st.statename))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT statename, stateabbr INTO db_name, db_abbr
      FROM usstates WHERE stateid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Updated state ID=%1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Updated State" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Updated State'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Updated state ID=%1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: PUT /usstates/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /usstates/99999 (not found) ..."

   LET json_body = '{"statename":"Ghost State","stateabbr":"GS","stateregion":"none"}'
   CALL test_rest_lib.http_put(SFMT("%1/99999", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /usstates/{id} — delete a state
-- =============================================================================
FUNCTION test_delete_usstate()
   DEFINE new_st t_usstate
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /usstates/{id} (delete) ..."

   -- Create a record to delete
   LET new_st.statename = "Delete Test State"
   LET new_st.stateabbr = "DT"
   LET new_st.stateregion = "test"
   LET json_body = util.JSON.stringify(new_st)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create state, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_st)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created state")
      RETURN
   END TRY

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, new_st.stateid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, new_st.stateid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM usstates
      WHERE stateid = new_st.stateid
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("State ID=%1 still exists in DB after delete",
         new_st.stateid))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Deleted state ID=%1, verified 404 and gone from DB",
      new_st.stateid))
END FUNCTION

-- =============================================================================
-- Test: DELETE /usstates/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /usstates/99999 (not found) ..."

   CALL test_rest_lib.http_delete(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: Full lifecycle — create, read, update, verify, delete, verify gone
-- =============================================================================
FUNCTION test_full_lifecycle()
   DEFINE st t_usstate
   DEFINE verified t_usstate
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET st.statename = "Lifecycle State"
   LET st.stateabbr = "LS"
   LET st.stateregion = "test"
   LET json_body = util.JSON.stringify(st)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, st)
   LET created_id = st.stateid

   IF created_id IS NULL OR created_id = 0 THEN
      CALL test_rest_lib.test_fail("CREATE returned no ID")
      RETURN
   END IF

   -- DB validation: verify created record in database
   SELECT statename INTO db_name
      FROM usstates WHERE stateid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created state ID=%1 not found in DB", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 2. READ — verify it exists
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, created_id)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after CREATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.statename != "Lifecycle State" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong name: '%1'", verified.statename))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET st.statename = "Lifecycle Updated"
   LET st.stateabbr = "LU"
   LET json_body = util.JSON.stringify(st)
   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 4. READ — verify update took effect
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, created_id)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.statename != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, name='%1', expected 'Lifecycle Updated'", verified.statename))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT statename INTO db_name
      FROM usstates WHERE stateid = created_id
   IF db_name != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Updated'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 5. DELETE
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("DELETE failed: status=%1", status_code))
      RETURN
   END IF

   -- 6. READ — verify it's gone
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, created_id)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After DELETE, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM usstates
      WHERE stateid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("State ID=%1 still in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Full lifecycle passed for ID=%1 (all DB checks passed)", created_id))
END FUNCTION
