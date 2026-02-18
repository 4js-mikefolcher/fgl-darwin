# Makefile for Genero BDL Application
# Compiles .per forms and .4gl modules

# Directories
BINDIR = ../bin

# Compilers
FORMCOMP = fglform
SRCCOMP = fgl2p

# Source files
FORMS = employees.per employees_list.per empl_terr.per empl_terr_list.per region.per region_list.per territories.per territories_list.per \
        orders.per orders_list.per order_details.per order_details_list.per \
        categories.per categories_list.per customers.per customers_list.per \
        products.per products_list.per shippers.per shippers_list.per \
        suppliers.per suppliers_list.per usstates.per usstates_list.per \
        rpt_orders_by_customer.per rpt_orders_by_employee.per rpt_orders_by_product.per \
        rpt_orders_by_daterange.per rpt_orders_generic.per report_viewer.per bdl_menu.per

# Compiled form targets
FORM_TARGETS = $(BINDIR)/employees.42f \
               $(BINDIR)/employees_list.42f \
               $(BINDIR)/empl_terr.42f \
               $(BINDIR)/empl_terr_list.42f \
               $(BINDIR)/region.42f \
               $(BINDIR)/region_list.42f \
               $(BINDIR)/territories.42f \
               $(BINDIR)/territories_list.42f \
               $(BINDIR)/orders.42f \
               $(BINDIR)/orders_list.42f \
               $(BINDIR)/order_details.42f \
               $(BINDIR)/order_details_list.42f \
               $(BINDIR)/categories.42f \
               $(BINDIR)/categories_list.42f \
               $(BINDIR)/customers.42f \
               $(BINDIR)/customers_list.42f \
               $(BINDIR)/products.42f \
               $(BINDIR)/products_list.42f \
               $(BINDIR)/shippers.42f \
               $(BINDIR)/shippers_list.42f \
               $(BINDIR)/suppliers.42f \
               $(BINDIR)/suppliers_list.42f \
               $(BINDIR)/usstates.42f \
               $(BINDIR)/usstates_list.42f \
               $(BINDIR)/rpt_orders_by_customer.42f \
               $(BINDIR)/rpt_orders_by_employee.42f \
               $(BINDIR)/rpt_orders_by_product.42f \
               $(BINDIR)/rpt_orders_by_daterange.42f \
               $(BINDIR)/rpt_orders_generic.42f \
               $(BINDIR)/report_viewer.42f \
               $(BINDIR)/bdl_menu.42f

# Program targets
PROG_TARGETS = $(BINDIR)/bdl_menu.42r \
               $(BINDIR)/ifx_menu.42r \
               $(BINDIR)/main_employees.42r \
               $(BINDIR)/main_empl_terr.42r \
               $(BINDIR)/main_region.42r \
               $(BINDIR)/main_territories.42r \
               $(BINDIR)/main_orders.42r \
               $(BINDIR)/main_order_details.42r \
               $(BINDIR)/main_categories.42r \
               $(BINDIR)/main_customers.42r \
               $(BINDIR)/main_products.42r \
               $(BINDIR)/main_shippers.42r \
               $(BINDIR)/main_suppliers.42r \
               $(BINDIR)/main_usstates.42r \
               $(BINDIR)/main_rpt_orders_by_customer.42r \
               $(BINDIR)/main_rpt_orders_by_employee.42r \
               $(BINDIR)/main_rpt_orders_by_product.42r \
               $(BINDIR)/main_rpt_orders_by_daterange.42r \
               $(BINDIR)/main_rpt_orders_generic.42r

# Default target - build everything
all: $(BINDIR) $(FORM_TARGETS) $(PROG_TARGETS)

# Create bin directory if it doesn't exist
$(BINDIR):
	mkdir -p $(BINDIR)

# Form compilation rules
$(BINDIR)/employees.42f: employees.per
	$(FORMCOMP) $<
	mv employees.42f $(BINDIR)/

$(BINDIR)/employees_list.42f: employees_list.per
	$(FORMCOMP) $<
	mv employees_list.42f $(BINDIR)/

$(BINDIR)/empl_terr.42f: empl_terr.per
	$(FORMCOMP) $<
	mv empl_terr.42f $(BINDIR)/

$(BINDIR)/empl_terr_list.42f: empl_terr_list.per
	$(FORMCOMP) $<
	mv empl_terr_list.42f $(BINDIR)/

$(BINDIR)/region.42f: region.per
	$(FORMCOMP) $<
	mv region.42f $(BINDIR)/

$(BINDIR)/region_list.42f: region_list.per
	$(FORMCOMP) $<
	mv region_list.42f $(BINDIR)/

$(BINDIR)/territories.42f: territories.per
	$(FORMCOMP) $<
	mv territories.42f $(BINDIR)/

$(BINDIR)/territories_list.42f: territories_list.per
	$(FORMCOMP) $<
	mv territories_list.42f $(BINDIR)/

$(BINDIR)/orders.42f: orders.per
	$(FORMCOMP) $<
	mv orders.42f $(BINDIR)/

$(BINDIR)/orders_list.42f: orders_list.per
	$(FORMCOMP) $<
	mv orders_list.42f $(BINDIR)/

$(BINDIR)/order_details.42f: order_details.per
	$(FORMCOMP) $<
	mv order_details.42f $(BINDIR)/

$(BINDIR)/order_details_list.42f: order_details_list.per
	$(FORMCOMP) $<
	mv order_details_list.42f $(BINDIR)/

$(BINDIR)/categories.42f: categories.per
	$(FORMCOMP) $<
	mv categories.42f $(BINDIR)/

$(BINDIR)/categories_list.42f: categories_list.per
	$(FORMCOMP) $<
	mv categories_list.42f $(BINDIR)/

$(BINDIR)/customers.42f: customers.per
	$(FORMCOMP) $<
	mv customers.42f $(BINDIR)/

$(BINDIR)/customers_list.42f: customers_list.per
	$(FORMCOMP) $<
	mv customers_list.42f $(BINDIR)/

$(BINDIR)/products.42f: products.per
	$(FORMCOMP) $<
	mv products.42f $(BINDIR)/

$(BINDIR)/products_list.42f: products_list.per
	$(FORMCOMP) $<
	mv products_list.42f $(BINDIR)/

$(BINDIR)/shippers.42f: shippers.per
	$(FORMCOMP) $<
	mv shippers.42f $(BINDIR)/

$(BINDIR)/shippers_list.42f: shippers_list.per
	$(FORMCOMP) $<
	mv shippers_list.42f $(BINDIR)/

$(BINDIR)/suppliers.42f: suppliers.per
	$(FORMCOMP) $<
	mv suppliers.42f $(BINDIR)/

$(BINDIR)/suppliers_list.42f: suppliers_list.per
	$(FORMCOMP) $<
	mv suppliers_list.42f $(BINDIR)/

$(BINDIR)/usstates.42f: usstates.per
	$(FORMCOMP) $<
	mv usstates.42f $(BINDIR)/

$(BINDIR)/usstates_list.42f: usstates_list.per
	$(FORMCOMP) $<
	mv usstates_list.42f $(BINDIR)/

$(BINDIR)/rpt_orders_by_customer.42f: rpt_orders_by_customer.per
	$(FORMCOMP) $<
	mv rpt_orders_by_customer.42f $(BINDIR)/

$(BINDIR)/rpt_orders_by_employee.42f: rpt_orders_by_employee.per
	$(FORMCOMP) $<
	mv rpt_orders_by_employee.42f $(BINDIR)/

$(BINDIR)/rpt_orders_by_product.42f: rpt_orders_by_product.per
	$(FORMCOMP) $<
	mv rpt_orders_by_product.42f $(BINDIR)/

$(BINDIR)/rpt_orders_by_daterange.42f: rpt_orders_by_daterange.per
	$(FORMCOMP) $<
	mv rpt_orders_by_daterange.42f $(BINDIR)/

$(BINDIR)/rpt_orders_generic.42f: rpt_orders_generic.per
	$(FORMCOMP) $<
	mv rpt_orders_generic.42f $(BINDIR)/

$(BINDIR)/report_viewer.42f: report_viewer.per
	$(FORMCOMP) $<
	mv report_viewer.42f $(BINDIR)/

$(BINDIR)/bdl_menu.42f: bdl_menu.per
	$(FORMCOMP) $<
	mv bdl_menu.42f $(BINDIR)/

# Common modules for cross-navigation
CORE_MODULES = main_lib.4gl list_view_helper.4gl controller.4gl dispatch.4gl \
               employees.4gl empl_terr.4gl territories.4gl region.4gl \
               orders.4gl order_details.4gl customers.4gl shippers.4gl \
               products.4gl suppliers.4gl categories.4gl usstates.4gl

CORE_42M = main_lib.42m list_view_helper.42m controller.42m dispatch.42m \
           employees.42m empl_terr.42m territories.42m region.42m \
           orders.42m order_details.42m customers.42m shippers.42m \
           products.42m suppliers.42m categories.42m usstates.42m

# Report modules
RPT_MODULES = rpt_orders_by_customer.4gl rpt_orders_by_employee.4gl \
              rpt_orders_by_product.4gl rpt_orders_by_daterange.4gl \
              rpt_orders_generic.4gl

RPT_42M = rpt_orders_by_customer.42m rpt_orders_by_employee.42m \
          rpt_orders_by_product.42m rpt_orders_by_daterange.42m \
          rpt_orders_generic.42m

# Program compilation rules
$(BINDIR)/bdl_menu.42r: bdl_menu.4gl main_lib.4gl
	$(SRCCOMP) -o bdl_menu.42r $^
	mv bdl_menu.42r bdl_menu.42m main_lib.42m $(BINDIR)/

$(BINDIR)/ifx_menu.42r: ifx_menu.4gl
	$(SRCCOMP) -o ifx_menu.42r $^
	mv ifx_menu.42r ifx_menu.42m $(BINDIR)/

$(BINDIR)/main_employees.42r: main_employees.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_employees.42r $^
	mv main_employees.42r main_employees.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_empl_terr.42r: main_empl_terr.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_empl_terr.42r $^
	mv main_empl_terr.42r main_empl_terr.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_region.42r: main_region.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_region.42r $^
	mv main_region.42r main_region.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_territories.42r: main_territories.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_territories.42r $^
	mv main_territories.42r main_territories.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_orders.42r: main_orders.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_orders.42r $^
	mv main_orders.42r main_orders.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_order_details.42r: main_order_details.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_order_details.42r $^
	mv main_order_details.42r main_order_details.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_categories.42r: main_categories.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_categories.42r $^
	mv main_categories.42r main_categories.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_customers.42r: main_customers.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_customers.42r $^
	mv main_customers.42r main_customers.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_products.42r: main_products.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_products.42r $^
	mv main_products.42r main_products.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_shippers.42r: main_shippers.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_shippers.42r $^
	mv main_shippers.42r main_shippers.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_suppliers.42r: main_suppliers.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_suppliers.42r $^
	mv main_suppliers.42r main_suppliers.42m $(CORE_42M) $(BINDIR)/

$(BINDIR)/main_usstates.42r: main_usstates.4gl $(CORE_MODULES)
	$(SRCCOMP) -o main_usstates.42r $^
	mv main_usstates.42r main_usstates.42m $(CORE_42M) $(BINDIR)/

# Report program compilation rules
$(BINDIR)/main_rpt_orders_by_customer.42r: main_rpt_orders_by_customer.4gl main_lib.4gl report_helper.4gl rpt_orders_by_customer.4gl
	$(SRCCOMP) -o main_rpt_orders_by_customer.42r $^
	mv main_rpt_orders_by_customer.42r main_rpt_orders_by_customer.42m main_lib.42m report_helper.42m rpt_orders_by_customer.42m $(BINDIR)/

$(BINDIR)/main_rpt_orders_by_employee.42r: main_rpt_orders_by_employee.4gl main_lib.4gl report_helper.4gl rpt_orders_by_employee.4gl
	$(SRCCOMP) -o main_rpt_orders_by_employee.42r $^
	mv main_rpt_orders_by_employee.42r main_rpt_orders_by_employee.42m main_lib.42m report_helper.42m rpt_orders_by_employee.42m $(BINDIR)/

$(BINDIR)/main_rpt_orders_by_product.42r: main_rpt_orders_by_product.4gl main_lib.4gl report_helper.4gl rpt_orders_by_product.4gl
	$(SRCCOMP) -o main_rpt_orders_by_product.42r $^
	mv main_rpt_orders_by_product.42r main_rpt_orders_by_product.42m main_lib.42m report_helper.42m rpt_orders_by_product.42m $(BINDIR)/

$(BINDIR)/main_rpt_orders_by_daterange.42r: main_rpt_orders_by_daterange.4gl main_lib.4gl report_helper.4gl rpt_orders_by_daterange.4gl
	$(SRCCOMP) -o main_rpt_orders_by_daterange.42r $^
	mv main_rpt_orders_by_daterange.42r main_rpt_orders_by_daterange.42m main_lib.42m report_helper.42m rpt_orders_by_daterange.42m $(BINDIR)/

$(BINDIR)/main_rpt_orders_generic.42r: main_rpt_orders_generic.4gl main_lib.4gl report_helper.4gl rpt_orders_generic.4gl
	$(SRCCOMP) -o main_rpt_orders_generic.42r $^
	mv main_rpt_orders_generic.42r main_rpt_orders_generic.42m main_lib.42m report_helper.42m rpt_orders_generic.42m $(BINDIR)/

# Clean compiled files
clean:
	rm -f *.42f *.42m *.42r
	rm -f $(BINDIR)/*.42f $(BINDIR)/*.42m $(BINDIR)/*.42r

# Clean and rebuild
rebuild: clean all

# Individual targets for convenience
employees: $(BINDIR)/employees.42f $(BINDIR)/employees_list.42f $(BINDIR)/main_employees.42r
empl_terr: $(BINDIR)/empl_terr.42f $(BINDIR)/empl_terr_list.42f $(BINDIR)/main_empl_terr.42r
region: $(BINDIR)/region.42f $(BINDIR)/region_list.42f $(BINDIR)/main_region.42r
territories: $(BINDIR)/territories.42f $(BINDIR)/territories_list.42f $(BINDIR)/main_territories.42r
orders: $(BINDIR)/orders.42f $(BINDIR)/orders_list.42f $(BINDIR)/main_orders.42r
order_details: $(BINDIR)/order_details.42f $(BINDIR)/order_details_list.42f $(BINDIR)/main_order_details.42r
categories: $(BINDIR)/categories.42f $(BINDIR)/categories_list.42f $(BINDIR)/main_categories.42r
customers: $(BINDIR)/customers.42f $(BINDIR)/customers_list.42f $(BINDIR)/main_customers.42r
products: $(BINDIR)/products.42f $(BINDIR)/products_list.42f $(BINDIR)/main_products.42r
shippers: $(BINDIR)/shippers.42f $(BINDIR)/shippers_list.42f $(BINDIR)/main_shippers.42r
suppliers: $(BINDIR)/suppliers.42f $(BINDIR)/main_suppliers.42r
usstates: $(BINDIR)/usstates.42f $(BINDIR)/usstates_list.42f $(BINDIR)/main_usstates.42r

ifx_menu: $(BINDIR)/ifx_menu.42r

# Report convenience targets
rpt_orders_by_customer: $(BINDIR)/rpt_orders_by_customer.42f $(BINDIR)/main_rpt_orders_by_customer.42r
rpt_orders_by_employee: $(BINDIR)/rpt_orders_by_employee.42f $(BINDIR)/main_rpt_orders_by_employee.42r
rpt_orders_by_product: $(BINDIR)/rpt_orders_by_product.42f $(BINDIR)/main_rpt_orders_by_product.42r
rpt_orders_by_daterange: $(BINDIR)/rpt_orders_by_daterange.42f $(BINDIR)/main_rpt_orders_by_daterange.42r

bdl_menu: $(BINDIR)/bdl_menu.42f $(BINDIR)/bdl_menu.42r

# Report convenience targets
rpt_orders_by_customer: $(BINDIR)/rpt_orders_by_customer.42f $(BINDIR)/main_rpt_orders_by_customer.42r
rpt_orders_by_employee: $(BINDIR)/rpt_orders_by_employee.42f $(BINDIR)/main_rpt_orders_by_employee.42r
rpt_orders_by_product: $(BINDIR)/rpt_orders_by_product.42f $(BINDIR)/main_rpt_orders_by_product.42r
rpt_orders_by_daterange: $(BINDIR)/rpt_orders_by_daterange.42f $(BINDIR)/main_rpt_orders_by_daterange.42r
rpt_orders_generic: $(BINDIR)/rpt_orders_generic.42f $(BINDIR)/main_rpt_orders_generic.42r

.PHONY: all clean rebuild employees empl_terr region territories orders order_details categories customers products shippers suppliers usstates rpt_orders_by_customer rpt_orders_by_employee rpt_orders_by_product rpt_orders_by_daterange rpt_orders_generic ifx_menu bdl_menu
