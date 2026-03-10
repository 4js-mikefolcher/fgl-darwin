IMPORT FGL main_lib
IMPORT FGL ui_customers
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "customers"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "Customers Maintenance"
        COMMAND "Query" "Search for Customers"
            CALL submenu_customers()
        COMMAND "Add" "Add a new Customer"
            CALL root_add_customers()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
