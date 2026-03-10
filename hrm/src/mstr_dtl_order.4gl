IMPORT FGL main_lib
IMPORT FGL md_order_details
DATABASE northwind
MAIN

    CALL init_pgm()
    CALL mstr_detail_orders()

END MAIN