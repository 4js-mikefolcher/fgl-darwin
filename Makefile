# Parent Makefile for Genero BDL Application
# Calls the Makefile in the source directory

# Source directory (adjust if your source dir has a different name)
HRMDIR = hrm

# Default target - build everything
all:
	$(MAKE) -C $(HRMDIR)

# Clean compiled files
clean:
	$(MAKE) -C $(HRMDIR) clean

# Clean and rebuild
rebuild:
	$(MAKE) -C $(HRMDIR) rebuild

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

.PHONY: all clean rebuild employees empl_terr region territories orders order_details categories customers products shippers suppliers usstates

