IMPORT FGL main_lib
IMPORT FGL ui_empl_terr
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "empl_terr"

     MENU "Customers Maintenance"
        COMMAND "Query" "Search for Employee Territories"
            CALL submenu_empl_terr()
        COMMAND "Add" "Add a new Employee Territory"
            CALL root_add_empl_terr()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

    CLOSE WINDOW mainWindow

END MAIN
