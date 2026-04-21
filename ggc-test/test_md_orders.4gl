#
# test_md_orders.4gl
# GGC test scenario for the master/detail orders module (mstr_dtl_order)
#
# Tests: search for orders, view a record, navigate, exit cleanly.
#
IMPORT FGL ggc

MAIN
    DEFINE stats ggc.Statistics

    CALL ggc.setApplicationName("mstr_dtl_order")
    CALL ggc.parseOptions()
    CALL ggc.registerScenario(FUNCTION play_search_and_view)
    CALL ggc.play()

    CALL ggc.getStatistics() RETURNING stats.*
    CALL ggc.showStatistics(stats.*)

    IF stats.scenarioFailed > 0 THEN
        EXIT PROGRAM 1
    END IF
    EXIT PROGRAM 0

END MAIN

#----------------------------------------------------------------------
# Scenario: Search for orders, view a record, navigate, exit
#----------------------------------------------------------------------
PRIVATE FUNCTION play_search_and_view()
    DEFINE tableSize INTEGER
    DEFINE detailSize INTEGER
    DEFINE orderId STRING
    DEFINE detailOrderId STRING
    DEFINE customerId STRING
    DEFINE employeeId STRING
    DEFINE nextOrderId STRING
    DEFINE prevOrderId STRING
    DEFINE lastOrderId STRING
    DEFINE firstOrderId STRING

    DISPLAY "--- Test: Search and View Orders ---"

    #------------------------------------------------------------------
    # Step 1: Verify the search/list form loaded
    #------------------------------------------------------------------
    DISPLAY "Step 1: Verify search form"
    CALL ggc.checkFormName("mstr_order_list")
    CALL ggc.checkNoError()

    #------------------------------------------------------------------
    # Step 2: Execute a search (empty criteria = all orders)
    #------------------------------------------------------------------
    DISPLAY "Step 2: Execute search"
    CALL ggc.action("accept")
    CALL ggc.wait(500)
    CALL ggc.checkNoError()

    #------------------------------------------------------------------
    # Step 3: Verify results exist
    #------------------------------------------------------------------
    DISPLAY "Step 3: Verify search results"
    LET tableSize = ggc.getTableSize("s_table")
    CALL ggc.assert(tableSize > 0,
        SFMT("Expected search results, got table size %1", tableSize))
    DISPLAY SFMT("  Found %1 orders", tableSize)

    #------------------------------------------------------------------
    # Step 4: Capture first row data and view it
    #------------------------------------------------------------------
    DISPLAY "Step 4: View first order"
    CALL ggc.setRowFocus("s_table", 1)
    CALL ggc.wait(200)

    LET orderId = ggc.getColumnValue("s_table", "orderid", 1)
    CALL ggc.assert(orderId IS NOT NULL AND orderId.getLength() > 0,
        "First row should have an order ID")
    DISPLAY SFMT("  Viewing order: %1", orderId)

    CALL ggc.action("view")
    CALL ggc.wait(500)

    #------------------------------------------------------------------
    # Step 5: Verify detail form opened with correct data
    #------------------------------------------------------------------
    DISPLAY "Step 5: Verify detail form"
    CALL ggc.checkFormName("md_order_details")
    CALL ggc.checkNoError()

    LET detailOrderId = ggc.getFieldValue("orders.orderid")
    CALL ggc.assert(detailOrderId IS NOT NULL AND detailOrderId != "0",
        SFMT("Expected order ID on detail form, got '%1'", detailOrderId))
    CALL ggc.assertEquals(orderId, detailOrderId,
        SFMT("Detail order ID '%1' should match list '%2'",
            detailOrderId, orderId))
    DISPLAY SFMT("  Detail form shows order: %1", detailOrderId)

    #------------------------------------------------------------------
    # Step 6: Verify header fields have data
    #------------------------------------------------------------------
    DISPLAY "Step 6: Verify header fields"
    LET customerId = ggc.getFieldValue("orders.customerid")
    CALL ggc.assert(customerId IS NOT NULL AND customerId.getLength() > 0,
        SFMT("Expected customer ID, got '%1'", customerId))
    DISPLAY SFMT("  Customer: %1", customerId)

    LET employeeId = ggc.getFieldValue("orders.employeeid")
    CALL ggc.assert(employeeId IS NOT NULL AND employeeId.getLength() > 0,
        SFMT("Expected employee ID, got '%1'", employeeId))
    DISPLAY SFMT("  Employee: %1", employeeId)

    #------------------------------------------------------------------
    # Step 7: Verify detail rows exist
    #------------------------------------------------------------------
    DISPLAY "Step 7: Verify detail rows"
    LET detailSize = ggc.getTableSize("s_details")
    CALL ggc.assert(detailSize > 0,
        SFMT("Expected detail rows, got %1", detailSize))
    DISPLAY SFMT("  Detail rows: %1", detailSize)

    #------------------------------------------------------------------
    # Step 8: Navigate — NEXT
    #------------------------------------------------------------------
    DISPLAY "Step 8: Navigate next"
    CALL ggc.action("next")
    CALL ggc.wait(300)
    CALL ggc.checkNoError()

    LET nextOrderId = ggc.getFieldValue("orders.orderid")
    CALL ggc.assert(nextOrderId IS NOT NULL AND nextOrderId != "0",
        SFMT("Expected order ID after NEXT, got '%1'", nextOrderId))
    CALL ggc.assert(nextOrderId != orderId,
        SFMT("NEXT should show a different order, still showing '%1'",
            nextOrderId))
    DISPLAY SFMT("  After NEXT: order %1", nextOrderId)

    #------------------------------------------------------------------
    # Step 9: Navigate — PREVIOUS (should return to first order)
    #------------------------------------------------------------------
    DISPLAY "Step 9: Navigate previous"
    CALL ggc.action("previous")
    CALL ggc.wait(300)
    CALL ggc.checkNoError()

    LET prevOrderId = ggc.getFieldValue("orders.orderid")
    CALL ggc.assertEquals(orderId, prevOrderId,
        SFMT("PREVIOUS should return to order '%1', got '%2'",
            orderId, prevOrderId))
    DISPLAY SFMT("  After PREVIOUS: order %1", prevOrderId)

    #------------------------------------------------------------------
    # Step 10: Navigate — LAST
    #------------------------------------------------------------------
    DISPLAY "Step 10: Navigate last"
    CALL ggc.action("last")
    CALL ggc.wait(300)
    CALL ggc.checkNoError()

    LET lastOrderId = ggc.getFieldValue("orders.orderid")
    CALL ggc.assert(lastOrderId IS NOT NULL AND lastOrderId != "0",
        SFMT("Expected order ID after LAST, got '%1'", lastOrderId))
    DISPLAY SFMT("  After LAST: order %1", lastOrderId)

    #------------------------------------------------------------------
    # Step 11: Navigate — FIRST
    #------------------------------------------------------------------
    DISPLAY "Step 11: Navigate first"
    CALL ggc.action("first")
    CALL ggc.wait(300)
    CALL ggc.checkNoError()

    LET firstOrderId = ggc.getFieldValue("orders.orderid")
    CALL ggc.assertEquals(orderId, firstOrderId,
        SFMT("FIRST should return to order '%1', got '%2'",
            orderId, firstOrderId))
    DISPLAY SFMT("  After FIRST: order %1", firstOrderId)

    #------------------------------------------------------------------
    # Step 12: Exit view, return to list
    #------------------------------------------------------------------
    DISPLAY "Step 12: Exit view"
    CALL ggc.action("exit")
    CALL ggc.wait(500)

    CALL ggc.checkFormName("mstr_order_list")
    CALL ggc.checkNoError()
    DISPLAY "  Back on search/list form"

    #------------------------------------------------------------------
    # Step 13: Exit application
    #------------------------------------------------------------------
    DISPLAY "Step 13: Exit application"
    CALL ggc.action("exit")
    CALL ggc.wait(300)

    CALL ggc.end()
    DISPLAY "--- Test PASSED ---"

END FUNCTION #play_search_and_view
