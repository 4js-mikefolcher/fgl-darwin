DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "region"
      ATTRIBUTES(BORDER, STYLE="noactions")

    MENU "Region Maintenance"
        ON ACTION query
            CALL submenu_region()
        ON ACTION add
            CALL add_region()
        ON ACTION exit
            EXIT MENU
    END MENU

END MAIN
