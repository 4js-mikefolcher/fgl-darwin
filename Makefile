# Parent Makefile for Genero BDL Application
# Calls the Makefile in the source directory

# Source directory (adjust if your source dir has a different name)
HRMDIR  = hrm
GGCDIR  = ggc-test

# Default target - build everything
all:
	$(MAKE) -C $(HRMDIR)

# Clean compiled files
clean:
	$(MAKE) -C $(HRMDIR) clean
	$(MAKE) -C $(GGCDIR) clean

# Clean and rebuild
rebuild:
	$(MAKE) -C $(HRMDIR) rebuild

# ----------------------------------------------------------------------
# GGC (Genero Ghost Client) test targets
# ----------------------------------------------------------------------
# Prerequisites (run once per shell before the targets below):
#   . $$FGLDIR/testing_utilities/ggc/envggc    # sets GGCDIR + PATH
#   . $$FGLDIR/envcomp                         # sets FGLGWS env
#   ggcadmin startbdlserver &                  # start GGC BDL server
#
# Then:
#   make ggc-build        — compile the ghost client test scenarios
#   make ggc-test         — compile app + run tests (headless)
#   make ggc-test-gui     — run tests with GUI forwarded to GDC
#   make ggc-test-debug   — run tests with guilog on error

ggc-build:
	$(MAKE) -C $(GGCDIR)

ggc-test: all ggc-build
	$(MAKE) -C $(GGCDIR) run

ggc-test-gui: all ggc-build
	$(MAKE) -C $(GGCDIR) run-gui

ggc-test-debug: all ggc-build
	$(MAKE) -C $(GGCDIR) run-debug

ggc-clean:
	$(MAKE) -C $(GGCDIR) clean

# Individual module targets
employees:
	$(MAKE) -C $(HRMDIR) employees

empl_terr:
	$(MAKE) -C $(HRMDIR) empl_terr

region:
	$(MAKE) -C $(HRMDIR) region

territories:
	$(MAKE) -C $(HRMDIR) territories

orders:
	$(MAKE) -C $(HRMDIR) orders

order_details:
	$(MAKE) -C $(HRMDIR) order_details

categories:
	$(MAKE) -C $(HRMDIR) categories

customers:
	$(MAKE) -C $(HRMDIR) customers

products:
	$(MAKE) -C $(HRMDIR) products

shippers:
	$(MAKE) -C $(HRMDIR) shippers

suppliers:
	$(MAKE) -C $(HRMDIR) suppliers

usstates:
	$(MAKE) -C $(HRMDIR) usstates

mstr_dtl_order:
	$(MAKE) -C $(HRMDIR) mstr_dtl_order

.PHONY: all clean rebuild employees empl_terr region territories orders order_details categories customers products shippers suppliers usstates mstr_dtl_order ggc-build ggc-test ggc-test-gui ggc-test-debug ggc-clean

