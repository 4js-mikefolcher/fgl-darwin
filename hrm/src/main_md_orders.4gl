IMPORT FGL main_lib
IMPORT FGL md_orders
DATABASE northwind
MAIN

    CALL init_pgm()
    CALL master_detail_orders()

END MAIN
