DATABASE northwind
MAIN
    DEFINE f ui.Form

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "shippers"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "Shippers Maintenance"
        COMMAND "Query" "Search for Shippers"
            CALL submenu_shippers()
        COMMAND "Add" "Add a new Shipper"
            CALL add_shippers()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
