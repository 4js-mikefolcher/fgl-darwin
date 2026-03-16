IMPORT FGL main_lib
IMPORT FGL ui_order_details
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "order_details"
      ATTRIBUTES(BORDER)

    MENU "Order Details Maintenance"
        COMMAND "Query" "Search for Order Details"
            CALL submenu_order_details()
        COMMAND "Add" "Add a new Order Detail"
            CALL root_add_order_details()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
