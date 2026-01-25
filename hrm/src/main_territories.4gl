DATABASE northwind

MAIN          
          
    CALL init_pgm()
              
    OPEN FORM f FROM "territories" 
    DISPLAY FORM f
                 
    MENU "Territories Maintenance" 
        COMMAND "Query" "Search for territories"
            CALL submenu_territories()
        COMMAND "Add" "Add a new territory"
            CALL add_territories()
        COMMAND "Exit" "Cancel the program"
            EXIT MENU
    END MENU

END MAIN
