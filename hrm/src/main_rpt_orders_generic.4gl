IMPORT FGL main_lib
IMPORT FGL rpt_orders_generic
DATABASE northwind
MAIN

    CALL init_pgm()
    CALL run_orders_generic()

END MAIN
