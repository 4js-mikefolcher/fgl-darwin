-- =============================================================================
-- Module: test_rest_employees.4gl
-- Purpose: REST client to test the rest_employees web service endpoints
-- Usage:  FGLGUI=0 fglrun test_rest_employees.42m
-- Server: Expects REST server running at http://localhost:8899
-- =============================================================================
IMPORT FGL test_rest_lib
IMPORT util

DATABASE northwind

DEFINE m_base_url STRING

TYPE t_employee RECORD
   employeeid       STRING,
   lastname         STRING,
   firstname        STRING,
   title            STRING,
   titleofcourtesy  STRING,
   birthdate        STRING,
   hiredate         STRING,
   address          STRING,
   city             STRING,
   region           STRING,
   postalcode       STRING,
   country          STRING,
   homephone        STRING,
   extension        STRING,
   reportsto        STRING,
   fullname         STRING,
   photopath        STRING,
   notes            STRING
END RECORD

-- =============================================================================
MAIN
-- =============================================================================
   LET m_base_url = fgl_getenv("TEST_BASE_URL")
   IF m_base_url.getLength() = 0 THEN
      LET m_base_url = "http://localhost:8899/emp/employees"
   END IF
   CALL test_rest_lib.init_test_suite("REST Employees Service Test Suite", m_base_url)

   -- Read-only tests first
   CALL test_get_all()
   CALL test_get_by_id()
   CALL test_get_not_found()

   -- CRUD tests
   CALL test_create_employee()
   CALL test_update_employee()
   CALL test_delete_employee()
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
-- Test: GET /employees — returns a list of employees
-- =============================================================================
FUNCTION test_get_all()
   DEFINE employees DYNAMIC ARRAY OF t_employee
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_count INTEGER

   DISPLAY "TEST: GET /employees (get all) ..."

   CALL test_rest_lib.http_get(m_base_url) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, employees)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON response: %1", response_body))
      RETURN
   END TRY

   IF employees.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Expected at least one employee, got 0")
      RETURN
   END IF

   IF employees[1].lastname IS NULL OR employees[1].lastname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("First employee has NULL/empty lastname")
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM employees
   IF db_count != employees.getLength() THEN
      CALL test_rest_lib.test_fail(SFMT("REST returned %1 employees but DB has %2",
         employees.getLength(), db_count))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Returned %1 employees (matches DB)", employees.getLength()))
END FUNCTION

-- =============================================================================
-- Test: GET /employees/{id} — returns a single employee
-- =============================================================================
FUNCTION test_get_by_id()
   DEFINE emp t_employee
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE db_lastname STRING

   DISPLAY "TEST: GET /employees/1 (get by ID) ..."

   CALL test_rest_lib.http_get(SFMT("%1/1", m_base_url)) RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, emp)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse JSON: %1", response_body))
      RETURN
   END TRY

   IF emp.lastname IS NULL OR emp.lastname.getLength() = 0 THEN
      CALL test_rest_lib.test_fail("Employee lastname is NULL/empty")
      RETURN
   END IF

   -- DB validation
   SELECT lastname INTO db_lastname
      FROM employees WHERE employeeid = 1
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail("Employee 1 not found in database")
      RETURN
   END IF
   IF emp.lastname != db_lastname THEN
      CALL test_rest_lib.test_fail(SFMT("REST lastname '%1' != DB '%2'", emp.lastname, db_lastname))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got employee: %1 %2 (matches DB)", emp.firstname, emp.lastname))
END FUNCTION

-- =============================================================================
-- Test: GET /employees/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_get_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: GET /employees/99999 (not found) ..."

   CALL test_rest_lib.http_get(SFMT("%1/99999", m_base_url)) RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass("Got 404 as expected")
END FUNCTION

-- =============================================================================
-- Test: POST /employees — create a new employee
-- =============================================================================
FUNCTION test_create_employee()
   DEFINE new_emp t_employee
   DEFINE created_emp t_employee
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_lastname STRING
   DEFINE created_id INTEGER

   DISPLAY "TEST: POST /employees (create) ..."

   LET json_body = '{"lastname":"TestLast","firstname":"TestFirst","title":"Tester","birthdate":"1990-01-15","hiredate":"2024-01-01","reportsto":1}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200/201, got %1 body=%2", status_code, response_body))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, created_emp)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse response: %1", response_body))
      RETURN
   END TRY

   LET created_id = created_emp.employeeid
   IF created_id IS NULL OR created_id = 0 THEN
      CALL test_rest_lib.test_fail("Created employee has NULL/0 employeeid")
      RETURN
   END IF

   IF created_emp.lastname != "TestLast" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected lastname 'TestLast', got '%1'", created_emp.lastname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation
   SELECT lastname INTO db_lastname
      FROM employees WHERE employeeid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created employee %1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_lastname != "TestLast" THEN
      CALL test_rest_lib.test_fail(SFMT("DB lastname '%1' != expected 'TestLast'", db_lastname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Created employee %1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: POST /employees — 400 for missing required fields
-- =============================================================================
FUNCTION test_create_missing_fields()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE created_emp t_employee

   DISPLAY "TEST: POST /employees (invalid - missing lastname) ..."

   -- Missing lastname and firstname (required)
   LET json_body = '{"lastname":"","firstname":"","birthdate":"1990-01-15","hiredate":"2024-01-01"}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code != 400 THEN
      IF status_code >= 200 AND status_code < 300 THEN
         TRY
            CALL util.JSON.parse(response_body, created_emp)
            IF created_emp.employeeid IS NOT NULL THEN
               LET json_body = created_emp.employeeid
               CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, json_body))
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
-- Test: PUT /employees/{id} — update an existing employee
-- =============================================================================
FUNCTION test_update_employee()
   DEFINE new_emp t_employee
   DEFINE updated_emp t_employee
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_title STRING
   DEFINE created_id INTEGER

   DISPLAY "TEST: PUT /employees/{id} (update) ..."

   -- Create a record to update
   LET json_body = '{"lastname":"UpdLast","firstname":"UpdFirst","title":"Original","birthdate":"1985-06-15","hiredate":"2023-03-01","reportsto":1}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create employee, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_emp)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created employee")
      RETURN
   END TRY
   LET created_id = new_emp.employeeid

   -- Update it — use hand-crafted JSON to avoid empty-string-for-null issues
   LET json_body = SFMT('{\"employeeid\":%1,\"lastname\":\"UpdLast\",\"firstname\":\"UpdFirst\",\"title\":\"Updated Title\",\"birthdate\":\"1985-06-15\",\"hiredate\":\"2023-03-01\",\"reportsto\":1}', created_id)

   CALL test_rest_lib.http_put(SFMT("%1/%2", m_base_url, created_id), json_body)
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1 body=%2", status_code, response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, updated_emp)
   CATCH
      CALL test_rest_lib.test_fail(SFMT("Failed to parse update response: %1", response_body))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END TRY

   IF updated_emp.title != "Updated Title" THEN
      CALL test_rest_lib.test_fail(SFMT("Expected title 'Updated Title', got '%1'", updated_emp.title))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation
   SELECT title INTO db_title
      FROM employees WHERE employeeid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Updated employee %1 not found in database", created_id))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF
   IF db_title != "Updated Title" THEN
      CALL test_rest_lib.test_fail(SFMT("DB title '%1' != expected 'Updated Title'", db_title))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- Clean up
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   CALL test_rest_lib.test_pass(SFMT("Updated employee %1, verified in DB, cleaned up", created_id))
END FUNCTION

-- =============================================================================
-- Test: PUT /employees/{id} — 400/404 for non-existent ID
-- =============================================================================
FUNCTION test_update_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING

   DISPLAY "TEST: PUT /employees/99999 (not found) ..."

   LET json_body = '{"employeeid":99999,"lastname":"Ghost","firstname":"Employee","birthdate":"1990-01-01","hiredate":"2024-01-01"}'
   CALL test_rest_lib.http_put(SFMT("%1/99999", m_base_url), json_body) RETURNING status_code, response_body

   IF status_code != 400 AND status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 400 or 404, got %1", status_code))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Got %1 as expected for non-existent update", status_code))
END FUNCTION

-- =============================================================================
-- Test: DELETE /employees/{id} — delete an employee
-- =============================================================================
FUNCTION test_delete_employee()
   DEFINE new_emp t_employee
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_count INTEGER
   DEFINE created_id INTEGER

   DISPLAY "TEST: DELETE /employees/{id} (delete) ..."

   -- Create a record to delete
   LET json_body = '{"lastname":"DelLast","firstname":"DelFirst","birthdate":"1988-12-25","hiredate":"2024-06-01","reportsto":1}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("Setup failed: could not create employee, status=%1", status_code))
      RETURN
   END IF

   TRY
      CALL util.JSON.parse(response_body, new_emp)
   CATCH
      CALL test_rest_lib.test_fail("Setup failed: could not parse created employee")
      RETURN
   END TRY
   LET created_id = new_emp.employeeid

   -- Delete it
   CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   IF status_code != 200 THEN
      CALL test_rest_lib.test_fail(SFMT("Expected status 200, got %1", status_code))
      RETURN
   END IF

   -- Verify it's gone via REST
   CALL test_rest_lib.http_get(SFMT("%1/%2", m_base_url, created_id))
      RETURNING status_code, response_body

   IF status_code != 404 THEN
      CALL test_rest_lib.test_fail(SFMT("After delete, expected 404, got %1", status_code))
      RETURN
   END IF

   -- DB validation
   SELECT COUNT(*) INTO db_count FROM employees
      WHERE employeeid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Employee %1 still exists in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Deleted employee %1, verified 404 and gone from DB", created_id))
END FUNCTION

-- =============================================================================
-- Test: DELETE /employees/{id} — 404 for non-existent ID
-- =============================================================================
FUNCTION test_delete_not_found()
   DEFINE status_code INTEGER
   DEFINE response_body STRING

   DISPLAY "TEST: DELETE /employees/99999 (not found) ..."

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
   DEFINE emp t_employee
   DEFINE verified t_employee
   DEFINE status_code INTEGER
   DEFINE response_body STRING
   DEFINE json_body STRING
   DEFINE db_lastname STRING
   DEFINE db_count INTEGER
   DEFINE created_id INTEGER

   DISPLAY "TEST: Full CRUD lifecycle ..."

   -- 1. CREATE
   LET json_body = '{"lastname":"LifeLast","firstname":"LifeFirst","title":"QA Tester","birthdate":"1992-07-20","hiredate":"2024-03-15","reportsto":1}'
   CALL test_rest_lib.http_post(m_base_url, json_body) RETURNING status_code, response_body

   IF status_code < 200 OR status_code > 201 THEN
      CALL test_rest_lib.test_fail(SFMT("CREATE failed: status=%1", status_code))
      RETURN
   END IF

   CALL util.JSON.parse(response_body, emp)
   LET created_id = emp.employeeid

   -- DB validation: verify created
   SELECT lastname INTO db_lastname
      FROM employees WHERE employeeid = created_id
   IF SQLCA.SQLCODE = NOTFOUND THEN
      CALL test_rest_lib.test_fail(SFMT("Created employee %1 not found in DB", created_id))
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
   IF verified.lastname != "LifeLast" THEN
      CALL test_rest_lib.test_fail(SFMT("READ returned wrong lastname: '%1'", verified.lastname))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- 3. UPDATE — use hand-crafted JSON to avoid empty-string-for-null issues
   LET json_body = SFMT('{\"employeeid\":%1,\"lastname\":\"LifeLast\",\"firstname\":\"LifeFirst\",\"title\":\"Senior QA Tester\",\"birthdate\":\"1992-07-20\",\"hiredate\":\"2024-03-15\",\"reportsto\":1}', created_id)
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
   IF verified.title != "Senior QA Tester" THEN
      CALL test_rest_lib.test_fail(SFMT("After UPDATE, title='%1', expected 'Senior QA Tester'", verified.title))
      CALL test_rest_lib.http_delete(SFMT("%1/%2", m_base_url, created_id))
         RETURNING status_code, response_body
      RETURN
   END IF

   -- DB validation: verify update
   SELECT lastname INTO db_lastname
      FROM employees WHERE employeeid = created_id
   IF db_lastname != "LifeLast" THEN
      CALL test_rest_lib.test_fail(SFMT("DB lastname '%1' != expected 'LifeLast'", db_lastname))
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

   -- DB validation: verify record gone
   SELECT COUNT(*) INTO db_count FROM employees
      WHERE employeeid = created_id
   IF db_count != 0 THEN
      CALL test_rest_lib.test_fail(SFMT("Employee %1 still in DB after delete", created_id))
      RETURN
   END IF

   CALL test_rest_lib.test_pass(SFMT("Full lifecycle passed for employee %1 (all DB checks passed)", created_id))
END FUNCTION
