MODULES := HASP4 HASPHL

all: $(MODULES) 

define RESET
$(1) :=
$(1)-yes :=
endef

define DOSUBDIR
$(foreach V,$(SUBDIR_VARS),$(eval $(call RESET,$(V))))
SUBDIR := $(1)/
include $(1)/Makefile
endef

SUBDIR := lib/VN/HASP/
include $(SUBDIR)/Makefile

install: $(MODULES)

dist: install
	if [ -z "$(LIB)" ]; then exit 1; fi 
	mkdir -p "$(LIB)"	
	cp -r lib/auto "$(LIB)"
	mkdir -p "$(LIB)/VN/HASP"
	cp lib/VN/HASP.pm "$(LIB)/VN/"
	cp lib/VN/HASP/*.pm "$(LIB)/VN/HASP/"
