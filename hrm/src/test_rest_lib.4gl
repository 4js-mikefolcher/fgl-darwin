-- =============================================================================
-- Module: test_rest_lib.4gl
-- Purpose: Shared library for REST service test modules
--          Provides HTTP helper functions, test counters, and result display
-- =============================================================================
IMPORT com

DEFINE m_tests_passed INTEGER
DEFINE m_tests_failed INTEGER

-- =============================================================================
-- Test initialization and summary
-- =============================================================================

PUBLIC FUNCTION init_test_suite(suite_name STRING, base_url STRING)
   LET m_tests_passed = 0
   LET m_tests_failed = 0

   DISPLAY "============================================================"
   DISPLAY SFMT("  %1", suite_name)
   DISPLAY "  Base URL: ", base_url
   DISPLAY "============================================================"
   DISPLAY ""
END FUNCTION

PUBLIC FUNCTION display_test_summary() RETURNS INTEGER
   DISPLAY ""
   DISPLAY "============================================================"
   DISPLAY "  Test Results"
   DISPLAY "============================================================"
   DISPLAY SFMT("  Passed: %1", m_tests_passed)
   DISPLAY SFMT("  Failed: %1", m_tests_failed)
   DISPLAY SFMT("  Total:  %1", m_tests_passed + m_tests_failed)
   DISPLAY "============================================================"

   RETURN m_tests_failed
END FUNCTION

-- =============================================================================
-- Test result helpers
-- =============================================================================

PUBLIC FUNCTION test_pass(msg STRING)
   LET m_tests_passed = m_tests_passed + 1
   DISPLAY SFMT("  PASS: %1", msg)
   DISPLAY ""
END FUNCTION

PUBLIC FUNCTION test_fail(msg STRING)
   LET m_tests_failed = m_tests_failed + 1
   DISPLAY SFMT("  FAIL: %1", msg)
   DISPLAY ""
END FUNCTION

-- =============================================================================
-- HTTP helper functions
-- =============================================================================

PUBLIC FUNCTION http_get(url STRING) RETURNS (INTEGER, STRING)
   DEFINE req com.HttpRequest
   DEFINE resp com.HttpResponse

   TRY
      LET req = com.HttpRequest.Create(url)
      CALL req.setMethod("GET")
      CALL req.setHeader("Accept", "application/json")
      CALL req.setTimeout(10)
      CALL req.doRequest()

      LET resp = req.getResponse()
      RETURN resp.getStatusCode(), resp.getTextResponse()
   CATCH
      DISPLAY SFMT("  HTTP ERROR: GET %1 — %2", url, err_get(STATUS))
      RETURN -1, ""
   END TRY
END FUNCTION

PUBLIC FUNCTION http_post(url STRING, json_body STRING) RETURNS (INTEGER, STRING)
   DEFINE req com.HttpRequest
   DEFINE resp com.HttpResponse

   TRY
      LET req = com.HttpRequest.Create(url)
      CALL req.setMethod("POST")
      CALL req.setHeader("Content-Type", "application/json")
      CALL req.setHeader("Accept", "application/json")
      CALL req.setTimeout(10)
      CALL req.doTextRequest(json_body)

      LET resp = req.getResponse()
      RETURN resp.getStatusCode(), resp.getTextResponse()
   CATCH
      DISPLAY SFMT("  HTTP ERROR: POST %1 — %2", url, err_get(STATUS))
      RETURN -1, ""
   END TRY
END FUNCTION

PUBLIC FUNCTION http_put(url STRING, json_body STRING) RETURNS (INTEGER, STRING)
   DEFINE req com.HttpRequest
   DEFINE resp com.HttpResponse

   TRY
      LET req = com.HttpRequest.Create(url)
      CALL req.setMethod("PUT")
      CALL req.setHeader("Content-Type", "application/json")
      CALL req.setHeader("Accept", "application/json")
      CALL req.setTimeout(10)
      CALL req.doTextRequest(json_body)

      LET resp = req.getResponse()
      RETURN resp.getStatusCode(), resp.getTextResponse()
   CATCH
      DISPLAY SFMT("  HTTP ERROR: PUT %1 — %2", url, err_get(STATUS))
      RETURN -1, ""
   END TRY
END FUNCTION

PUBLIC FUNCTION http_delete(url STRING) RETURNS (INTEGER, STRING)
   DEFINE req com.HttpRequest
   DEFINE resp com.HttpResponse

   TRY
      LET req = com.HttpRequest.Create(url)
      CALL req.setMethod("DELETE")
      CALL req.setHeader("Accept", "application/json")
      CALL req.setTimeout(10)
      CALL req.doRequest()

      LET resp = req.getResponse()
      RETURN resp.getStatusCode(), resp.getTextResponse()
   CATCH
      DISPLAY SFMT("  HTTP ERROR: DELETE %1 — %2", url, err_get(STATUS))
      RETURN -1, ""
   END TRY
END FUNCTION

PUBLIC FUNCTION check_server(url STRING) RETURNS BOOLEAN
   DEFINE req com.HttpRequest
   DEFINE resp com.HttpResponse

   TRY
      LET req = com.HttpRequest.Create(url)
      CALL req.setMethod("GET")
      CALL req.setHeader("Accept", "application/json")
      CALL req.setTimeout(5)
      CALL req.doRequest()
      LET resp = req.getResponse()
      RETURN TRUE
   CATCH
      RETURN FALSE
   END TRY
END FUNCTION
