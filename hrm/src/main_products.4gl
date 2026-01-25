DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN FORM f FROM "products"
    DISPLAY FORM f

    MENU "Products Maintenance"
        COMMAND "Query" "Search for Products"
            CALL submenu_products()
        COMMAND "Add" "Add a new Product"
            CALL add_products()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
