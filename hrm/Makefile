# Parent Makefile for Genero BDL Application
# Calls the Makefile in the source directory

# Source directory (adjust if your source dir has a different name)
SRCDIR = src

# Default target - build everything
all:
	$(MAKE) -C $(SRCDIR)

# Clean compiled files
clean:
	$(MAKE) -C $(SRCDIR) clean

# Clean and rebuild
rebuild:
	$(MAKE) -C $(SRCDIR) rebuild

# Individual module targets
employees:
	$(MAKE) -C $(SRCDIR) employees

empl_terr:
	$(MAKE) -C $(SRCDIR) empl_terr

region:
	$(MAKE) -C $(SRCDIR) region

territories:
	$(MAKE) -C $(SRCDIR) territories

cust_demo:
	$(MAKE) -C $(SRCDIR) cust_demo

cust_cust_demo:
	$(MAKE) -C $(SRCDIR) cust_cust_demo

.PHONY: all clean rebuild employees empl_terr region territories cust_demo cust_cust_demo

