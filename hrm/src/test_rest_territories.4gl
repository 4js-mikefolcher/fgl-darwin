-- =============================================================================
-- Module: test_rest_territories.4gl
-- Purpose: REST client to test the rest_territories web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_territories.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_territory RECORD
   territoryid          STRING,
   territorydescription STRING,
   regionid             INTEGER
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/terr/territories"
   END IF
   CALL test_rest_lib.init_test_suite("REST Territories Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_territory()
   CALL test_update_territory()
   CALL test_delete_territory()
   CALL test_full_lifecycle()

   -- Negative/error tests last
   CALL test_update_not_found()
   CALL test_delete_not_found()
   CALL test_create_missing_fields()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Test: GET /territories — returns a list of territories
-- =============================================================================
FUNCTION test_get_all()
   DEFINE territories DYNAMIC ARRAY OF t_territory
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /territories (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, territories)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   IF territories.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one territory, got 0")
      RETURN
   END IF

   IF territories[1].territorydescription IS NULL OR territories[1].territorydescription.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("First territory has NULL/empty territorydescription")
      RETURN
   END IF

   -- DB validation: compare REST count with database count
   SELECT COUNT(*) INTO db_count FROM territories
   IF db_count != territories.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 territories but DB has %2",
         territories.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 territories (matches DB)", territories.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /territories/{id} — returns a single territory
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE terr t_territory
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: GET /territories/01581 (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/01581", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, terr)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF terr.territoryid IS NULL OR terr.territoryid.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Territory territoryid is NULL/empty")
      RETURN
   END IF

   IF terr.territorydescription IS NULL OR terr.territorydescription.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Territory territorydescription is NULL/empty")
      RETURN
   END IF

   -- DB validation: compare REST response with database record
   SELECT territorydescription INTO db_desc
      FROM territories WHERE territoryid = "01581"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Territory 01581 not found in database")
      RETURN
   END IF
   IF terr.territorydescription != db_desc THEN
      CALL test_rest_lib.test_fail(SFMT("REST desc '%1' != DB desc '%2'",
         terr.territorydescription, db_desc))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got territory: %1 (matches DB)", terr.territorydescription))
END FUNCTION

-- =============================================================================
-- Test: GET /territories/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /territories/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/ZZZZZ", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /territories — create a new territory
-- =============================================================================
FUNCTION test_create_territory()
   DEFINE new_terr t_territory
   DEFINE created_terr t_territory
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: POST /territories (create) ..."

   LET new_terr.territoryid = "TTEST"
   LET new_terr.territorydescription = "Test Territory"
   LET new_terr.regionid = 1

   LET json_body = util.JSON.stringify(new_terr)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_terr)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   IF created_terr.territorydescription != "Test Territory" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected desc 'Test Territory', got '%1'", created_terr.territorydescription))
      RETURN
   END IF

   -- DB validation: verify record exists in database
   SELECT territorydescription INTO db_desc
      FROM territories WHERE territoryid = "TTEST"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Created territory TTEST not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/TTEST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_desc != "Test Territory" THEN
      CALL test_rest_lib.test_fail(SFMT("DB desc '%1' != expected 'Test Territory'", db_desc))
      CALL test_rest_lib.http_delete(SFMT("%1/TTEST", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/TTEST", m_base_url))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Created territory TTEST, verified in DB, cleaned up")
END FUNCTION

-- =============================================================================
-- Test: POST /territories — 400 for missing required fields
-- =============================================================================
FUNCTION test_create_missing_fields()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created t_territory

   DISPLAY "TEST: POST /territories (invalid - missing description) ..."

   LET json_body = '{"territoryid":"BADTR","territorydescription":"","regionid":1}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created)
            IF created.territoryid IS NOT NULL AND created.territoryid.getLength() > 0 THEN
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created.territoryid))
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
-- Test: PUT /territories/{id} — update an existing territory
-- =============================================================================
FUNCTION test_update_territory()
   DEFINE new_terr t_territory
   DEFINE updated_terr t_territory
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: PUT /territories/{id} (update) ..."

   -- Create a record to update
   LET new_terr.territoryid = "UPDTR"
   LET new_terr.territorydescription = "Update Test Territory"
   LET new_terr.regionid = 1
   LET json_body = util.JSON.stringify(new_terr)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create territory, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_terr)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created territory")
      RETURN
   END TRY

   -- Update it
   LET new_terr.territorydescription = "Updated Territory"
   LET new_terr.regionid = 2
   LET json_body = util.JSON.stringify(new_terr)

   CALL test_rest_lib.http_put(SFMT("%1/UPDTR", m_base_url), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_terr)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_terr.territorydescription != "Updated Territory" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected desc 'Updated Territory', got '%1'", updated_terr.territorydescription))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT territorydescription INTO db_desc
      FROM territories WHERE territoryid = "UPDTR"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Updated territory UPDTR not found in database")
      CALL test_rest_lib.http_delete(SFMT("%1/UPDTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_desc != "Updated Territory" THEN
      CALL test_rest_lib.test_fail(SFMT("DB desc '%1' != expected 'Updated Territory'", db_desc))
      CALL test_rest_lib.http_delete(SFMT("%1/UPDTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/UPDTR", m_base_url))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass("Updated territory UPDTR, verified in DB, cleaned up")
END FUNCTION

-- =============================================================================
-- Test: PUT /territories/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /territories/ZZZZZ (not found) ..."

   LET json_body = '{"territorydescription":"Ghost Territory","regionid":1}'
   CALL test_rest_lib.http_put(SFMT("%1/ZZZZZ", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /territories/{id} — delete a territory
-- =============================================================================
FUNCTION test_delete_territory()
   DEFINE new_terr t_territory
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /territories/{id} (delete) ..."

   -- Create a record to delete
   LET new_terr.territoryid = "DELTR"
   LET new_terr.territorydescription = "Delete Test Territory"
   LET new_terr.regionid = 1
   LET json_body = util.JSON.stringify(new_terr)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create territory, status=%1", status_code))
      RETURN
   END IF

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/DELTR", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/DELTR", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM territories
      WHERE territoryid = "DELTR"
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Territory DELTR still exists in DB after delete")
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Deleted territory DELTR, verified 404 and gone from DB")
END FUNCTION

-- =============================================================================
-- Test: DELETE /territories/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /territories/ZZZZZ (not found) ..."

   CALL test_rest_lib.http_delete(SFMT("%1/ZZZZZ", m_base_url)) RETURNING status_code, response_body

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
   DEFINE terr t_territory
   DEFINE verified t_territory
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_desc STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET terr.territoryid = "LFCTR"
   LET terr.territorydescription = "Lifecycle Territory"
   LET terr.regionid = 1
   LET json_body = util.JSON.stringify(terr)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, terr)

   -- DB validation: verify created record in database
   SELECT territorydescription INTO db_desc
      FROM territories WHERE territoryid = "LFCTR"
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Created territory LFCTR not found in DB")
      CALL test_rest_lib.http_delete(SFMT("%1/LFCTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 2. READ — verify it exists
   CALL test_rest_lib.http_get(SFMT("%1/LFCTR", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after CREATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.territorydescription != "Lifecycle Territory" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong desc: '%1'", verified.territorydescription))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET terr.territorydescription = "Lifecycle Updated"
   LET terr.regionid = 2
   LET json_body = util.JSON.stringify(terr)
   CALL test_rest_lib.http_put(SFMT("%1/LFCTR", m_base_url), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 4. READ — verify update took effect
   CALL test_rest_lib.http_get(SFMT("%1/LFCTR", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("READ after UPDATE failed: status=%1", status_code))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   CALL util.JSON.parse(response_body, verified)
   IF verified.territorydescription != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, desc='%1', expected 'Lifecycle Updated'", verified.territorydescription))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT territorydescription INTO db_desc
      FROM territories WHERE territoryid = "LFCTR"
   IF db_desc != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("DB desc '%1' != expected 'Lifecycle Updated'", db_desc))
      CALL test_rest_lib.http_delete(SFMT("%1/LFCTR", m_base_url))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 5. DELETE
   CALL test_rest_lib.http_delete(SFMT("%1/LFCTR", m_base_url))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("DELETE failed: status=%1", status_code))
      RETURN
   END IF

   -- 6. READ — verify it's gone
   CALL test_rest_lib.http_get(SFMT("%1/LFCTR", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After DELETE, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM territories
      WHERE territoryid = "LFCTR"
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail("Territory LFCTR still in DB after delete")
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Full lifecycle passed for LFCTR (all DB checks passed)")
END FUNCTION
