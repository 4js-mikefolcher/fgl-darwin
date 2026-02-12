###############################################################################
# Program: ifx_menu.4gl
# Purpose: Text-based menu system to launch Northwind application programs
###############################################################################

MAIN

    DEFER INTERRUPT

    OPTIONS
        MESSAGE LINE LAST

    OPEN WINDOW w_menu AT 2,2 WITH 22 ROWS, 76 COLUMNS
        ATTRIBUTE (BORDER, MESSAGE LINE LAST)

    CALL show_menu()

    CLOSE WINDOW w_menu

END MAIN

###############################################################################
FUNCTION show_menu()
###############################################################################
    DEFINE l_choice CHAR(1)
    DEFINE l_running SMALLINT

    LET l_running = TRUE

    WHILE l_running

        CLEAR SCREEN

        DISPLAY "========================================" AT 2,18
        DISPLAY "     NORTHWIND APPLICATION MENU         " AT 3,18
        DISPLAY "========================================" AT 4,18
        DISPLAY "                                        " AT 5,18
        DISPLAY "   1. Employee Management               " AT 6,18
        DISPLAY "   2. Customer Management               " AT 7,18
        DISPLAY "   3. Order Management                  " AT 8,18
        DISPLAY "   4. Product Management                " AT 9,18
        DISPLAY "   5. Reference Data                    " AT 10,18
        DISPLAY "                                        " AT 11,18
        DISPLAY "   0. Exit                              " AT 12,18
        DISPLAY "                                        " AT 13,18
        DISPLAY "========================================" AT 14,18

        PROMPT "   Enter selection: " FOR l_choice

        CASE l_choice
            WHEN "1"
                CALL employee_menu()

            WHEN "2"
                CALL customer_menu()

            WHEN "3"
                CALL order_menu()

            WHEN "4"
                CALL product_menu()

            WHEN "5"
                CALL reference_menu()

            WHEN "0"
                LET l_running = FALSE

            OTHERWISE
                MESSAGE "Invalid selection. Please try again."
                SLEEP 2
        END CASE

    END WHILE

END FUNCTION

###############################################################################
FUNCTION employee_menu()
###############################################################################
    DEFINE l_choice CHAR(1)
    DEFINE l_running SMALLINT

    LET l_running = TRUE

    WHILE l_running

        CLEAR SCREEN

        DISPLAY "========================================" AT 2,18
        DISPLAY "       EMPLOYEE MANAGEMENT              " AT 3,18
        DISPLAY "========================================" AT 4,18
        DISPLAY "                                        " AT 5,18
        DISPLAY "   1. Employee Maintenance              " AT 6,18
        DISPLAY "   2. Employee Territories              " AT 7,18
        DISPLAY "                                        " AT 8,18
        DISPLAY "   0. Return to Main Menu               " AT 9,18
        DISPLAY "                                        " AT 10,18
        DISPLAY "========================================" AT 11,18

        PROMPT "   Enter selection: " FOR l_choice

        CASE l_choice
            WHEN "1"
                RUN "fglrun main_employees"
            WHEN "2"
                RUN "fglrun main_empl_terr"
            WHEN "0"
                LET l_running = FALSE
            OTHERWISE
                MESSAGE "Invalid selection. Please try again."
                SLEEP 2
        END CASE

    END WHILE

END FUNCTION

###############################################################################
FUNCTION customer_menu()
###############################################################################
    DEFINE l_choice CHAR(1)
    DEFINE l_running SMALLINT

    LET l_running = TRUE

    WHILE l_running

        CLEAR SCREEN

        DISPLAY "========================================" AT 2,18
        DISPLAY "       CUSTOMER MANAGEMENT              " AT 3,18
        DISPLAY "========================================" AT 4,18
        DISPLAY "                                        " AT 5,18
        DISPLAY "   1. Customer Maintenance              " AT 6,18
        DISPLAY "                                        " AT 7,18
        DISPLAY "   0. Return to Main Menu               " AT 8,18
        DISPLAY "                                        " AT 9,18
        DISPLAY "========================================" AT 10,18

        PROMPT "   Enter selection: " FOR l_choice

        CASE l_choice
            WHEN "1"
                RUN "fglrun main_customers"
            WHEN "0"
                LET l_running = FALSE
            OTHERWISE
                MESSAGE "Invalid selection. Please try again."
                SLEEP 2
        END CASE

    END WHILE

END FUNCTION

###############################################################################
FUNCTION order_menu()
###############################################################################
    DEFINE l_choice CHAR(1)
    DEFINE l_running SMALLINT

    LET l_running = TRUE

    WHILE l_running

        CLEAR SCREEN

        DISPLAY "========================================" AT 2,18
        DISPLAY "         ORDER MANAGEMENT               " AT 3,18
        DISPLAY "========================================" AT 4,18
        DISPLAY "                                        " AT 5,18
        DISPLAY "   1. Order Maintenance                 " AT 6,18
        DISPLAY "   2. Order Details Maintenance          " AT 7,18
        DISPLAY "   3. Shipper Maintenance               " AT 8,18
        DISPLAY "                                        " AT 9,18
        DISPLAY "   0. Return to Main Menu               " AT 10,18
        DISPLAY "                                        " AT 11,18
        DISPLAY "========================================" AT 12,18

        PROMPT "   Enter selection: " FOR l_choice

        CASE l_choice
            WHEN "1"
                RUN "fglrun main_orders"
            WHEN "2"
                RUN "fglrun main_order_details"
            WHEN "3"
                RUN "fglrun main_shippers"
            WHEN "0"
                LET l_running = FALSE
            OTHERWISE
                MESSAGE "Invalid selection. Please try again."
                SLEEP 2
        END CASE

    END WHILE

END FUNCTION

###############################################################################
FUNCTION product_menu()
###############################################################################
    DEFINE l_choice CHAR(1)
    DEFINE l_running SMALLINT

    LET l_running = TRUE

    WHILE l_running

        CLEAR SCREEN

        DISPLAY "========================================" AT 2,18
        DISPLAY "        PRODUCT MANAGEMENT              " AT 3,18
        DISPLAY "========================================" AT 4,18
        DISPLAY "                                        " AT 5,18
        DISPLAY "   1. Product Maintenance               " AT 6,18
        DISPLAY "   2. Category Maintenance              " AT 7,18
        DISPLAY "   3. Supplier Maintenance              " AT 8,18
        DISPLAY "                                        " AT 9,18
        DISPLAY "   0. Return to Main Menu               " AT 10,18
        DISPLAY "                                        " AT 11,18
        DISPLAY "========================================" AT 12,18

        PROMPT "   Enter selection: " FOR l_choice

        CASE l_choice
            WHEN "1"
                RUN "fglrun main_products"
            WHEN "2"
                RUN "fglrun main_categories"
            WHEN "3"
                RUN "fglrun main_suppliers"
            WHEN "0"
                LET l_running = FALSE
            OTHERWISE
                MESSAGE "Invalid selection. Please try again."
                SLEEP 2
        END CASE

    END WHILE

END FUNCTION

###############################################################################
FUNCTION reference_menu()
###############################################################################
    DEFINE l_choice CHAR(1)
    DEFINE l_running SMALLINT

    LET l_running = TRUE

    WHILE l_running

        CLEAR SCREEN

        DISPLAY "========================================" AT 2,18
        DISPLAY "         REFERENCE DATA                 " AT 3,18
        DISPLAY "========================================" AT 4,18
        DISPLAY "                                        " AT 5,18
        DISPLAY "   1. Region Maintenance                " AT 6,18
        DISPLAY "   2. Territory Maintenance             " AT 7,18
        DISPLAY "   3. US States Maintenance             " AT 8,18
        DISPLAY "                                        " AT 9,18
        DISPLAY "   0. Return to Main Menu               " AT 10,18
        DISPLAY "                                        " AT 11,18
        DISPLAY "========================================" AT 12,18

        PROMPT "   Enter selection: " FOR l_choice

        CASE l_choice
            WHEN "1"
                RUN "fglrun main_region"
            WHEN "2"
                RUN "fglrun main_territories"
            WHEN "3"
                RUN "fglrun main_usstates"
            WHEN "0"
                LET l_running = FALSE
            OTHERWISE
                MESSAGE "Invalid selection. Please try again."
                SLEEP 2
        END CASE

    END WHILE

END FUNCTION