
use_nvbrd ?= 1

ifeq ($(use_nvbrd), 1)
NXDC_FILES = constr/top.nxdc

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

endif

TOPNAME = top

INC_PATH += $(sort $(dir $(shell find $(abspath ./csrc) -name "*.h")))

VERILATOR = verilator
VERILATOR_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert

VERILATOR_CFLAGS += -I./vsrc
VERILATOR_CFLAGS += -Wno-WIDTHEXPAND

BUILD_DIR = ./build
OBJ_DIR = $(BUILD_DIR)/obj_dir
BIN = $(BUILD_DIR)/$(TOPNAME)

NPC_EXEC := $(BIN) $(ARGS) $(IMG)

sim: $(NPC_EXEC)
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@$^

$(shell mkdir -p $(BUILD_DIR))

ifeq ($(use_nvbrd), 1)
# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@
endif

# project source
VSRCS ?= $(shell find $(abspath ./vsrc) -name "*.v")
CSRCS ?= $(shell find $(abspath ./csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

ifeq ($(use_nvbrd), 1)
CSRCS += $(SRC_AUTO_BIND)
endif

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))

CXXFLAGS += $(INCFLAGS) 
CXXFLAGS += -g
CXXFLAGS += -DTOP_NAME="V$(TOPNAME)" 

ifeq ($(use_nvbrd), 1)
CXXFLAGS += -DCONFIG_USE_NVBOARD=1
endif

LDFLAGS += -lreadline

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(VERILATOR) $(VERILATOR_CFLAGS) \
		--top-module $(TOPNAME) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

all: run
run: sim


clean:
	rm -rf $(BUILD_DIR)
	
include ../Makefile

.PHONY: sim all clean run
