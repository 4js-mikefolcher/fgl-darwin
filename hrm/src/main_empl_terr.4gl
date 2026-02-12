DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "empl_terr"

    CALL submenu_empl_terr()

    CLOSE WINDOW mainWindow

END MAIN
