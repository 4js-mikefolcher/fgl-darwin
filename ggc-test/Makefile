# Makefile for GGC test scenarios
#
# Usage:
#   make              — compile all tests
#   make run          — compile and run the search/view test
#   make clean        — remove compiled files

# Directories
BINDIR   = bin
PROJROOT = ..
APPBIN   = $(PROJROOT)/bin
APPSRC   = $(PROJROOT)/hrm/src
DBSDIR   = $(PROJROOT)/dbs

# GGC location (inside FGLDIR)
GGCDIR   = $(FGLDIR)/testing_utilities/ggc

# Compiler
MODCOMP  = fglcomp -M

# Use export to handle paths with spaces (FGLDIR contains spaces on macOS)
export FGLLDPATH := $(GGCDIR)/lib:$(APPBIN):$(FGLLDPATH)

# Environment for running the app under test (FGLRESOURCEPATH and FGLDBPATH)
export FGLRESOURCEPATH := $(APPSRC):$(FGLRESOURCEPATH)
export FGLDBPATH := $(DBSDIR):$(FGLDBPATH)

# Test sources
TEST_SOURCES = test_md_orders.4gl

# Compiled test modules
TEST_TARGETS = $(patsubst %.4gl,$(BINDIR)/%.42m,$(TEST_SOURCES))

# Default: compile all tests
all: $(BINDIR) $(TEST_TARGETS)

$(BINDIR):
	mkdir -p $(BINDIR)

# Compile rule: .4gl -> .42m
$(BINDIR)/%.42m: %.4gl
	$(MODCOMP) $<
	mv $*.42m $(BINDIR)/

# Run the search/view test (TCP direct connection)
run: all
	@echo "============================================"
	@echo " Running GGC test: test_md_orders"
	@echo " App: mstr_dtl_order"
	@echo "============================================"
	fglrun $(BINDIR)/test_md_orders.42m tcp \
		--command-line "fglrun mstr_dtl_order" \
		-w "$(APPBIN)"
	@echo "============================================"
	@echo " Test complete"
	@echo "============================================"

# Run with GUI forwarded to GDC (for watching the test)
run-gui: all
	@echo "============================================"
	@echo " Running GGC test with GUI: test_md_orders"
	@echo " (Start GDC first, then run this)"
	@echo "============================================"
	fglrun $(BINDIR)/test_md_orders.42m tcp \
		--command-line "fglrun mstr_dtl_order" \
		-w "$(APPBIN)" \
		-f localhost:0
	@echo "============================================"
	@echo " Test complete"
	@echo "============================================"

# Run with guilog on error (for debugging failures)
run-debug: all
	fglrun $(BINDIR)/test_md_orders.42m tcp \
		--command-line "fglrun mstr_dtl_order" \
		-w "$(APPBIN)" \
		--guilog-on-error \
		--guilog-directory $(BINDIR)

clean:
	rm -f $(BINDIR)/*.42m

.PHONY: all clean run run-gui run-debug
