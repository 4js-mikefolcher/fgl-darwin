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

# ----------------------------------------------------------------------
# fglunit unit-test targets
# ----------------------------------------------------------------------
# Build + run the fglunit test suite under hrm/fglunit-src/. The child
# Makefile takes care of FGLLDPATH, DBPATH, and FGLPROFILE so no shell
# setup is needed here.
#
# Prerequisite: the hrm model modules (model_*.42m, main_lib.42m, etc.)
# must already exist in bin/. They're produced by `make` in the hrm/ tree
# and are deliberately not rebuilt here — the unit tests only need the
# compiled .42m, not a full app re-link.
#
#   make unit-test        — compile + run every test program
#   make unit-test-build  — compile only (no run)
#   make unit-test-clean  — remove compiled test artifacts
#   make unit-test-<name> — run a single suite, e.g.
#                           make unit-test-model_categories
#                           make unit-test-model_helper
#                           make unit-test-main_lib

UNITDIR = $(HRMDIR)/fglunit-src

unit-test:
	$(MAKE) -C $(UNITDIR) test

unit-test-build:
	$(MAKE) -C $(UNITDIR)

unit-test-clean:
	$(MAKE) -C $(UNITDIR) clean

# Pattern target: forward `make unit-test-<name>` to the child's `run_<name>`
# target (e.g. unit-test-model_categories -> run_model_categories).
unit-test-%:
	$(MAKE) -C $(UNITDIR) run_$*

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

.PHONY: all clean rebuild employees empl_terr region territories orders order_details categories customers products shippers suppliers usstates mstr_dtl_order ggc-build ggc-test ggc-test-gui ggc-test-debug ggc-clean unit-test unit-test-build unit-test-clean

