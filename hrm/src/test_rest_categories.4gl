-- =============================================================================
-- Module: test_rest_categories.4gl
-- Purpose: REST client to test the rest_categories web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_categories.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_category RECORD
   categoryid   INTEGER,
   categoryname STRING,
   description  STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/cat/categories"
   END IF
   CALL test_rest_lib.init_test_suite("REST Categories Service Test Suite", m_base_url)

   -- Run all tests in logical order
   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_category()
   CALL test_update_category()
   CALL test_delete_category()
   CALL test_full_lifecycle()

   -- Negative/error tests last (may crash server)
   CALL test_update_not_found()
   CALL test_delete_not_found()
   CALL test_create_invalid()

   -- Summary
   IF test_rest_lib.display_test_summary() > 0 THEN
      EXIT PROGRAM 1
   END IF
END MAIN

-- =============================================================================
-- Test: GET /categories — returns a list of categories
-- =============================================================================
FUNCTION test_get_all()
   DEFINE categories DYNAMIC ARRAY OF t_category
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /categories (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, categories)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   IF categories.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one category, got 0")
      RETURN
   END IF

   -- Verify first record has required fields
   IF categories[1].categoryname IS NULL OR categories[1].categoryname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("First category has NULL/empty categoryname")
      RETURN
   END IF

   -- DB validation: compare REST count with database count
   SELECT COUNT(*) INTO db_count FROM categories
   IF db_count != categories.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 categories but DB has %2",
         categories.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 categories (matches DB)", categories.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /categories/{id} — returns a single category
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE cat t_category
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_name STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: GET /categories/1 (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/1", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, cat)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF cat.categoryid != 1 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected categoryid=1, got %1", cat.categoryid))
      RETURN
   END IF

   IF cat.categoryname IS NULL OR cat.categoryname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Category name is NULL/empty")
      RETURN
   END IF

   -- DB validation: compare REST response with database record
   SELECT categoryname, description INTO db_name, db_desc
      FROM categories WHERE categoryid = 1
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Category ID=1 not found in database")
      RETURN
   END IF
   IF cat.categoryname != db_name THEN
      CALL test_rest_lib.test_fail(SFMT("REST name '%1' != DB name '%2'",
         cat.categoryname, db_name))
      RETURN
   END IF
   IF cat.description != db_desc THEN
      CALL test_rest_lib.test_fail(SFMT("REST description '%1' != DB description '%2'",
         cat.description, db_desc))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got category: %1 (matches DB)", cat.categoryname))
END FUNCTION

-- =============================================================================
-- Test: GET /categories/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /categories/99999 (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /categories — create a new category
-- =============================================================================
FUNCTION test_create_category()
   DEFINE new_cat t_category
   DEFINE created_cat t_category
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_name STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: POST /categories (create) ..."

   LET new_cat.categoryname = "Test Category"
   LET new_cat.description = "Created by test_rest_categories"

   LET json_body = util.JSON.stringify(new_cat)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_cat)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   IF created_cat.categoryid IS NULL OR created_cat.categoryid = 0 THEN
      CALL test_rest_lib.test_fail("Created category has no ID assigned")
      RETURN
   END IF

   IF created_cat.categoryname != "Test Category" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Test Category', got '%1'", created_cat.categoryname))
      RETURN
   END IF

   -- DB validation: verify record exists in database
   SELECT categoryname, description INTO db_name, db_desc
      FROM categories WHERE categoryid = created_cat.categoryid
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created category ID=%1 not found in database",
         created_cat.categoryid))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_cat.categoryid))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Test Category" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Test Category'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_cat.categoryid))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up: delete the created record
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_cat.categoryid))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Created category ID=%1, verified in DB, cleaned up", created_cat.categoryid))
END FUNCTION

-- =============================================================================
-- Test: POST /categories — 400 for invalid data (missing name)
-- =============================================================================
FUNCTION test_create_invalid()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created t_category

   DISPLAY "TEST: POST /categories (invalid - missing name) ..."

   LET json_body = '{"categoryname":"","description":"No name"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      -- If the server returned success, clean up
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created)
            IF created.categoryid > 0 THEN
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created.categoryid))
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
-- Test: PUT /categories/{id} — update an existing category
-- =============================================================================
FUNCTION test_update_category()
   DEFINE new_cat t_category
   DEFINE updated_cat t_category
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING
   DEFINE db_desc STRING

   DISPLAY "TEST: PUT /categories/{id} (update) ..."

   -- First create a record to update
   LET new_cat.categoryname = "Update Test"
   LET new_cat.description = "Will be updated"
   LET json_body = util.JSON.stringify(new_cat)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create category, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_cat)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created category")
      RETURN
   END TRY
   LET created_id = new_cat.categoryid

   -- Now update it
   LET new_cat.categoryname = "Updated Cat"
   LET new_cat.description = "Updated by test"
   LET json_body = util.JSON.stringify(new_cat)

   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      -- Clean up
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_cat)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_cat.categoryname != "Updated Cat" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected name 'Updated Category', got '%1'", updated_cat.categoryname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT categoryname, description INTO db_name, db_desc
      FROM categories WHERE categoryid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Updated category ID=%1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Updated Cat" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Updated Cat'", db_name))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_desc != "Updated by test" THEN
      CALL test_rest_lib.test_fail(SFMT("DB description '%1' != expected 'Updated by test'", db_desc))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Updated category ID=%1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: PUT /categories/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /categories/99999 (not found) ..."

   LET json_body = '{"categoryname":"Ghost","description":"Does not exist"}'
   CALL test_rest_lib.http_put(SFMT("%1/99999", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /categories/{id} — delete a category
-- =============================================================================
FUNCTION test_delete_category()
   DEFINE new_cat t_category
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: DELETE /categories/{id} (delete) ..."

   -- Create a record to delete
   LET new_cat.categoryname = "Delete Test"
   LET new_cat.description = "Will be deleted"
   LET json_body = util.JSON.stringify(new_cat)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create category, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_cat)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created category")
      RETURN
   END TRY

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, new_cat.categoryid))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, new_cat.categoryid))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation: verify record no longer exists in database
   SELECT COUNT(*) INTO db_count FROM categories
      WHERE categoryid = new_cat.categoryid
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Category ID=%1 still exists in DB after delete",
         new_cat.categoryid))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Deleted category ID=%1, verified 404 and gone from DB",
      new_cat.categoryid))
END FUNCTION

-- =============================================================================
-- Test: DELETE /categories/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /categories/99999 (not found) ..."

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
   DEFINE cat t_category
   DEFINE verified t_category
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_id INTEGER
   DEFINE db_name STRING
   DEFINE db_desc STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET cat.categoryname = "Lifecycle Test"
   LET cat.description = "Full lifecycle test record"
   LET json_body = util.JSON.stringify(cat)
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, cat)
   LET created_id = cat.categoryid

   IF created_id IS NULL OR created_id = 0 THEN
      CALL test_rest_lib.test_fail("CREATE returned no ID")
      RETURN
   END IF

   -- DB validation: verify created record in database
   SELECT categoryname, description INTO db_name, db_desc
      FROM categories WHERE categoryid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created category ID=%1 not found in DB", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_name != "Lifecycle Test" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Test'", db_name))
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
   IF verified.categoryname != "Lifecycle Test" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong name: '%1'", verified.categoryname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE
   LET cat.categoryname = "Lifecycle Upd"
   LET cat.description = "Updated in lifecycle test"
   LET json_body = util.JSON.stringify(cat)
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
   IF verified.categoryname != "Lifecycle Upd" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, name='%1', expected 'Lifecycle Updated'", verified.categoryname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify updated values in database
   SELECT categoryname, description INTO db_name, db_desc
      FROM categories WHERE categoryid = created_id
   IF db_name != "Lifecycle Upd" THEN
      CALL test_rest_lib.test_fail(SFMT("DB name '%1' != expected 'Lifecycle Upd'", db_name))
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
   SELECT COUNT(*) INTO db_count FROM categories
      WHERE categoryid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Category ID=%1 still in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Full lifecycle passed for ID=%1 (all DB checks passed)", created_id))
END FUNCTION
