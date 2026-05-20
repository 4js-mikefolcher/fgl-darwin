-- =============================================================================
-- Module:  test_db_helper.4gl
-- Purpose: Shared DB connect/disconnect helpers for fglunit suites that need
--          the northwind database. Use with FglUnit.setSetupSuite /
--          setTeardownSuite.
-- =============================================================================
SCHEMA northwind

PUBLIC FUNCTION connect_northwind()
   CONNECT TO "northwind"
END FUNCTION

PUBLIC FUNCTION disconnect_northwind()
   DISCONNECT CURRENT
END FUNCTION
