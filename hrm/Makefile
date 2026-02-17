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

orders:
	$(MAKE) -C $(SRCDIR) orders

order_details:
	$(MAKE) -C $(SRCDIR) order_details

categories:
	$(MAKE) -C $(SRCDIR) categories

customers:
	$(MAKE) -C $(SRCDIR) customers

products:
	$(MAKE) -C $(SRCDIR) products

shippers:
	$(MAKE) -C $(SRCDIR) shippers

suppliers:
	$(MAKE) -C $(SRCDIR) suppliers

usstates:
	$(MAKE) -C $(SRCDIR) usstates

ifx_menu:
	$(MAKE) -C $(SRCDIR) ifx_menu

.PHONY: all clean rebuild ifx_menu employees empl_terr region territories orders order_details categories customers products shippers suppliers usstates

