DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN FORM f FROM "categories"
    DISPLAY FORM f

    MENU "Categories Maintenance"
        COMMAND "Query" "Search for Categories"
            CALL submenu_categories()
        COMMAND "Add" "Add a new Category"
            CALL add_categories()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
