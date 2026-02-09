DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "employees"
      ATTRIBUTES(BORDER)

    MENU "Employee Management"
        COMMAND "Query" "Search for employees"
            CALL submenu_employee()
        COMMAND "Add" "Add a new employee"
            CALL add_employee()
        COMMAND "Exit" "Quit program"
            EXIT MENU
    END MENU

END MAIN
