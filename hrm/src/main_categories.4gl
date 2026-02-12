DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "categories"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "Categories Maintenance"
        COMMAND "Query" "Search for Categories"
            CALL submenu_categories()
        COMMAND "Add" "Add a new Category"
            CALL add_categories()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
