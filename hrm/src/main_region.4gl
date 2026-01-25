DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN FORM f FROM "region"
    DISPLAY FORM f

    MENU "Region Maintenance"
        COMMAND "Query" "Search for regions"
            CALL submenu_region()
        COMMAND "Add" "Add a new region"
            CALL add_region()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
