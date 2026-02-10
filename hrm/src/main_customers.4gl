DATABASE northwind
MAIN
    DEFINE f ui.Form

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "customers"
      ATTRIBUTES(BORDER, STYLE="noactions")

    LET f = ui.Window.getCurrent().getForm()
    CALL f.loadActionDefaults("generic.4ad")

    MENU "Customers Maintenance"
        COMMAND "Query" "Search for Customers"
            CALL submenu_customers()
        COMMAND "Add" "Add a new Customer"
            CALL add_customers()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
