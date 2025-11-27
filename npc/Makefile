
include $(NPC_HOME)/scripts/my_config.mk

use_nvbrd ?= 0

ifeq ($(use_nvbrd), 1)
NXDC_FILES = constr/top.nxdc

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

endif

TOPNAME = top

GUEST_ISA ?= riscv32
CONFIG_DIFFTEST_REF_NAME ?= "nemu-interpreter"

remove_quote = $(patsubst "%",%,$(1))


INC_PATH += $(sort $(dir $(shell find $(abspath ./csrc) -name "*.h")))

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert

VERILATOR_CFLAGS += -I./vsrc
VERILATOR_CFLAGS += -Wno-WIDTHEXPAND

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

include $(NPC_HOME)/scripts/difftest.mk

NPC_EXEC := $(BIN) $(IMG)
ARGS += $(ARGS_DIFF)

sim: $(NPC_EXEC)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	LD_PRELOAD=$(shell gcc -print-file-name=libasan.so) $(BIN) $(ARGS) $(IMG)

$(shell mkdir -p $(BUILD_DIR))

ifeq ($(use_nvbrd), 1)
# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@
endif

FILELIST_MK = $(shell find -L . -name "filelist.mk")
include $(FILELIST_MK)

# project source
VSRCS-y ?= $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS-y ?= $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

ifeq ($(use_nvbrd), )
CSRCS-BLACKLIST-y += $(SRC_AUTO_BIND)
endif

VSRCS-BLACKLIST-y += $(VSRCS-BLACKLIST)
CSRCS-BLACKLIST-y += $(CSRCS-BLACKLIST)
VSRCS := $(filter-out $(VSRCS-BLACKLIST-y),$(VSRCS-y))
CSRCS := $(filter-out $(CSRCS-BLACKLIST-y),$(CSRCS-y))

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))

CXXFLAGS += $(INCFLAGS) 
CXXFLAGS += -g -O2 
CXXFLAGS += -DTOP_NAME="V$(TOPNAME)" 

# CXXFLAGS += -fpermissive

ifeq ($(use_nvbrd), 1)
CXXFLAGS += -DCONFIG_USE_NVBOARD=1
endif

LDFLAGS += -lreadline -ldl -lm -lstdc++ -lpthread

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: run
run: sim


clean:
	rm -rf $(BUILD_DIR) core.*
	
include ../Makefile

.PHONY: sim all clean run
