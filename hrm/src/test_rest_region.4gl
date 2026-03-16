-- =============================================================================
-- Module: test_rest_region.4gl
-- Purpose: REST client to test the rest_region web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_region.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_region RECORD
   regionid          INTEGER,
   regiondescription STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/regn/regions"
   END IF
   CALL test_rest_lib.init_test_suite("REST Region Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_region()
   CALL test_update_region()
   CALL test_delete_region()
   CALL test_full_lifecycle()

   -- Negative/error tests last
   CALL test_update_not_found()
   CALL test_delete_not_found()
   CALL test_create_missing_description()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Test: GET /regions — returns a list of regions
-- =============================================================================
FUNCTION test_get_all()
   DEFINE regions DYNAMIC ARRAY OF t_region
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /regions (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, regions)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   IF regions.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one region, got 0")
      RETURN
   END IF

   IF regions[1].regiondescription IS NULL OR regions[1].regiondescription.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("First region has NULL/empty regiondescription")
      RETURN
   END IF

   -- DB validation: compare REST count with database count
   SELECT COUNT(*) INTO db_count FROM region
   IF db_count != regions.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 regions but DB has %2",
         regions.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 regions (matches DB)", regions.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /regions/{id} — returns a single region
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE reg t_region
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: GET /regions/1 (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/1", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, reg)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF reg.regionid != 1 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected regionid=1, got %1", reg.regionid))
      RETURN
   END IF

   IF reg.regiondescription IS NULL OR reg.regiondescription.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Region regiondescription is NULL/empty")
      RETURN
   END IF

   -- DB validation: compare REST response with database record
   SELECT regiondescription INTO db_desc
      FROM region WHERE regionid = 1
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Region ID=1 not found in database")
      RETURN
   END IF
   IF reg.regiondescription != db_desc THEN
      CALL test_rest_lib.test_fail(SFMT("REST desc '%1' != DB desc '%2'",
         reg.regiondescription, db_desc))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got region: %1 (matches DB)", reg.regiondescription))
END FUNCTION

-- =============================================================================
-- Test: GET /regions/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /regions/99999 (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /regions — create a new region
-- =============================================================================
FUNCTION test_create_region()
   DEFINE new_reg t_region
   DEFINE created_reg t_region
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: POST /regions (create) ..."

   LET new_reg.regiondescription = "Test Region"

   LET json_body = util.JSON.stringify(new_reg)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_reg)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   IF created_reg.regionid IS NULL OR created_reg.regionid = 0 THEN
      CALL test_rest_lib.test_fail("Created region has no ID assigned")
      RETURN
   END IF

   IF created_reg.regiondescription != "Test Region" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected desc 'Test Region', got '%1'", created_reg.regiondescription))
      RETURN
   END IF

   -- DB validation: verify record exists in database
   SELECT regiondescription INTO db_desc
      FROM region WHERE regionid = created_reg.regionid
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created region ID=%1 not found in database",
         created_reg.regionid))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_reg.regionid))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_desc != "Test Region" THEN
      CALL test_rest_lib.test_fail(SFMT("DB desc '%1' != expected 'Test Region'", db_desc))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_reg.regionid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_reg.regionid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Created region ID=%1, verified in DB, cleaned up",
      created_reg.regionid))
END FUNCTION

-- =============================================================================
-- Test: POST /regions — 400 for missing description
-- =============================================================================
FUNCTION test_create_missing_description()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created t_region

   DISPLAY "TEST: POST /regions (invalid - missing description) ..."

   LET json_body = '{"regiondescription":""}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created)
            IF created.regionid > 0 THEN
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created.regionid))
                  RETURNING status_code, response_body
            END IF
         CATCH
         END TRY
      END IF
      CALL test_rest_lib.test_fail(SFMT("Expected status 400, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 400 validation error as expected")
END FUNCTION

-- =============================================================================
-- Test: PUT /regions/{id} — update an existing region
-- =============================================================================
FUNCTION test_update_region()
   DEFINE new_reg t_region
   DEFINE updated_reg t_region
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_desc STRING

   DISPLAY "TEST: PUT /regions/{id} (update) ..."

   -- Create a record to update
   LET new_reg.regiondescription = "Update Test Region"
   LET json_body = util.JSON.stringify(new_reg)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create region, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_reg)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created region")
      RETURN
   END TRY
   LET created_id = new_reg.regionid

   -- Update it
   LET new_reg.regiondescription = "Updated Region"
   LET json_body = util.JSON.stringify(new_reg)

   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_reg)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_reg.regiondescription != "Updated Region" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected desc 'Updated Region', got '%1'", updated_reg.regiondescription))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT regiondescription INTO db_desc
      FROM region WHERE regionid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Updated region ID=%1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_desc != "Updated Region" THEN
      CALL test_rest_lib.test_fail(SFMT("DB desc '%1' != expected 'Updated Region'", db_desc))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Updated region ID=%1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: PUT /regions/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /regions/99999 (not found) ..."

   LET json_body = '{"regiondescription":"Ghost Region"}'
   CALL test_rest_lib.http_put(SFMT("%1/99999", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /regions/{id} — delete a region
-- =============================================================================
FUNCTION test_delete_region()
   DEFINE new_reg t_region
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /regions/{id} (delete) ..."

   -- Create a record to delete
   LET new_reg.regiondescription = "Delete Test Region"
   LET json_body = util.JSON.stringify(new_reg)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create region, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_reg)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created region")
      RETURN
   END TRY

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, new_reg.regionid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, new_reg.regionid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM region
      WHERE regionid = new_reg.regionid
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Region ID=%1 still exists in DB after delete",
         new_reg.regionid))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Deleted region ID=%1, verified 404 and gone from DB",
      new_reg.regionid))
END FUNCTION

-- =============================================================================
-- Test: DELETE /regions/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /regions/99999 (not found) ..."

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
   DEFINE reg t_region
   DEFINE verified t_region
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_desc STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET reg.regiondescription = "Lifecycle Region"
   LET json_body = util.JSON.stringify(reg)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, reg)
   LET created_id = reg.regionid

   IF created_id IS NULL OR created_id = 0 THEN
      CALL test_rest_lib.test_fail("CREATE returned no ID")
      RETURN
   END IF

   -- DB validation: verify created record in database
   SELECT regiondescription INTO db_desc
      FROM region WHERE regionid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created region ID=%1 not found in DB", created_id))
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
   IF verified.regiondescription != "Lifecycle Region" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong desc: '%1'", verified.regiondescription))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET reg.regiondescription = "Lifecycle Updated"
   LET json_body = util.JSON.stringify(reg)
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
   IF verified.regiondescription != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, desc='%1', expected 'Lifecycle Updated'", verified.regiondescription))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT regiondescription INTO db_desc
      FROM region WHERE regionid = created_id
   IF db_desc != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("DB desc '%1' != expected 'Lifecycle Updated'", db_desc))
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
   SELECT COUNT(*) INTO db_count FROM region
      WHERE regionid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Region ID=%1 still in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Full lifecycle passed for ID=%1 (all DB checks passed)", created_id))
END FUNCTION
