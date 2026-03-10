IMPORT FGL main_lib
IMPORT FGL ui_usstates
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "usstates"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "US States Maintenance"
        COMMAND "Query" "Search for States"
            CALL submenu_usstates()
        COMMAND "Add" "Add a new State"
            CALL root_add_usstates()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
