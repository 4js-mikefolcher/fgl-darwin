IMPORT ui
IMPORT FGL main_lib
IMPORT FGL ui_orders
IMPORT FGL model_shippers
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "orders"
      ATTRIBUTES(BORDER)

    CALL model_shippers.load_shipvia_combo(ui.ComboBox.forName("shipvia"))
    MENU "Order Maintenance"
        COMMAND "Query" "Search for Orders"
            CALL submenu_orders()
        COMMAND "Add" "Add a new Order"
            CALL root_add_orders()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
