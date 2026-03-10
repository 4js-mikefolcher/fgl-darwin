IMPORT FGL main_lib
IMPORT FGL ui_cust_demo
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "cust_demo"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "Customer Demographics Maintenance"
        COMMAND "Query" "Search for Customer Demographics"
            CALL submenu_cust_demo()
        COMMAND "Add" "Add a new Customer Demographic"
            CALL root_add_cust_demo()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

    CLOSE WINDOW mainWindow

END MAIN
