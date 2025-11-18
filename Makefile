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

.PHONY: all clean rebuild employees empl_terr region territories

