IMPORT FGL main_lib
IMPORT FGL ui_shippers
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "shippers"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "Shippers Maintenance"
        COMMAND "Query" "Search for Shippers"
            CALL submenu_shippers()
        COMMAND "Add" "Add a new Shipper"
            CALL root_add_shippers()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
