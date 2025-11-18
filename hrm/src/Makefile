# Makefile for Genero BDL Application
# Compiles .per forms and .4gl modules

# Directories
BINDIR = ../bin

# Compilers
FORMCOMP = fglform
SRCCOMP = fgl2p

# Source files
FORMS = employees.per empl_terr.per region.per territories.per

# Compiled form targets
FORM_TARGETS = $(BINDIR)/employees.42f \
               $(BINDIR)/empl_terr.42f \
               $(BINDIR)/region.42f \
               $(BINDIR)/territories.42f

# Program targets
PROG_TARGETS = $(BINDIR)/main_employees.42r \
               $(BINDIR)/main_empl_terr.42r \
               $(BINDIR)/main_region.42r \
               $(BINDIR)/main_territories.42r

# Default target - build everything
all: $(BINDIR) $(FORM_TARGETS) $(PROG_TARGETS)

# Create bin directory if it doesn't exist
$(BINDIR):
	mkdir -p $(BINDIR)

# Form compilation rules
$(BINDIR)/employees.42f: employees.per
	$(FORMCOMP) $<
	mv employees.42f $(BINDIR)/

$(BINDIR)/empl_terr.42f: empl_terr.per
	$(FORMCOMP) $<
	mv empl_terr.42f $(BINDIR)/

$(BINDIR)/region.42f: region.per
	$(FORMCOMP) $<
	mv region.42f $(BINDIR)/

$(BINDIR)/territories.42f: territories.per
	$(FORMCOMP) $<
	mv territories.42f $(BINDIR)/

# Program compilation rules
$(BINDIR)/main_employees.42r: main_employees.4gl main_lib.4gl employees.4gl
	$(SRCCOMP) -o main_employees.42r $^
	mv main_employees.42r main_employees.42m main_lib.42m employees.42m $(BINDIR)/

$(BINDIR)/main_empl_terr.42r: main_empl_terr.4gl main_lib.4gl empl_terr.4gl territories.4gl employees.4gl region.4gl
	$(SRCCOMP) -o main_empl_terr.42r $^
	mv main_empl_terr.42r main_empl_terr.42m main_lib.42m empl_terr.42m territories.42m employees.42m region.42m $(BINDIR)/

$(BINDIR)/main_region.42r: main_region.4gl main_lib.4gl region.4gl
	$(SRCCOMP) -o main_region.42r $^
	mv main_region.42r main_region.42m main_lib.42m region.42m $(BINDIR)/

$(BINDIR)/main_territories.42r: main_territories.4gl main_lib.4gl territories.4gl region.4gl
	$(SRCCOMP) -o main_territories.42r $^
	mv main_territories.42r main_territories.42m main_lib.42m territories.42m region.42m $(BINDIR)/

# Clean compiled files
clean:
	rm -f *.42f *.42m *.42r
	rm -f $(BINDIR)/*.42f $(BINDIR)/*.42m $(BINDIR)/*.42r

# Clean and rebuild
rebuild: clean all

# Individual targets for convenience
employees: $(BINDIR)/employees.42f $(BINDIR)/main_employees.42r
empl_terr: $(BINDIR)/empl_terr.42f $(BINDIR)/main_empl_terr.42r
region: $(BINDIR)/region.42f $(BINDIR)/main_region.42r
territories: $(BINDIR)/territories.42f $(BINDIR)/main_territories.42r

.PHONY: all clean rebuild employees empl_terr region territories
