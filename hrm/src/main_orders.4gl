DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN FORM f FROM "orders"
    DISPLAY FORM f

    MENU "Order Maintenance"
        COMMAND "Query" "Search for Orders"
            CALL submenu_orders()
        COMMAND "Add" "Add a new Order"
            CALL add_orders()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN