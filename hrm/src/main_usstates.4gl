DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN FORM f FROM "usstates"
    DISPLAY FORM f

    MENU "US States Maintenance"
        COMMAND "Query" "Search for States"
            CALL submenu_usstates()
        COMMAND "Add" "Add a new State"
            CALL add_usstates()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
