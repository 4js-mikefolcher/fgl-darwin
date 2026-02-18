DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "suppliers"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "Suppliers Maintenance"
        COMMAND "Query" "Search for Suppliers"
            CALL submenu_suppliers()
        COMMAND "Add" "Add a new Supplier"
            CALL suppliers_do_add()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
