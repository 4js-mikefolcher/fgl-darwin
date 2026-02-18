DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "customers"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "Customers Maintenance"
        COMMAND "Query" "Search for Customers"
            CALL submenu_customers()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
