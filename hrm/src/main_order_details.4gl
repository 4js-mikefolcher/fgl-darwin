DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN FORM f FROM "order_details"
    DISPLAY FORM f

    MENU "Order Details Maintenance"
        COMMAND "Query" "Search for Order Details"
            CALL submenu_order_details()
        COMMAND "Add" "Add a new Order Detail"
            CALL add_order_details()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
