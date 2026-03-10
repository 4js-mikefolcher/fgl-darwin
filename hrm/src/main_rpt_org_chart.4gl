IMPORT FGL main_lib
IMPORT FGL rpt_org_chart
DATABASE northwind
MAIN

    CALL init_pgm()
    CALL run_org_chart()

END MAIN
