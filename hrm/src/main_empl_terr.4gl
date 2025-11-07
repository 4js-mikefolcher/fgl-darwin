DATABASE northwind

MAIN

    CALL init_pgm()

    OPEN FORM f FROM "empl_terr"
    DISPLAY FORM f

    MENU "Employee Territories Management"
        COMMAND "Add" "Add a new employee territory"
            CALL add_empl_terr()
        COMMAND "Query" "Search for employee territories"
            CALL submenu_employee()
        COMMAND "Cancel" "Quit program"
            EXIT MENU
    END MENU
END MAIN
