DATABASE northwind

MAIN

    CALL init_pgm()

    OPEN FORM f FROM "employees"
    DISPLAY FORM f

    MENU "Employee Management"
        COMMAND "Add" "Add a new employee"
            CALL add_employee()
        COMMAND "Query" "Search for employees"
            CALL submenu_employee()
        COMMAND "Exit" "Quit program"
            EXIT MENU
    END MENU
END MAIN
