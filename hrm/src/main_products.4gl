IMPORT FGL main_lib
IMPORT FGL ui_products
DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "products"
      ATTRIBUTES(BORDER, STYLE="noactions")

    CALL populate_supplier_combo()
    CALL populate_category_combo()

    MENU "Products Maintenance"
        COMMAND "Query" "Search for Products"
            CALL submenu_products()
        COMMAND "Add" "Add a new Product"
            CALL root_add_products()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
