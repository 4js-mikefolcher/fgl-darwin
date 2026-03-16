IMPORT FGL main_lib
IMPORT FGL ui_cust_cust_demo
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "cust_cust_demo"

    MENU "Customer Type Assignments Maintenance"
        COMMAND "Query" "Search for Customer Type Assignments"
            CALL submenu_cust_cust_demo()
        COMMAND "Add" "Add a new Customer Type Assignment"
            CALL root_add_cust_cust_demo()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

    CLOSE WINDOW mainWindow

END MAIN
