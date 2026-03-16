-- =============================================================================
-- Module: test_rest_shippers.4gl
-- Purpose: REST client to test the rest_shippers web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_shippers.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_shipper RECORD
   shipperid   INTEGER,
   companyname STRING,
   phone       STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/ship/shippers"
   END IF
   CALL test_rest_lib.init_test_suite("REST Shippers Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_shipper()
   CALL test_update_shipper()
   CALL test_delete_shipper()
   CALL test_full_lifecycle()

   -- Negative/error tests last (may crash server)
   CALL test_update_not_found()
   CALL test_delete_not_found()
   CALL test_create_missing_name()
   CALL test_create_missing_phone()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Test: GET /shippers — returns a list of shippers
-- =============================================================================
FUNCTION test_get_all()
   DEFINE shippers DYNAMIC ARRAY OF t_shipper
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /shippers (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, shippers)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   IF shippers.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one shipper, got 0")
      RETURN
   END IF

   IF shippers[1].companyname IS NULL OR shippers[1].companyname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("First shipper has NULL/empty companyname")
      RETURN
   END IF

   -- DB validation: compare REST count with database count
   SELECT COUNT(*) INTO db_count FROM shippers
   IF db_count != shippers.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 shippers but DB has %2",
         shippers.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 shippers (matches DB)", shippers.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /shippers/{id} — returns a single shipper
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE ship t_shipper
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_name STRING
   DEFINE db_phone STRING

   DISPLAY "TEST: GET /shippers/1 (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/1", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, ship)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF ship.shipperid != 1 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected shipperid=1, got %1", ship.shipperid))
      RETURN
   END IF

   IF ship.companyname IS NULL OR ship.companyname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Shipper companyname is NULL/empty")
      RETURN
   END IF

   IF ship.phone IS NULL OR ship.phone.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Shipper phone is NULL/empty")
      RETURN
   END IF

   -- DB validation: compare REST response with database record
   SELECT companyname, phone INTO db_name, db_phone
      FROM shippers WHERE shipperid = 1
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Shipper ID=1 not found in database")
      RETURN
   END IF
   IF ship.companyname != db_name THEN
      CALL test_rest_lib.test_fail(SFMT("REST name '%1' != DB name '%2'",
         ship.companyname, db_name))
      RETURN
   END IF
   IF ship.phone != db_phone THEN
      CALL test_rest_lib.test_fail(SFMT("REST phone '%1' != DB phone '%2'",
         ship.phone, db_phone))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got shipper: %1, phone: %2 (matches DB)",
      ship.companyname, ship.phone))
END FUNCTION

-- =============================================================================
-- Test: GET /shippers/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /shippers/99999 (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /shippers — create a new shipper
-- =============================================================================
FUNCTION test_create_shipper()
   DEFINE new_ship t_shipper
   DEFINE created_ship t_shipper
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_name STRING
   DEFINE db_phone STRING

   DISPLAY "TEST: POST /shippers (create) ..."

   LET new_ship.companyname = "Test Shipping Co"
   LET new_ship.phone = "(555) 100-0001"

   LET json_body = util.JSON.stringify(new_ship)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_ship)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   IF created_ship.shipperid IS NULL OR created_ship.shipperid = 0 THEN
      CALL test_rest_lib.test_fail("Created shipper has no ID assigned")
      RETURN
   END IF

   IF created_ship.companyname != "Test Shipping Co" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Test Shipping Co', got '%1'", created_ship.companyname))
      RETURN
   END IF

   -- DB validation: verify record exists in database
   SELECT companyname, phone INTO db_name, db_phone
      FROM shippers WHERE shipperid = created_ship.shipperid
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created shipper ID=%1 not found in database",
         created_ship.shipperid))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_ship.shipperid))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Test Shipping Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Test Shipping Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_ship.shipperid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_ship.shipperid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Created shipper ID=%1, verified in DB, cleaned up",
      created_ship.shipperid))
END FUNCTION

-- =============================================================================
-- Test: POST /shippers — 400 for missing company name
-- =============================================================================
FUNCTION test_create_missing_name()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created t_shipper

   DISPLAY "TEST: POST /shippers (invalid - missing name) ..."

   LET json_body = '{"companyname":"","phone":"(555) 000-0000"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created)
            IF created.shipperid > 0 THEN
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created.shipperid))
                  RETURNING status_code, response_body
            END IF
         CATCH
         END TRY
      END IF
      CALL test_rest_lib.test_fail(SFMT("Expected status 400, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 400 validation error as expected (missing name)")
END FUNCTION

-- =============================================================================
-- Test: POST /shippers — 400 for missing phone
-- =============================================================================
FUNCTION test_create_missing_phone()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created t_shipper

   DISPLAY "TEST: POST /shippers (invalid - missing phone) ..."

   LET json_body = '{"companyname":"No Phone Shipping"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created)
            IF created.shipperid > 0 THEN
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created.shipperid))
                  RETURNING status_code, response_body
            END IF
         CATCH
         END TRY
      END IF
      CALL test_rest_lib.test_fail(SFMT("Expected status 400, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 400 validation error as expected (missing phone)")
END FUNCTION

-- =============================================================================
-- Test: PUT /shippers/{id} — update an existing shipper
-- =============================================================================
FUNCTION test_update_shipper()
   DEFINE new_ship t_shipper
   DEFINE updated_ship t_shipper
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING
   DEFINE db_phone STRING

   DISPLAY "TEST: PUT /shippers/{id} (update) ..."

   -- Create a record to update
   LET new_ship.companyname = "Update Test Shipping"
   LET new_ship.phone = "(555) 200-0001"
   LET json_body = util.JSON.stringify(new_ship)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create shipper, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_ship)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created shipper")
      RETURN
   END TRY
   LET created_id = new_ship.shipperid

   -- Update it
   LET new_ship.companyname = "Updated Shipping Co"
   LET new_ship.phone = "(555) 200-9999"
   LET json_body = util.JSON.stringify(new_ship)

   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_ship)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_ship.companyname != "Updated Shipping Co" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Updated Shipping Co', got '%1'", updated_ship.companyname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   IF updated_ship.phone != "(555) 200-9999" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected phone '(555) 200-9999', got '%1'", updated_ship.phone))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT companyname, phone INTO db_name, db_phone
      FROM shippers WHERE shipperid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Updated shipper ID=%1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Updated Shipping Co" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Updated Shipping Co'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_phone != "(555) 200-9999" THEN
      CALL test_rest_lib.test_fail(SFMT("DB phone '%1' != expected '(555) 200-9999'", db_phone))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Updated shipper ID=%1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: PUT /shippers/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /shippers/99999 (not found) ..."

   LET json_body = '{"companyname":"Ghost Shipping","phone":"(555) 000-0000"}'
   CALL test_rest_lib.http_put(SFMT("%1/99999", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /shippers/{id} — delete a shipper
-- =============================================================================
FUNCTION test_delete_shipper()
   DEFINE new_ship t_shipper
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /shippers/{id} (delete) ..."

   -- Create a record to delete
   LET new_ship.companyname = "Delete Test Shipping"
   LET new_ship.phone = "(555) 300-0001"
   LET json_body = util.JSON.stringify(new_ship)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create shipper, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_ship)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created shipper")
      RETURN
   END TRY

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, new_ship.shipperid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, new_ship.shipperid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM shippers
      WHERE shipperid = new_ship.shipperid
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Shipper ID=%1 still exists in DB after delete",
         new_ship.shipperid))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Deleted shipper ID=%1, verified 404 and gone from DB",
      new_ship.shipperid))
END FUNCTION

-- =============================================================================
-- Test: DELETE /shippers/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /shippers/99999 (not found) ..."

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
   DEFINE ship t_shipper
   DEFINE verified t_shipper
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING
   DEFINE db_phone STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET ship.companyname = "Lifecycle Shipping"
   LET ship.phone = "(555) 400-0001"
   LET json_body = util.JSON.stringify(ship)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, ship)
   LET created_id = ship.shipperid

   IF created_id IS NULL OR created_id = 0 THEN
      CALL test_rest_lib.test_fail("CREATE returned no ID")
      RETURN
   END IF

   -- DB validation: verify created record in database
   SELECT companyname, phone INTO db_name, db_phone
      FROM shippers WHERE shipperid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created shipper ID=%1 not found in DB", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Lifecycle Shipping" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Shipping'", db_name))
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
   IF verified.companyname != "Lifecycle Shipping" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong name: '%1'", verified.companyname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   IF verified.phone != "(555) 400-0001" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong phone: '%1'", verified.phone))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET ship.companyname = "Lifecycle Updated"
   LET ship.phone = "(555) 400-9999"
   LET json_body = util.JSON.stringify(ship)
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
   IF verified.companyname != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, name='%1', expected 'Lifecycle Updated'", verified.companyname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   IF verified.phone != "(555) 400-9999" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, phone='%1', expected '(555) 400-9999'", verified.phone))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT companyname, phone INTO db_name, db_phone
      FROM shippers WHERE shipperid = created_id
   IF db_name != "Lifecycle Updated" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Updated'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_phone != "(555) 400-9999" THEN
      CALL test_rest_lib.test_fail(SFMT("DB phone '%1' != expected '(555) 400-9999'", db_phone))
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
   SELECT COUNT(*) INTO db_count FROM shippers
      WHERE shipperid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Shipper ID=%1 still in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Full lifecycle passed for ID=%1 (all DB checks passed)", created_id))
END FUNCTION
