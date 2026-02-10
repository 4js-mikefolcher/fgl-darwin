DATABASE northwind
MAIN
    DEFINE f ui.Form

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "suppliers"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "Suppliers Maintenance"
        COMMAND "Query" "Search for Suppliers"
            CALL submenu_suppliers()
        COMMAND "Add" "Add a new Supplier"
            CALL add_suppliers()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
