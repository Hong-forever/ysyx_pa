TOPNAME = top

VERILATOR = verilator

BUILD_DIR = ./build

OBJ_DIR = $(BUILD_DIR)/obj_dir

BIN = $(OBJ_DIR)/$(TOPNAME)



#创建生成文件的目录,存放生成的文件
VERILATOR_FLAGS += --Mdir $(OBJ_DIR)

#优化分配 
VERILATOR_FLAGS += -x-assign fast

#将所有warning 变成error
VERILATOR_FLAGS += -Wall


#Make waveforms,fst格式
VERILATOR_FLAGS += --trace-fst
WAVE = wave.fst


#检查SystemVerilog断言
VERILATOR_FLAGS += --assert

#debug模式，生成更多调试信息
#VERILATOR_FLAGS += --debug

#Add this trace to get a backtrace in gdb
#VERILATOR_FLAGS += --gdbbt

# 可用gdb调试
#VERILATOR_FLAGS += --gdb

#加速编译
VERILATOR_FLAGS += -j

#调用工具链来构建库，不加则由verilator自己构建
VERILATOR_FLAGS += --build

#指定顶层文件
VERILATOR_FLAGS += --top-module $(TOPNAME)

#生成C++可执行文件，并指定文件名字
VERILATOR_FLAGS += --cc --exe -o $(abspath $(BIN))

#VSRCS = $(wildcard vsrc/*.v vsrc/*.sv)
#CSRCS = $(wildcard csrc/*.c csrc/*.cpp csrc/*.h)
VSRCS = $(abspath $(wildcard ./vsrc/*.v ./vsrc/*.sv))
CSRCS = $(abspath $(wildcard ./csrc/*.c ./csrc/*.cpp))


run:
	@echo "-------- VERILATE --- AND --- BUILD --------"
	@rm -rf $(OBJ_DIR)
	@mkdir -p $(OBJ_DIR)
	
	@$(VERILATOR) $(VERILATOR_FLAGS) $(VSRCS) $(CSRCS)
	
	@echo
	@echo "-------------------- RUN --------------------"
	@rm -rf $(BUILD_DIR)/logs
	@mkdir -p $(BUILD_DIR)/logs
	@$(BIN)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@echo "\n-------------------- SIM --------------------"
	@rm -rf $(BUILD_DIR)/logs
	@mkdir -p $(BUILD_DIR)/logs
	@$(BIN) +trace
	gtkwave $(BUILD_DIR)/$(WAVE)
	
gdb:
	@echo "-------- VERILATE --- AND --- BUILD --------"
	@rm -rf $(OBJ_DIR)
	@mkdir -p $(OBJ_DIR)
	
	@$(VERILATOR) $(VERILATOR_FLAGS) $(VSRCS) $(CSRCS)
	
	@echo "-------------------- GDB --------------------"
	@rm -rf $(BUILD_DIR)/logs
	@mkdir -p $(BUILD_DIR)/logs
	gdb -s $(BIN) --args $(BIN)

clean:
	rm -rf $(BUILD_DIR)

include ../Makefile
