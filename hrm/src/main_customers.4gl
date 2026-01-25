DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN FORM f FROM "customers"
    DISPLAY FORM f

    MENU "Customers Maintenance"
        COMMAND "Query" "Search for Customers"
            CALL submenu_customers()
        COMMAND "Add" "Add a new Customer"
            CALL add_customers()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
