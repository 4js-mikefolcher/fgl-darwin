DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "empl_terr"
      ATTRIBUTES(BORDER)

    MENU "Employee Territories Management"
        COMMAND "Query" "Search for employee territories"
            CALL submenu_empl_terr()
        COMMAND "Add" "Add a new employee territory"
            CALL add_empl_terr()
        COMMAND "Exit" "Quit program"
            EXIT MENU
    END MENU

END MAIN
