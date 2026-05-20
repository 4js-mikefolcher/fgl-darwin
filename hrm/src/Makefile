# Makefile for Genero BDL Application
# Compiles .per forms and .4gl modules.
#
# Every .4gl source — library OR main program — compiles to a .42m via
# `fglcomp -M`. There is no `fgl2p` link step: IMPORT FGL chains are
# resolved at runtime by `fglrun` via FGLLDPATH (configured below).
#
# To launch a program:   fglrun bin/main_employees    (no extension needed)
# To launch a form:      handled by the program itself

# Directories
BINDIR = ../../bin

# Compilers
FORMCOMP = fglform
MODCOMP  = fglcomp -M

# ----------------------------------------------------------------------
# FGLLDPATH for fglcomp / fglrun
# ----------------------------------------------------------------------
# fglcomp must find imported modules to verify call signatures:
#   - BINDIR       — sibling app modules already compiled to .42m
#   - PKGDIR/*     — fglpkg packages (poiapi, aim, restdblib, fglunit)
#   - $$FGLLDPATH  — leave anything the caller already set
PROJECT_ROOT = ../..
PKGDIR       = $(PROJECT_ROOT)/.fglpkg/packages
PKG_PATHS    = $(PKGDIR)/poiapi:$(PKGDIR)/aim:$(PKGDIR)/restdblib:$(PKGDIR)/fglunit
LDPATH       = FGLLDPATH=$(BINDIR):$(PKG_PATHS):$$FGLLDPATH

# Source files
FORMS = employees.per employees_list.per empl_terr.per empl_terr_list.per region.per region_list.per territories.per territories_list.per \
        orders.per orders_list.per order_details.per order_details_list.per \
        categories.per categories_list.per customers.per customers_list.per \
        products.per products_list.per shippers.per shippers_list.per \
        suppliers.per suppliers_list.per usstates.per usstates_list.per \
        cust_demo.per cust_demo_list.per cust_cust_demo.per cust_cust_demo_list.per \
        md_order_details.per mstr_order_list.per advsearch_orders.per \
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

# ----------------------------------------------------------------------
# All .4gl source files (libraries AND program entry points).
# Every .4gl compiles to .42m the same way; programs are distinguished
# from libraries only by having a MAIN block.
# ----------------------------------------------------------------------
MODULE_SOURCES = \
    main_lib.4gl list_view_helper.4gl controller.4gl dispatch.4gl \
    model_helper.4gl \
    model_employees.4gl model_empl_terr.4gl model_territories.4gl model_region.4gl \
    model_orders.4gl model_order_details.4gl model_customers.4gl model_shippers.4gl \
    model_products.4gl model_suppliers.4gl model_categories.4gl model_usstates.4gl \
    ui_employees.4gl ui_empl_terr.4gl ui_territories.4gl ui_region.4gl \
    ui_orders.4gl ui_order_details.4gl ui_customers.4gl ui_shippers.4gl \
    ui_products.4gl ui_suppliers.4gl ui_categories.4gl ui_usstates.4gl \
    model_cust_demo.4gl model_cust_cust_demo.4gl \
    ui_cust_demo.4gl ui_cust_cust_demo.4gl \
    md_order_details.4gl md_helper.4gl \
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
    rest_cust_demo.4gl rest_cust_cust_demo.4gl \
    test_rest_lib.4gl \
    bdl_menu.4gl ifx_menu.4gl mstr_dtl_order.4gl \
    main_employees.4gl main_empl_terr.4gl main_region.4gl main_territories.4gl \
    main_orders.4gl main_order_details.4gl main_categories.4gl main_customers.4gl \
    main_products.4gl main_shippers.4gl main_suppliers.4gl main_usstates.4gl \
    main_cust_demo.4gl main_cust_cust_demo.4gl \
    main_rpt_orders_by_customer.4gl main_rpt_orders_by_employee.4gl \
    main_rpt_orders_by_product.4gl main_rpt_orders_by_daterange.4gl \
    main_rpt_orders_generic.4gl main_rpt_org_chart.4gl \
    main_rpt_products_by_category.4gl main_rpt_employees_with_totals.4gl \
    main_rest_server.4gl \
    test_rest_shippers.4gl test_rest_categories.4gl test_rest_suppliers.4gl \
    test_rest_region.4gl test_rest_usstates.4gl test_rest_products.4gl \
    test_rest_customers.4gl test_rest_territories.4gl test_rest_employees.4gl \
    test_rest_orders.4gl test_rest_order_details.4gl test_rest_cust_demo.4gl \
    test_rest_empl_terr.4gl test_rest_cust_cust_demo.4gl

# Compiled module targets (.42m in bin/)
MODULE_TARGETS = $(patsubst %.4gl,$(BINDIR)/%.42m,$(MODULE_SOURCES))

# ----------------------------------------------------------------------
# Default target — build forms + all .42m modules.
# ----------------------------------------------------------------------
all: $(BINDIR) $(FORM_TARGETS) $(MODULE_TARGETS)

$(BINDIR):
	mkdir -p $(BINDIR)

# Generic rule: compile any .4gl to .42m and move to bin/.
# Library modules and main programs both follow this rule.
$(BINDIR)/%.42m: %.4gl
	$(LDPATH) $(MODCOMP) $<
	mv $*.42m $(BINDIR)/

# ----------------------------------------------------------------------
# Form compilation rules
# ----------------------------------------------------------------------
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

# ----------------------------------------------------------------------
# Clean — remove compiled forms + modules. Also nukes any stale .42r
# from the old fgl2p-based build.
# ----------------------------------------------------------------------
clean:
	rm -f *.42f *.42m *.42r
	rm -f $(BINDIR)/*.42f $(BINDIR)/*.42m $(BINDIR)/*.42r

# Clean and rebuild
rebuild: clean all

# Compile all modules (convenience target — same as `all` minus forms)
modules: $(MODULE_TARGETS)

# ----------------------------------------------------------------------
# Per-program convenience targets — each pulls in the program's .42m
# plus its forms. Programs are launched via `fglrun <name>` (no
# extension); fglrun finds the .42m through FGLLDPATH.
# ----------------------------------------------------------------------
employees:        $(BINDIR)/employees.42f $(BINDIR)/employees_list.42f $(BINDIR)/main_employees.42m
empl_terr:        $(BINDIR)/empl_terr.42f $(BINDIR)/empl_terr_list.42f $(BINDIR)/main_empl_terr.42m
region:           $(BINDIR)/region.42f $(BINDIR)/region_list.42f $(BINDIR)/main_region.42m
territories:      $(BINDIR)/territories.42f $(BINDIR)/territories_list.42f $(BINDIR)/main_territories.42m
orders:           $(BINDIR)/orders.42f $(BINDIR)/orders_list.42f $(BINDIR)/main_orders.42m
order_details:    $(BINDIR)/order_details.42f $(BINDIR)/order_details_list.42f $(BINDIR)/main_order_details.42m
categories:       $(BINDIR)/categories.42f $(BINDIR)/categories_list.42f $(BINDIR)/main_categories.42m
customers:        $(BINDIR)/customers.42f $(BINDIR)/customers_list.42f $(BINDIR)/main_customers.42m
products:         $(BINDIR)/products.42f $(BINDIR)/products_list.42f $(BINDIR)/main_products.42m
shippers:         $(BINDIR)/shippers.42f $(BINDIR)/shippers_list.42f $(BINDIR)/main_shippers.42m
suppliers:        $(BINDIR)/suppliers.42f $(BINDIR)/main_suppliers.42m
usstates:         $(BINDIR)/usstates.42f $(BINDIR)/usstates_list.42f $(BINDIR)/main_usstates.42m
cust_demo:        $(BINDIR)/cust_demo.42f $(BINDIR)/cust_demo_list.42f $(BINDIR)/main_cust_demo.42m
cust_cust_demo:   $(BINDIR)/cust_cust_demo.42f $(BINDIR)/cust_cust_demo_list.42f $(BINDIR)/main_cust_cust_demo.42m
mstr_dtl_order:   $(BINDIR)/md_order_details.42f $(BINDIR)/mstr_order_list.42f $(BINDIR)/advsearch_orders.42f $(BINDIR)/mstr_dtl_order.42m

ifx_menu:         $(BINDIR)/ifx_menu.42m
bdl_menu:         $(BINDIR)/bdl_menu.42f $(BINDIR)/bdl_menu.42m

# Report convenience targets
rpt_orders_by_customer:     $(BINDIR)/rpt_orders_by_customer.42f $(BINDIR)/main_rpt_orders_by_customer.42m
rpt_orders_by_employee:     $(BINDIR)/rpt_orders_by_employee.42f $(BINDIR)/main_rpt_orders_by_employee.42m
rpt_orders_by_product:      $(BINDIR)/rpt_orders_by_product.42f $(BINDIR)/main_rpt_orders_by_product.42m
rpt_orders_by_daterange:    $(BINDIR)/rpt_orders_by_daterange.42f $(BINDIR)/main_rpt_orders_by_daterange.42m
rpt_orders_generic:         $(BINDIR)/rpt_orders_generic.42f $(BINDIR)/main_rpt_orders_generic.42m
rpt_org_chart:              $(BINDIR)/rpt_org_chart.42f $(BINDIR)/main_rpt_org_chart.42m
rpt_products_by_category:   $(BINDIR)/rpt_products_by_category.42f $(BINDIR)/main_rpt_products_by_category.42m
rpt_employees_with_totals:  $(BINDIR)/rpt_employees_with_totals.42f $(BINDIR)/main_rpt_employees_with_totals.42m

rest_server: $(BINDIR)/main_rest_server.42m

test_rest_shippers:        $(BINDIR)/test_rest_shippers.42m
test_rest_categories:      $(BINDIR)/test_rest_categories.42m
test_rest_suppliers:       $(BINDIR)/test_rest_suppliers.42m
test_rest_region:          $(BINDIR)/test_rest_region.42m
test_rest_usstates:        $(BINDIR)/test_rest_usstates.42m
test_rest_products:        $(BINDIR)/test_rest_products.42m
test_rest_customers:       $(BINDIR)/test_rest_customers.42m
test_rest_territories:     $(BINDIR)/test_rest_territories.42m
test_rest_employees:       $(BINDIR)/test_rest_employees.42m
test_rest_orders:          $(BINDIR)/test_rest_orders.42m
test_rest_order_details:   $(BINDIR)/test_rest_order_details.42m
test_rest_cust_demo:       $(BINDIR)/test_rest_cust_demo.42m
test_rest_empl_terr:       $(BINDIR)/test_rest_empl_terr.42m
test_rest_cust_cust_demo:  $(BINDIR)/test_rest_cust_cust_demo.42m
test_rest: \
    $(BINDIR)/test_rest_shippers.42m $(BINDIR)/test_rest_categories.42m \
    $(BINDIR)/test_rest_suppliers.42m $(BINDIR)/test_rest_region.42m \
    $(BINDIR)/test_rest_usstates.42m $(BINDIR)/test_rest_products.42m \
    $(BINDIR)/test_rest_customers.42m $(BINDIR)/test_rest_territories.42m \
    $(BINDIR)/test_rest_employees.42m $(BINDIR)/test_rest_orders.42m \
    $(BINDIR)/test_rest_order_details.42m $(BINDIR)/test_rest_cust_demo.42m \
    $(BINDIR)/test_rest_empl_terr.42m $(BINDIR)/test_rest_cust_cust_demo.42m

.PHONY: all clean rebuild modules \
    employees empl_terr region territories orders order_details \
    categories customers products shippers suppliers usstates \
    cust_demo cust_cust_demo mstr_dtl_order \
    rpt_orders_by_customer rpt_orders_by_employee rpt_orders_by_product \
    rpt_orders_by_daterange rpt_orders_generic rpt_org_chart \
    rpt_products_by_category rpt_employees_with_totals \
    ifx_menu bdl_menu rest_server \
    test_rest_shippers test_rest_categories test_rest_suppliers \
    test_rest_region test_rest_usstates test_rest_products \
    test_rest_customers test_rest_territories test_rest_employees \
    test_rest_orders test_rest_order_details test_rest_cust_demo \
    test_rest_empl_terr test_rest_cust_cust_demo test_rest
