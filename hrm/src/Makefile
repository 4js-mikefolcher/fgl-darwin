# Makefile for Genero BDL Application
# Compiles .per forms and .4gl modules

# Directories
BINDIR = ../../bin

# Compilers
FORMCOMP = fglform
SRCCOMP = fgl2p

# FGLLDPATH for linking: include bin dir + existing system paths
LDPATH = FGLLDPATH=$(BINDIR):$$FGLLDPATH

# Source files
FORMS = employees.per employees_list.per empl_terr.per empl_terr_list.per region.per region_list.per territories.per territories_list.per \
        orders.per orders_list.per order_details.per order_details_list.per \
        categories.per categories_list.per customers.per customers_list.per \
        products.per products_list.per shippers.per shippers_list.per \
        suppliers.per suppliers_list.per usstates.per usstates_list.per \
        cust_demo.per cust_demo_list.per cust_cust_demo.per cust_cust_demo_list.per \
        md_orders.per md_order_details.per mstr_order_list.per advsearch_orders.per \
        rpt_orders_by_customer.per rpt_orders_by_employee.per rpt_orders_by_product.per \
        rpt_orders_by_daterange.per rpt_orders_generic.per rpt_org_chart.per \
        rpt_products_by_category.per rpt_employees_with_totals.per report_viewer.per bdl_menu.per

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
               $(BINDIR)/cust_demo.42f \
               $(BINDIR)/cust_demo_list.42f \
               $(BINDIR)/cust_cust_demo.42f \
               $(BINDIR)/cust_cust_demo_list.42f \
               $(BINDIR)/md_orders.42f \
               $(BINDIR)/md_order_details.42f \
               $(BINDIR)/mstr_order_list.42f \
               $(BINDIR)/advsearch_orders.42f \
               $(BINDIR)/rpt_orders_by_customer.42f \
               $(BINDIR)/rpt_orders_by_employee.42f \
               $(BINDIR)/rpt_orders_by_product.42f \
               $(BINDIR)/rpt_orders_by_daterange.42f \
               $(BINDIR)/rpt_orders_generic.42f \
               $(BINDIR)/rpt_org_chart.42f \
               $(BINDIR)/rpt_products_by_category.42f \
               $(BINDIR)/rpt_employees_with_totals.42f \
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
               $(BINDIR)/main_cust_demo.42r \
               $(BINDIR)/main_cust_cust_demo.42r \
               $(BINDIR)/main_md_orders.42r \
               $(BINDIR)/mstr_dtl_order.42r \
               $(BINDIR)/main_rpt_orders_by_customer.42r \
               $(BINDIR)/main_rpt_orders_by_employee.42r \
               $(BINDIR)/main_rpt_orders_by_product.42r \
               $(BINDIR)/main_rpt_orders_by_daterange.42r \
               $(BINDIR)/main_rpt_orders_generic.42r \
               $(BINDIR)/main_rpt_org_chart.42r \
               $(BINDIR)/main_rpt_products_by_category.42r \
               $(BINDIR)/main_rpt_employees_with_totals.42r \
               $(BINDIR)/main_rest_server.42r

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

$(BINDIR)/rpt_org_chart.42f: rpt_org_chart.per
	$(FORMCOMP) $<
	mv rpt_org_chart.42f $(BINDIR)/

$(BINDIR)/rpt_products_by_category.42f: rpt_products_by_category.per
	$(FORMCOMP) $<
	mv rpt_products_by_category.42f $(BINDIR)/

$(BINDIR)/rpt_employees_with_totals.42f: rpt_employees_with_totals.per
	$(FORMCOMP) $<
	mv rpt_employees_with_totals.42f $(BINDIR)/

$(BINDIR)/report_viewer.42f: report_viewer.per
	$(FORMCOMP) $<
	mv report_viewer.42f $(BINDIR)/

$(BINDIR)/cust_demo.42f: cust_demo.per
	$(FORMCOMP) $<
	mv cust_demo.42f $(BINDIR)/

$(BINDIR)/cust_demo_list.42f: cust_demo_list.per
	$(FORMCOMP) $<
	mv cust_demo_list.42f $(BINDIR)/

$(BINDIR)/cust_cust_demo.42f: cust_cust_demo.per
	$(FORMCOMP) $<
	mv cust_cust_demo.42f $(BINDIR)/

$(BINDIR)/cust_cust_demo_list.42f: cust_cust_demo_list.per
	$(FORMCOMP) $<
	mv cust_cust_demo_list.42f $(BINDIR)/

$(BINDIR)/md_orders.42f: md_orders.per
	$(FORMCOMP) $<
	mv md_orders.42f $(BINDIR)/

$(BINDIR)/md_order_details.42f: md_order_details.per
	$(FORMCOMP) $<
	mv md_order_details.42f $(BINDIR)/

$(BINDIR)/mstr_order_list.42f: mstr_order_list.per
	$(FORMCOMP) $<
	mv mstr_order_list.42f $(BINDIR)/

$(BINDIR)/advsearch_orders.42f: advsearch_orders.per
	$(FORMCOMP) $<
	mv advsearch_orders.42f $(BINDIR)/

$(BINDIR)/bdl_menu.42f: bdl_menu.per
	$(FORMCOMP) $<
	mv bdl_menu.42f $(BINDIR)/

# Module compiler (individual .4gl -> .42m)
MODCOMP = fglcomp -M

# All library/module source files (compiled individually to .42m)
MODULE_SOURCES = main_lib.4gl list_view_helper.4gl controller.4gl dispatch.4gl \
                 model_helper.4gl \
                 model_employees.4gl model_empl_terr.4gl model_territories.4gl model_region.4gl \
                 model_orders.4gl model_order_details.4gl model_customers.4gl model_shippers.4gl \
                 model_products.4gl model_suppliers.4gl model_categories.4gl model_usstates.4gl \
                 ui_employees.4gl ui_empl_terr.4gl ui_territories.4gl ui_region.4gl \
                 ui_orders.4gl ui_order_details.4gl ui_customers.4gl ui_shippers.4gl \
                 ui_products.4gl ui_suppliers.4gl ui_categories.4gl ui_usstates.4gl \
                 model_cust_demo.4gl model_cust_cust_demo.4gl \
                 ui_cust_demo.4gl ui_cust_cust_demo.4gl \
                 md_orders.4gl md_order_details.4gl md_helper.4gl \
                 advsearch_orders.4gl dialog_prompt.4gl \
                 report_helper.4gl \
                 rpt_orders_by_customer.4gl rpt_orders_by_employee.4gl \
                 rpt_orders_by_product.4gl rpt_orders_by_daterange.4gl \
                 rpt_orders_generic.4gl rpt_org_chart.4gl \
                 rpt_products_by_category.4gl rpt_employees_with_totals.4gl \
                 rest_categories.4gl rest_customers.4gl rest_employees.4gl \
                 rest_orders.4gl rest_order_details.4gl rest_products.4gl \
                 rest_suppliers.4gl rest_shippers.4gl rest_region.4gl \
                 rest_territories.4gl rest_usstates.4gl rest_empl_terr.4gl \
                 rest_cust_demo.4gl rest_cust_cust_demo.4gl

# Compiled module targets (.42m in bin/)
MODULE_TARGETS = $(patsubst %.4gl,$(BINDIR)/%.42m,$(MODULE_SOURCES))

# Generic rule: compile any .4gl module to .42m and move to bin/
$(BINDIR)/%.42m: %.4gl
	$(MODCOMP) $<
	mv $*.42m $(BINDIR)/

# Program linking rules (each main program links only itself; deps resolved via IMPORT FGL)
# FGLLDPATH tells fgl2p where to find imported .42m modules
$(BINDIR)/bdl_menu.42r: bdl_menu.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o bdl_menu.42r bdl_menu.4gl
	mv bdl_menu.42r bdl_menu.42m $(BINDIR)/

$(BINDIR)/ifx_menu.42r: ifx_menu.4gl
	$(SRCCOMP) -o ifx_menu.42r ifx_menu.4gl
	mv ifx_menu.42r ifx_menu.42m $(BINDIR)/

$(BINDIR)/main_employees.42r: main_employees.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_employees.42r main_employees.4gl
	mv main_employees.42r main_employees.42m $(BINDIR)/

$(BINDIR)/main_empl_terr.42r: main_empl_terr.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_empl_terr.42r main_empl_terr.4gl
	mv main_empl_terr.42r main_empl_terr.42m $(BINDIR)/

$(BINDIR)/main_region.42r: main_region.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_region.42r main_region.4gl
	mv main_region.42r main_region.42m $(BINDIR)/

$(BINDIR)/main_territories.42r: main_territories.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_territories.42r main_territories.4gl
	mv main_territories.42r main_territories.42m $(BINDIR)/

$(BINDIR)/main_orders.42r: main_orders.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_orders.42r main_orders.4gl
	mv main_orders.42r main_orders.42m $(BINDIR)/

$(BINDIR)/main_order_details.42r: main_order_details.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_order_details.42r main_order_details.4gl
	mv main_order_details.42r main_order_details.42m $(BINDIR)/

$(BINDIR)/main_categories.42r: main_categories.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_categories.42r main_categories.4gl
	mv main_categories.42r main_categories.42m $(BINDIR)/

$(BINDIR)/main_customers.42r: main_customers.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_customers.42r main_customers.4gl
	mv main_customers.42r main_customers.42m $(BINDIR)/

$(BINDIR)/main_products.42r: main_products.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_products.42r main_products.4gl
	mv main_products.42r main_products.42m $(BINDIR)/

$(BINDIR)/main_shippers.42r: main_shippers.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_shippers.42r main_shippers.4gl
	mv main_shippers.42r main_shippers.42m $(BINDIR)/

$(BINDIR)/main_suppliers.42r: main_suppliers.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_suppliers.42r main_suppliers.4gl
	mv main_suppliers.42r main_suppliers.42m $(BINDIR)/

$(BINDIR)/main_usstates.42r: main_usstates.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_usstates.42r main_usstates.4gl
	mv main_usstates.42r main_usstates.42m $(BINDIR)/

$(BINDIR)/main_cust_demo.42r: main_cust_demo.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_cust_demo.42r main_cust_demo.4gl
	mv main_cust_demo.42r main_cust_demo.42m $(BINDIR)/

$(BINDIR)/main_cust_cust_demo.42r: main_cust_cust_demo.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_cust_cust_demo.42r main_cust_cust_demo.4gl
	mv main_cust_cust_demo.42r main_cust_cust_demo.42m $(BINDIR)/

$(BINDIR)/main_md_orders.42r: main_md_orders.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_md_orders.42r main_md_orders.4gl
	mv main_md_orders.42r main_md_orders.42m $(BINDIR)/

$(BINDIR)/mstr_dtl_order.42r: mstr_dtl_order.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o mstr_dtl_order.42r mstr_dtl_order.4gl
	mv mstr_dtl_order.42r mstr_dtl_order.42m $(BINDIR)/

$(BINDIR)/main_rpt_orders_by_customer.42r: main_rpt_orders_by_customer.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_rpt_orders_by_customer.42r main_rpt_orders_by_customer.4gl
	mv main_rpt_orders_by_customer.42r main_rpt_orders_by_customer.42m $(BINDIR)/

$(BINDIR)/main_rpt_orders_by_employee.42r: main_rpt_orders_by_employee.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_rpt_orders_by_employee.42r main_rpt_orders_by_employee.4gl
	mv main_rpt_orders_by_employee.42r main_rpt_orders_by_employee.42m $(BINDIR)/

$(BINDIR)/main_rpt_orders_by_product.42r: main_rpt_orders_by_product.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_rpt_orders_by_product.42r main_rpt_orders_by_product.4gl
	mv main_rpt_orders_by_product.42r main_rpt_orders_by_product.42m $(BINDIR)/

$(BINDIR)/main_rpt_orders_by_daterange.42r: main_rpt_orders_by_daterange.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_rpt_orders_by_daterange.42r main_rpt_orders_by_daterange.4gl
	mv main_rpt_orders_by_daterange.42r main_rpt_orders_by_daterange.42m $(BINDIR)/

$(BINDIR)/main_rpt_orders_generic.42r: main_rpt_orders_generic.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_rpt_orders_generic.42r main_rpt_orders_generic.4gl
	mv main_rpt_orders_generic.42r main_rpt_orders_generic.42m $(BINDIR)/

$(BINDIR)/main_rpt_org_chart.42r: main_rpt_org_chart.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_rpt_org_chart.42r main_rpt_org_chart.4gl
	mv main_rpt_org_chart.42r main_rpt_org_chart.42m $(BINDIR)/

$(BINDIR)/main_rpt_products_by_category.42r: main_rpt_products_by_category.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_rpt_products_by_category.42r main_rpt_products_by_category.4gl
	mv main_rpt_products_by_category.42r main_rpt_products_by_category.42m $(BINDIR)/

$(BINDIR)/main_rpt_employees_with_totals.42r: main_rpt_employees_with_totals.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_rpt_employees_with_totals.42r main_rpt_employees_with_totals.4gl
	mv main_rpt_employees_with_totals.42r main_rpt_employees_with_totals.42m $(BINDIR)/

$(BINDIR)/main_rest_server.42r: main_rest_server.4gl $(MODULE_TARGETS)
	$(LDPATH) $(SRCCOMP) -o main_rest_server.42r main_rest_server.4gl
	mv main_rest_server.42r main_rest_server.42m $(BINDIR)/

# Clean compiled files
clean:
	rm -f *.42f *.42m *.42r
	rm -f $(BINDIR)/*.42f $(BINDIR)/*.42m $(BINDIR)/*.42r

# Clean and rebuild
rebuild: clean all

# Compile all modules (convenience target)
modules: $(MODULE_TARGETS)

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
cust_demo: $(BINDIR)/cust_demo.42f $(BINDIR)/cust_demo_list.42f $(BINDIR)/main_cust_demo.42r
cust_cust_demo: $(BINDIR)/cust_cust_demo.42f $(BINDIR)/cust_cust_demo_list.42f $(BINDIR)/main_cust_cust_demo.42r
md_orders: $(BINDIR)/md_orders.42f $(BINDIR)/main_md_orders.42r
mstr_dtl_order: $(BINDIR)/md_order_details.42f $(BINDIR)/mstr_order_list.42f $(BINDIR)/advsearch_orders.42f $(BINDIR)/mstr_dtl_order.42r

ifx_menu: $(BINDIR)/ifx_menu.42r
bdl_menu: $(BINDIR)/bdl_menu.42f $(BINDIR)/bdl_menu.42r

# Report convenience targets
rpt_orders_by_customer: $(BINDIR)/rpt_orders_by_customer.42f $(BINDIR)/main_rpt_orders_by_customer.42r
rpt_orders_by_employee: $(BINDIR)/rpt_orders_by_employee.42f $(BINDIR)/main_rpt_orders_by_employee.42r
rpt_orders_by_product: $(BINDIR)/rpt_orders_by_product.42f $(BINDIR)/main_rpt_orders_by_product.42r
rpt_orders_by_daterange: $(BINDIR)/rpt_orders_by_daterange.42f $(BINDIR)/main_rpt_orders_by_daterange.42r
rpt_orders_generic: $(BINDIR)/rpt_orders_generic.42f $(BINDIR)/main_rpt_orders_generic.42r
rpt_org_chart: $(BINDIR)/rpt_org_chart.42f $(BINDIR)/main_rpt_org_chart.42r
rpt_products_by_category: $(BINDIR)/rpt_products_by_category.42f $(BINDIR)/main_rpt_products_by_category.42r
rpt_employees_with_totals: $(BINDIR)/rpt_employees_with_totals.42f $(BINDIR)/main_rpt_employees_with_totals.42r

rest_server: $(BINDIR)/main_rest_server.42r

.PHONY: all clean rebuild modules employees empl_terr region territories orders order_details categories customers products shippers suppliers usstates cust_demo cust_cust_demo md_orders mstr_dtl_order rpt_orders_by_customer rpt_orders_by_employee rpt_orders_by_product rpt_orders_by_daterange rpt_orders_generic rpt_org_chart rpt_products_by_category rpt_employees_with_totals ifx_menu bdl_menu rest_server
