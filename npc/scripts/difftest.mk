ifdef CONFIG_DIFFTEST

DIFF_REF_PATH = $(NEMU_HOME)

DIFF_REF_SO = $(DIFF_REF_PATH)/build/$(GUEST_ISA)-$(call remove_quote,$(CONFIG_DIFFTEST_REF_NAME))-$(call remove_quote,$(CONFIG_ENGINE))-so

ARGS_DIFF += --diff=$(DIFF_REF_SO)

endif