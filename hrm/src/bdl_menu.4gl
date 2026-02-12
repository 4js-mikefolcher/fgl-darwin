###############################################################################
# Program: bdl_menu.4gl
# Purpose: GUI tree-based menu system to launch Northwind application programs
###############################################################################

MAIN

    DEFINE l_menu DYNAMIC ARRAY OF RECORD
        menu_name    STRING,
        description  STRING,
        program_name STRING,
        id           INTEGER,
        pid          INTEGER
    END RECORD

    DEFER INTERRUPT

    CALL init_pgm()
    CALL build_menu(l_menu)

    OPEN WINDOW w_menu WITH FORM "bdl_menu"

    DISPLAY ARRAY l_menu TO sr_menu.*
        ATTRIBUTES(UNBUFFERED, DOUBLECLICK = launch)

        ON ACTION launch
            CALL launch_program(l_menu[arr_curr()].program_name)

        ON ACTION exit
            EXIT DISPLAY

    END DISPLAY

    CLOSE WINDOW w_menu

END MAIN

###############################################################################
FUNCTION build_menu(p_menu)
###############################################################################
    DEFINE p_menu DYNAMIC ARRAY OF RECORD
        menu_name    STRING,
        description  STRING,
        program_name STRING,
        id           INTEGER,
        pid          INTEGER
    END RECORD

    -- Root: Employee Management (id=1)
    LET p_menu[p_menu.getLength() + 1].id           = 1
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Employee Management"
    LET p_menu[p_menu.getLength()].description      = "Manage employee records and assignments"
    LET p_menu[p_menu.getLength()].program_name     = NULL

    LET p_menu[p_menu.getLength() + 1].id           = 10
    LET p_menu[p_menu.getLength()].pid              = 1
    LET p_menu[p_menu.getLength()].menu_name        = "Employee Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage employee records"
    LET p_menu[p_menu.getLength()].program_name     = "main_employees"

    LET p_menu[p_menu.getLength() + 1].id           = 11
    LET p_menu[p_menu.getLength()].pid              = 1
    LET p_menu[p_menu.getLength()].menu_name        = "Employee Territories"
    LET p_menu[p_menu.getLength()].description      = "Assign employees to sales territories"
    LET p_menu[p_menu.getLength()].program_name     = "main_empl_terr"

    -- Root: Customer Management (id=2)
    LET p_menu[p_menu.getLength() + 1].id           = 2
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Customer Management"
    LET p_menu[p_menu.getLength()].description      = "Manage customer accounts"
    LET p_menu[p_menu.getLength()].program_name     = NULL

    LET p_menu[p_menu.getLength() + 1].id           = 20
    LET p_menu[p_menu.getLength()].pid              = 2
    LET p_menu[p_menu.getLength()].menu_name        = "Customer Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage customer records"
    LET p_menu[p_menu.getLength()].program_name     = "main_customers"

    -- Root: Order Management (id=3)
    LET p_menu[p_menu.getLength() + 1].id           = 3
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Order Management"
    LET p_menu[p_menu.getLength()].description      = "Manage orders, line items, and shipping"
    LET p_menu[p_menu.getLength()].program_name     = NULL

    LET p_menu[p_menu.getLength() + 1].id           = 30
    LET p_menu[p_menu.getLength()].pid              = 3
    LET p_menu[p_menu.getLength()].menu_name        = "Order Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage customer orders"
    LET p_menu[p_menu.getLength()].program_name     = "main_orders"

    LET p_menu[p_menu.getLength() + 1].id           = 31
    LET p_menu[p_menu.getLength()].pid              = 3
    LET p_menu[p_menu.getLength()].menu_name        = "Order Details Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage order line items and quantities"
    LET p_menu[p_menu.getLength()].program_name     = "main_order_details"

    LET p_menu[p_menu.getLength() + 1].id           = 32
    LET p_menu[p_menu.getLength()].pid              = 3
    LET p_menu[p_menu.getLength()].menu_name        = "Shipper Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage shipping companies and methods"
    LET p_menu[p_menu.getLength()].program_name     = "main_shippers"

    -- Root: Product Management (id=4)
    LET p_menu[p_menu.getLength() + 1].id           = 4
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Product Management"
    LET p_menu[p_menu.getLength()].description      = "Manage products, categories, and suppliers"
    LET p_menu[p_menu.getLength()].program_name     = NULL

    LET p_menu[p_menu.getLength() + 1].id           = 40
    LET p_menu[p_menu.getLength()].pid              = 4
    LET p_menu[p_menu.getLength()].menu_name        = "Product Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage product catalog"
    LET p_menu[p_menu.getLength()].program_name     = "main_products"

    LET p_menu[p_menu.getLength() + 1].id           = 41
    LET p_menu[p_menu.getLength()].pid              = 4
    LET p_menu[p_menu.getLength()].menu_name        = "Category Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage product category classifications"
    LET p_menu[p_menu.getLength()].program_name     = "main_categories"

    LET p_menu[p_menu.getLength() + 1].id           = 42
    LET p_menu[p_menu.getLength()].pid              = 4
    LET p_menu[p_menu.getLength()].menu_name        = "Supplier Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage supplier contacts"
    LET p_menu[p_menu.getLength()].program_name     = "main_suppliers"

    -- Root: Reference Data (id=5)
    LET p_menu[p_menu.getLength() + 1].id           = 5
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Reference Data"
    LET p_menu[p_menu.getLength()].description      = "Manage lookup tables and reference data"
    LET p_menu[p_menu.getLength()].program_name     = NULL

    LET p_menu[p_menu.getLength() + 1].id           = 50
    LET p_menu[p_menu.getLength()].pid              = 5
    LET p_menu[p_menu.getLength()].menu_name        = "Region Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage geographic sales regions"
    LET p_menu[p_menu.getLength()].program_name     = "main_region"

    LET p_menu[p_menu.getLength() + 1].id           = 51
    LET p_menu[p_menu.getLength()].pid              = 5
    LET p_menu[p_menu.getLength()].menu_name        = "Territory Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage sales territory definitions"
    LET p_menu[p_menu.getLength()].program_name     = "main_territories"

    LET p_menu[p_menu.getLength() + 1].id           = 52
    LET p_menu[p_menu.getLength()].pid              = 5
    LET p_menu[p_menu.getLength()].menu_name        = "US States Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage US state codes and names"
    LET p_menu[p_menu.getLength()].program_name     = "main_usstates"

END FUNCTION

###############################################################################
FUNCTION launch_program(p_program)
###############################################################################
    DEFINE p_program STRING

    IF p_program IS NULL THEN
        MESSAGE "Select a program to launch."
        RETURN
    END IF

    RUN "fglrun " || p_program WITHOUT WAITING

END FUNCTION
