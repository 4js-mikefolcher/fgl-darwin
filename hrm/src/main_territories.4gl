IMPORT FGL main_lib
IMPORT FGL ui_territories
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "territories"
      ATTRIBUTES(BORDER, STYLE="noactions")

    CALL populate_region_combo()

    MENU "Territories Maintenance"
        COMMAND "Query" "Search for territories"
            CALL submenu_territories()
        COMMAND "Add" "Add a new Territory"
            CALL root_add_territories()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
