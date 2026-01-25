DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN FORM f FROM "shippers"
    DISPLAY FORM f

    MENU "Shippers Maintenance"
        COMMAND "Query" "Search for Shippers"
            CALL submenu_shippers()
        COMMAND "Add" "Add a new Shipper"
            CALL add_shippers()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
