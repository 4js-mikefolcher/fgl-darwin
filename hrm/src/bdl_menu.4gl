###############################################################################
# Program: bdl_menu.4gl
# Purpose: GUI tree-based menu system to launch Northwind application programs
###############################################################################
IMPORT FGL main_lib

MAIN

    DEFINE l_menu DYNAMIC ARRAY OF RECORD
        menu_name    STRING,
        description  STRING,
        program_name STRING,
        id           INTEGER,
        pid          INTEGER,
        icon_name    STRING
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
        pid          INTEGER,
        icon_name    STRING
    END RECORD

    -- Root: Employee Management (id=1)
    LET p_menu[p_menu.getLength() + 1].id           = 1
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Employee Management"
    LET p_menu[p_menu.getLength()].description      = "Manage employee records and assignments"
    LET p_menu[p_menu.getLength()].program_name     = NULL
    LET p_menu[p_menu.getLength()].icon_name        = "fa-users"

    LET p_menu[p_menu.getLength() + 1].id           = 10
    LET p_menu[p_menu.getLength()].pid              = 1
    LET p_menu[p_menu.getLength()].menu_name        = "Employee Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage employee records"
    LET p_menu[p_menu.getLength()].program_name     = "main_employees"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-id-card"

    LET p_menu[p_menu.getLength() + 1].id           = 11
    LET p_menu[p_menu.getLength()].pid              = 1
    LET p_menu[p_menu.getLength()].menu_name        = "Employee Territories"
    LET p_menu[p_menu.getLength()].description      = "Assign employees to sales territories"
    LET p_menu[p_menu.getLength()].program_name     = "main_empl_terr"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-map-marker"

    -- Root: Customer Management (id=2)
    LET p_menu[p_menu.getLength() + 1].id           = 2
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Customer Management"
    LET p_menu[p_menu.getLength()].description      = "Manage customer accounts"
    LET p_menu[p_menu.getLength()].program_name     = NULL
    LET p_menu[p_menu.getLength()].icon_name        = "fa-user"

    LET p_menu[p_menu.getLength() + 1].id           = 20
    LET p_menu[p_menu.getLength()].pid              = 2
    LET p_menu[p_menu.getLength()].menu_name        = "Customer Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage customer records"
    LET p_menu[p_menu.getLength()].program_name     = "main_customers"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-address-card"

    LET p_menu[p_menu.getLength() + 1].id           = 21
    LET p_menu[p_menu.getLength()].pid              = 2
    LET p_menu[p_menu.getLength()].menu_name        = "Customer Demographics"
    LET p_menu[p_menu.getLength()].description      = "Manage customer demographic types"
    LET p_menu[p_menu.getLength()].program_name     = "main_cust_demo"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-id-badge"

    LET p_menu[p_menu.getLength() + 1].id           = 22
    LET p_menu[p_menu.getLength()].pid              = 2
    LET p_menu[p_menu.getLength()].menu_name        = "Customer Type Assignments"
    LET p_menu[p_menu.getLength()].description      = "Assign customers to demographic types"
    LET p_menu[p_menu.getLength()].program_name     = "main_cust_cust_demo"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-tags"

    -- Root: Order Management (id=3)
    LET p_menu[p_menu.getLength() + 1].id           = 3
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Order Management"
    LET p_menu[p_menu.getLength()].description      = "Manage orders, line items, and shipping"
    LET p_menu[p_menu.getLength()].program_name     = NULL
    LET p_menu[p_menu.getLength()].icon_name        = "fa-shopping-cart"

    LET p_menu[p_menu.getLength() + 1].id           = 30
    LET p_menu[p_menu.getLength()].pid              = 3
    LET p_menu[p_menu.getLength()].menu_name        = "Order Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage customer orders"
    LET p_menu[p_menu.getLength()].program_name     = "main_orders"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-shopping-cart"

    LET p_menu[p_menu.getLength() + 1].id           = 31
    LET p_menu[p_menu.getLength()].pid              = 3
    LET p_menu[p_menu.getLength()].menu_name        = "Order Details Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage order line items and quantities"
    LET p_menu[p_menu.getLength()].program_name     = "main_order_details"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-list-alt"

    LET p_menu[p_menu.getLength() + 1].id           = 32
    LET p_menu[p_menu.getLength()].pid              = 3
    LET p_menu[p_menu.getLength()].menu_name        = "Shipper Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage shipping companies and methods"
    LET p_menu[p_menu.getLength()].program_name     = "main_shippers"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-ship"

    LET p_menu[p_menu.getLength() + 1].id           = 33
    LET p_menu[p_menu.getLength()].pid              = 3
    LET p_menu[p_menu.getLength()].menu_name        = "Order Entry (Master-Detail)"
    LET p_menu[p_menu.getLength()].description      = "Master-detail order entry with line items"
    LET p_menu[p_menu.getLength()].program_name     = "mstr_dtl_order"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-clipboard"

    -- Root: Product Management (id=4)
    LET p_menu[p_menu.getLength() + 1].id           = 4
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Product Management"
    LET p_menu[p_menu.getLength()].description      = "Manage products, categories, and suppliers"
    LET p_menu[p_menu.getLength()].program_name     = NULL
    LET p_menu[p_menu.getLength()].icon_name        = "fa-list"

    LET p_menu[p_menu.getLength() + 1].id           = 40
    LET p_menu[p_menu.getLength()].pid              = 4
    LET p_menu[p_menu.getLength()].menu_name        = "Product Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage product catalog"
    LET p_menu[p_menu.getLength()].program_name     = "main_products"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-list"

    LET p_menu[p_menu.getLength() + 1].id           = 41
    LET p_menu[p_menu.getLength()].pid              = 4
    LET p_menu[p_menu.getLength()].menu_name        = "Category Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage product category classifications"
    LET p_menu[p_menu.getLength()].program_name     = "main_categories"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-tag"

    LET p_menu[p_menu.getLength() + 1].id           = 42
    LET p_menu[p_menu.getLength()].pid              = 4
    LET p_menu[p_menu.getLength()].menu_name        = "Supplier Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Query, add, and manage supplier contacts"
    LET p_menu[p_menu.getLength()].program_name     = "main_suppliers"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-truck"

    -- Root: Reference Data (id=5)
    LET p_menu[p_menu.getLength() + 1].id           = 5
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Reference Data"
    LET p_menu[p_menu.getLength()].description      = "Manage lookup tables and reference data"
    LET p_menu[p_menu.getLength()].program_name     = NULL
    LET p_menu[p_menu.getLength()].icon_name        = "fa-book"

    LET p_menu[p_menu.getLength() + 1].id           = 50
    LET p_menu[p_menu.getLength()].pid              = 5
    LET p_menu[p_menu.getLength()].menu_name        = "Region Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage geographic sales regions"
    LET p_menu[p_menu.getLength()].program_name     = "main_region"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-globe"

    LET p_menu[p_menu.getLength() + 1].id           = 51
    LET p_menu[p_menu.getLength()].pid              = 5
    LET p_menu[p_menu.getLength()].menu_name        = "Territory Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage sales territory definitions"
    LET p_menu[p_menu.getLength()].program_name     = "main_territories"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-map-marker"

    LET p_menu[p_menu.getLength() + 1].id           = 52
    LET p_menu[p_menu.getLength()].pid              = 5
    LET p_menu[p_menu.getLength()].menu_name        = "US States Maintenance"
    LET p_menu[p_menu.getLength()].description      = "Manage US state codes and names"
    LET p_menu[p_menu.getLength()].program_name     = "main_usstates"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-flag"

    -- Root: Reports (id=6)
    LET p_menu[p_menu.getLength() + 1].id           = 6
    LET p_menu[p_menu.getLength()].pid              = NULL
    LET p_menu[p_menu.getLength()].menu_name        = "Reports"
    LET p_menu[p_menu.getLength()].description      = "Order reports and analytics"
    LET p_menu[p_menu.getLength()].program_name     = NULL
    LET p_menu[p_menu.getLength()].icon_name        = "fa-bar-chart"

    LET p_menu[p_menu.getLength() + 1].id           = 60
    LET p_menu[p_menu.getLength()].pid              = 6
    LET p_menu[p_menu.getLength()].menu_name        = "Orders by Customer"
    LET p_menu[p_menu.getLength()].description      = "Report of orders grouped by customer"
    LET p_menu[p_menu.getLength()].program_name     = "main_rpt_orders_by_customer"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-bar-chart"

    LET p_menu[p_menu.getLength() + 1].id           = 61
    LET p_menu[p_menu.getLength()].pid              = 6
    LET p_menu[p_menu.getLength()].menu_name        = "Orders by Employee"
    LET p_menu[p_menu.getLength()].description      = "Report of orders grouped by employee"
    LET p_menu[p_menu.getLength()].program_name     = "main_rpt_orders_by_employee"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-bar-chart"

    LET p_menu[p_menu.getLength() + 1].id           = 62
    LET p_menu[p_menu.getLength()].pid              = 6
    LET p_menu[p_menu.getLength()].menu_name        = "Orders by Product"
    LET p_menu[p_menu.getLength()].description      = "Report of orders grouped by product"
    LET p_menu[p_menu.getLength()].program_name     = "main_rpt_orders_by_product"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-bar-chart"

    LET p_menu[p_menu.getLength() + 1].id           = 63
    LET p_menu[p_menu.getLength()].pid              = 6
    LET p_menu[p_menu.getLength()].menu_name        = "Orders by Date Range"
    LET p_menu[p_menu.getLength()].description      = "Report of orders filtered by date range"
    LET p_menu[p_menu.getLength()].program_name     = "main_rpt_orders_by_daterange"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-bar-chart"

    LET p_menu[p_menu.getLength() + 1].id           = 64
    LET p_menu[p_menu.getLength()].pid              = 6
    LET p_menu[p_menu.getLength()].menu_name        = "Generic Orders (XML)"
    LET p_menu[p_menu.getLength()].description      = "Generic order report with XML output"
    LET p_menu[p_menu.getLength()].program_name     = "main_rpt_orders_generic"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-file-text"

    LET p_menu[p_menu.getLength() + 1].id           = 65
    LET p_menu[p_menu.getLength()].pid              = 6
    LET p_menu[p_menu.getLength()].menu_name        = "Corporate Org Chart"
    LET p_menu[p_menu.getLength()].description      = "Employee organization chart showing reporting structure"
    LET p_menu[p_menu.getLength()].program_name     = "main_rpt_org_chart"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-sitemap"

    LET p_menu[p_menu.getLength() + 1].id           = 66
    LET p_menu[p_menu.getLength()].pid              = 6
    LET p_menu[p_menu.getLength()].menu_name        = "Products by Category"
    LET p_menu[p_menu.getLength()].description      = "Report of products grouped by category with total sales"
    LET p_menu[p_menu.getLength()].program_name     = "main_rpt_products_by_category"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-bar-chart"

    LET p_menu[p_menu.getLength() + 1].id           = 67
    LET p_menu[p_menu.getLength()].pid              = 6
    LET p_menu[p_menu.getLength()].menu_name        = "Employees with Order Totals"
    LET p_menu[p_menu.getLength()].description      = "Report of employees with total order amounts"
    LET p_menu[p_menu.getLength()].program_name     = "main_rpt_employees_with_totals"
    LET p_menu[p_menu.getLength()].icon_name        = "fa-bar-chart"

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
