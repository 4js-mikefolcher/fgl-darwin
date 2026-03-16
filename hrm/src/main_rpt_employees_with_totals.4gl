IMPORT FGL main_lib
IMPORT FGL rpt_employees_with_totals
DATABASE northwind
MAIN

    CALL init_pgm()
    CALL run_employees_with_totals()

END MAIN
