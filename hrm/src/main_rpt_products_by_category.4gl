IMPORT FGL main_lib
IMPORT FGL rpt_products_by_category
DATABASE northwind
MAIN

    CALL init_pgm()
    CALL run_products_by_category()

END MAIN
