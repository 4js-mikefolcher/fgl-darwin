IMPORT FGL main_lib
IMPORT FGL ui_orders
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "orders"
      ATTRIBUTES(BORDER)

    CALL populate_shipvia_combo()
    MENU "Order Maintenance"
        COMMAND "Query" "Search for Orders"
            CALL submenu_orders()
        COMMAND "Add" "Add a new Order"
            CALL root_add_orders()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
