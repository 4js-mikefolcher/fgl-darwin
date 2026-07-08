# Makefile for fglunit test suite
# Compiles and runs fglunit tests for hrm/src modules.
#
# Usage:
#   make                   — compile all test programs
#   make test              — compile and run all tests
#   make test_model_helper — compile one test program
#   make run_model_helper  — compile and run one test program
#   make clean             — remove compiled output
#
# Tests that touch the database need a running northwind Postgres instance
# matching the FGLPROFILE config in dbs/postgres/fglprofile.pgs. The 'test'
# target sets FGLPROFILE automatically.

BINDIR  = ../../bin
SRCDIR  = ../src
MODCOMP = fglcomp -M
SRCCOMP = fgl2p

# Project root holds .fglpkg/packages/ with installed fglunit + deps.
PROJECT_ROOT = ../..
PKGDIR       = $(PROJECT_ROOT)/.fglpkg/packages
FGLPROFILE   = $(PROJECT_ROOT)/dbs/postgres/fglprofile.pgs

# FGLLDPATH must include:
#   1. BINDIR     — compiled hrm/src modules (model_*, main_lib, etc.)
#   2. .          — sibling test modules (test_db_helper, etc.)
#   3. PKGDIR/*   — installed fglpkg packages (fglunit, aim, poiapi, restdblib)
#   4. caller env — leave whatever was already set
PKG_PATHS = $(PKGDIR)/fglunit:$(PKGDIR)/aim:$(PKGDIR)/poiapi:$(PKGDIR)/restdblib
LDPATH    = FGLLDPATH=.:$(BINDIR):$(PKG_PATHS):$$FGLLDPATH DBPATH=$(SRCDIR):$$DBPATH
RUNPATH   = $(LDPATH) FGLPROFILE=$(FGLPROFILE)

# -----------------------------------------------------------------------
# Shared test-only modules (compiled before the test programs that use
# them so IMPORT FGL resolves at link time).
# -----------------------------------------------------------------------
HELPER_MODS = test_db_helper.42m

# -----------------------------------------------------------------------
# Test programs — add one entry per test file as you create them
# -----------------------------------------------------------------------
TEST_TARGETS = \
	$(BINDIR)/test_model_helper.42r \
	$(BINDIR)/test_main_lib.42r \
	$(BINDIR)/test_model_categories.42r \
	$(BINDIR)/test_model_customers.42r \
	$(BINDIR)/test_model_employees.42r \
	$(BINDIR)/test_model_orders.42r \
	$(BINDIR)/test_model_order_details.42r \
	$(BINDIR)/test_model_products.42r \
	$(BINDIR)/test_model_shippers.42r \
	$(BINDIR)/test_model_suppliers.42r \
	$(BINDIR)/test_model_territories.42r \
	$(BINDIR)/test_model_region.42r \
	$(BINDIR)/test_model_usstates.42r \
	$(BINDIR)/test_model_cust_demo.42r \
	$(BINDIR)/test_model_cust_cust_demo.42r \
	$(BINDIR)/test_model_empl_terr.42r

# Default: compile everything
all: $(BINDIR) $(HELPER_MODS) $(TEST_TARGETS)

$(BINDIR):
	mkdir -p $(BINDIR)

# Compile helper module(s) to a .42m next to the test sources; LDPATH adds
# the current directory so test programs can IMPORT FGL test_db_helper.
test_db_helper.42m: test_db_helper.4gl
	$(LDPATH) $(MODCOMP) $<

# -----------------------------------------------------------------------
# Generic rule: compile a test .4gl in this directory and link it.
# Depends on the helper modules so they exist before any test that imports
# them is linked.
# -----------------------------------------------------------------------
$(BINDIR)/%.42r: %.4gl $(HELPER_MODS)
	$(LDPATH) $(MODCOMP) $<
	$(LDPATH) $(SRCCOMP) -o $*.42r $<
	mv $*.42r $*.42m $(BINDIR)/

# -----------------------------------------------------------------------
# Run targets — compile then execute with fglrun (terminal mode, no GUI)
# -----------------------------------------------------------------------
FGLRUN = FGLGUI=0 TERM=xterm fglrun

test: all
	@echo "=== fglunit test suite ==="
	@failed=0; \
	for t in $(TEST_TARGETS); do \
		echo "--- $$t ---"; \
		$(RUNPATH) $(FGLRUN) $$t || failed=$$((failed+1)); \
	done; \
	echo "=== done ==="; \
	exit $$failed

# Individual compile targets
test_model_helper:      $(BINDIR)/test_model_helper.42r
test_main_lib:          $(BINDIR)/test_main_lib.42r
test_model_categories:  $(BINDIR)/test_model_categories.42r
test_model_customers:   $(BINDIR)/test_model_customers.42r
test_model_employees:   $(BINDIR)/test_model_employees.42r
test_model_orders:      $(BINDIR)/test_model_orders.42r
test_model_order_details: $(BINDIR)/test_model_order_details.42r
test_model_products:    $(BINDIR)/test_model_products.42r
test_model_shippers:    $(BINDIR)/test_model_shippers.42r
test_model_suppliers:   $(BINDIR)/test_model_suppliers.42r
test_model_territories: $(BINDIR)/test_model_territories.42r
test_model_region:      $(BINDIR)/test_model_region.42r
test_model_usstates:    $(BINDIR)/test_model_usstates.42r
test_model_cust_demo:   $(BINDIR)/test_model_cust_demo.42r
test_model_cust_cust_demo: $(BINDIR)/test_model_cust_cust_demo.42r
test_model_empl_terr:   $(BINDIR)/test_model_empl_terr.42r

# Individual run targets
run_model_helper:      $(BINDIR)/test_model_helper.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_helper.42r
run_main_lib:          $(BINDIR)/test_main_lib.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_main_lib.42r
run_model_categories:  $(BINDIR)/test_model_categories.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_categories.42r
run_model_customers:   $(BINDIR)/test_model_customers.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_customers.42r
run_model_employees:   $(BINDIR)/test_model_employees.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_employees.42r
run_model_orders:      $(BINDIR)/test_model_orders.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_orders.42r
run_model_order_details: $(BINDIR)/test_model_order_details.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_order_details.42r
run_model_products:    $(BINDIR)/test_model_products.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_products.42r
run_model_shippers:    $(BINDIR)/test_model_shippers.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_shippers.42r
run_model_suppliers:   $(BINDIR)/test_model_suppliers.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_suppliers.42r
run_model_territories: $(BINDIR)/test_model_territories.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_territories.42r
run_model_region:      $(BINDIR)/test_model_region.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_region.42r
run_model_usstates:    $(BINDIR)/test_model_usstates.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_usstates.42r
run_model_cust_demo:   $(BINDIR)/test_model_cust_demo.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_cust_demo.42r
run_model_cust_cust_demo: $(BINDIR)/test_model_cust_cust_demo.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_cust_cust_demo.42r
run_model_empl_terr:   $(BINDIR)/test_model_empl_terr.42r
	$(RUNPATH) $(FGLRUN) $(BINDIR)/test_model_empl_terr.42r

# -----------------------------------------------------------------------
clean:
	rm -f *.42m
	rm -f $(BINDIR)/test_*.42r $(BINDIR)/test_*.42m

.PHONY: all test clean \
	test_model_helper test_main_lib \
	test_model_categories test_model_customers test_model_employees \
	test_model_orders test_model_order_details test_model_products \
	test_model_shippers test_model_suppliers test_model_territories \
	test_model_region test_model_usstates test_model_cust_demo \
	test_model_cust_cust_demo test_model_empl_terr \
	run_model_helper run_main_lib \
	run_model_categories run_model_customers run_model_employees \
	run_model_orders run_model_order_details run_model_products \
	run_model_shippers run_model_suppliers run_model_territories \
	run_model_region run_model_usstates run_model_cust_demo \
	run_model_cust_cust_demo run_model_empl_terr
