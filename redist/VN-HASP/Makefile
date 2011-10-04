#ifndef _ARCH
#  _ARCH := $(shell uname -p)
#  export _ARCH
#endif

MODULES := HASP4 HASPHL
#MODULES := HASPHL HASP4
#MODULES := HASPHL 
#ifeq ($(_ARCH), x86_64)
#ifeq ($(_ARCH), i386)
#$(warning Adding HASP4 to MODULES list)
#MODULES += HASP4
#else
#$(warning Skipping HASP4 module build: arch=$(_ARCH))
#$(warning Adding HASP4emu to MODULES list)
#MODULES += HASP4emu
#endif

all: $(MODULES) 

#define RESET
#$(1) :=
#$(1)-yes :=
#endef
#define DOSUBDIR
#$(foreach V,$(SUBDIR_VARS),$(eval $(call RESET,$(V))))
#SUBDIR := $(1)/
#include $(1)/Makefile
#endef

SUBDIR := lib/VN/HASP/
include $(SUBDIR)Makefile

install: $(MODULES)

dist: install
	if [ -z "$(LIB)" ]; then exit 1; fi 
	mkdir -p "$(LIB)"	
	cp -r $(CURDIR)/lib/auto "$(LIB)"
	mkdir -p "$(LIB)/VN/HASP"
	cp $(CURDIR)/lib/VN/HASP.pm "$(LIB)/VN/"
	cp $(CURDIR)/lib/VN/HASP/*.pm "$(LIB)/VN/HASP/"
