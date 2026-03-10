IMPORT FGL main_lib
IMPORT FGL rpt_orders_by_customer
DATABASE northwind
MAIN

    CALL init_pgm()
    CALL run_orders_by_customer()

END MAIN
