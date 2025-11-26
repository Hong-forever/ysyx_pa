
ifeq ($(CONFIG_ITRACE),)
CSRCS-BLACKLIST-y += csrc/utils/disasm.c
else
LIBCAPSTONE = $(NEMU_HOME)/tools/capstone/repo/libcapstone.so.5
CFLAGS += -I$(NEMU_HOME)/tools/capstone/repo/include
src/utils/disasm.c: $(LIBCAPSTONE)
$(LIBCAPSTONE):
	$(MAKE) -C $(NEMU_HOME)/tools/capstone
endif
