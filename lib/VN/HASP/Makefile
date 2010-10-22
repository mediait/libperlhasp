MODULES := HASP4 HASPHL
all: $(MODULES)

define MAKE_PERLXS
$(1): $(SUBDIR)$(1)/blib/arch/auto/VN/HASP/$(1)/$(1).so
$(SUBDIR)$(1)/blib/arch/auto/VN/HASP/$(1)/$(1).so:
	cd $(SUBDIR)$(1) && perl Makefile.PL INSTALL_BASE=./build && make && make install
endef

$(foreach D,$(MODULES),$(eval $(call MAKE_PERLXS,$(D))))

INSTALL-MODULES := 
$(foreach D,$(MODULES),$(eval INSTALL-MODULES += install-$(D)))
install: $(INSTALL-MODULES)

BINDIR := $(SUBDIR)../../auto/
LIBDIR := $(SUBDIR)../../
INSTALL := install
define INSTALL_PERLXS
install-$(1):
	mkdir -p "$(BINDIR)VN/HASP/$(1)/"
	$(INSTALL) -m 644 $(SUBDIR)$(1)/build/lib/perl5/*/auto/VN/HASP/$(1)/.[^.]* $(BINDIR)VN/HASP/$(1)/
	$(INSTALL) -m 644 $(SUBDIR)$(1)/build/lib/perl5/*/auto/VN/HASP/$(1)/* $(BINDIR)VN/HASP/$(1)/
	$(INSTALL) -m 755 $(SUBDIR)$(1)/build/lib/perl5/*/auto/VN/HASP/$(1)/*.so $(BINDIR)VN/HASP/$(1)/
	$(INSTALL) -m 644 $(SUBDIR)$(1)/build/lib/perl5/*/VN/HASP/$(1).pm $(LIBDIR)VN/HASP/
endef

$(foreach D,$(MODULES),$(eval $(call INSTALL_PERLXS,$(D))))

CLEAN-MODULES := 
$(foreach D,$(MODULES),$(eval CLEAN-MODULES += clean-$(D)))
clean: $(CLEAN-MODULES)

define CLEAN_PERLXS
clean-$(1):
	cd $(SUBDIR)$(1) && test ! -e Makefile || make clean 
	if [ -d $(SUBDIR)$(1)/build ]; then rm -rf $(SUBDIR)$(1)/build; fi
	if [ -e $(SUBDIR)$(1)/Makefile.old ]; then rm $(SUBDIR)$(1)/Makefile.old; fi
endef
$(foreach D,$(MODULES),$(eval $(call CLEAN_PERLXS,$(D))))


