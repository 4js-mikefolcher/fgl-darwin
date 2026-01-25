DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN FORM f FROM "suppliers"
    DISPLAY FORM f

    MENU "Suppliers Maintenance"
        COMMAND "Query" "Search for Suppliers"
            CALL submenu_suppliers()
        COMMAND "Add" "Add a new Supplier"
            CALL add_suppliers()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
