DATABASE northwind
MAIN

    CALL init_pgm()

    OPEN WINDOW mainWindow WITH FORM "employees"
      ATTRIBUTES(BORDER, STYLE="noactions")

    CALL populate_courtesy_combo()

    MENU "Employee Management"
        ON ACTION query
            CALL submenu_employee()
        ON ACTION add
            CALL add_employee()
        ON ACTION exit
            EXIT MENU
    END MENU

END MAIN
