`timescale 1ns / 1ps

//------------------------------------------------------------------------
// 宏定�?
//------------------------------------------------------------------------

//------------------------------------------------------------------------
// 时钟定义
//------------------------------------------------------------------------
`define CPU_CLOCK_HZ 325_000_000 // 325MHz


//------------------------------------------------------------------------
// 指令字段定义（位域范围）
//------------------------------------------------------------------------
`define RV32_OP  6:0    // 操作码字�?(7�?)
`define RV32_RD  11:7   // 目标寄存器字�?(5�?)
`define RV32_F3  14:12  // 功能3字段(3�?)
`define RV32_RM  14:12  // 舍入模式字段(3�?)
`define RV32_RS1 19:15  // 源寄存器1字段(5�?)
`define RV32_RS2 24:20  // 源寄存器2字段(5�?)
`define RV32_F2  26:25  // 功能2字段(2�?)
`define RV32_RS3 31:27  // 源寄存器3字段(5�?)
`define RV32_F7  31:25  // 功能7字段(7�?)

//------------------------------------------------------------------------
// 字段宽度定义
//------------------------------------------------------------------------
`define RV32_OP_WIDTH   7   // 操作码位�?
`define RV32_RD_WIDTH   5   // 目标寄存器字段位�?
`define RV32_RS1_WIDTH  5   // 源寄存器1字段位数
`define RV32_RS2_WIDTH  5   // 源寄存器2字段位数
`define RV32_RS3_WIDTH  5   // 源寄存器3字段位数
`define RV32_F3_WIDTH   3   // funct3字段位数
`define RV32_RM_WIDTH   3   // 舍入模式字段位数
`define RV32_F7_WIDTH   7   // funct7字段位数
`define RV32_F2_WIDTH   2   // funct2字段位数

//------------------------------------------------------------------------
// rv32i load type inst
//------------------------------------------------------------------------
`define RV32I_OP_TYPE_IL 7'b0000011
`define RV32I_F3_LB      3'b000
`define RV32I_F3_LH      3'b001
`define RV32I_F3_LW      3'b010
`define RV32I_F3_LBU     3'b100
`define RV32I_F3_LHU     3'b101

//------------------------------------------------------------------------
// rv32i I type inst
//------------------------------------------------------------------------
`define RV32I_OP_TYPE_I 7'b0010011
`define RV32I_F3_ADDI   3'b000
`define RV32I_F3_SLLI   3'b001
`define RV32I_F3_SLTI   3'b010
`define RV32I_F3_SLTIU  3'b011
`define RV32I_F3_XORI   3'b100
`define RV32I_F3_SRI    3'b101
`define RV32I_F3_ORI    3'b110
`define RV32I_F3_ANDI   3'b111

//------------------------------------------------------------------------
// rv32i U type inst
//------------------------------------------------------------------------
`define RV32I_OP_AUIPC  7'b0010111
`define RV32I_OP_LUI    7'b0110111

//------------------------------------------------------------------------
// rv32i S type inst
//------------------------------------------------------------------------
`define RV32I_OP_TYPE_S 7'b0100011
`define RV32I_F3_SB     3'b000
`define RV32I_F3_SH     3'b001
`define RV32I_F3_SW     3'b010

// rv32i/rv32m R/M type inst
`define RV32IM_OP_TYPE_R_M 7'b0110011

`define RV32I_F3_ADD_SUB 3'b000
`define RV32I_F3_SLL    3'b001
`define RV32I_F3_SLT    3'b010
`define RV32I_F3_SLTU   3'b011
`define RV32I_F3_XOR    3'b100
`define RV32I_F3_SR     3'b101
`define RV32I_F3_OR     3'b110
`define RV32I_F3_AND    3'b111

`define RV32I_F7_R1    7'b0000000
`define RV32I_F7_R2    7'b0100000

`define RV32M_F3_MUL    3'b000
`define RV32M_F3_MULH   3'b001
`define RV32M_F3_MULHSU 3'b010
`define RV32M_F3_MULHU  3'b011
`define RV32M_F3_DIV    3'b100
`define RV32M_F3_DIVU   3'b101
`define RV32M_F3_REM    3'b110
`define RV32M_F3_REMU   3'b111

`define RV32M_F7_MUL    7'b0000001

//------------------------------------------------------------------------
// rv32m div control
//------------------------------------------------------------------------
`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0


//------------------------------------------------------------------------
// rv32i B type inst
//------------------------------------------------------------------------
`define RV32I_OP_TYPE_B 7'b1100011
`define RV32I_F3_BEQ    3'b000
`define RV32I_F3_BNE    3'b001
`define RV32I_F3_BLT    3'b100
`define RV32I_F3_BGE    3'b101
`define RV32I_F3_BLTU   3'b110
`define RV32I_F3_BGEU   3'b111

//------------------------------------------------------------------------
// rv32i J type inst
//------------------------------------------------------------------------
`define RV32I_OP_JALR   7'b1100111
`define RV32I_OP_JAL    7'b1101111

//------------------------------------------------------------------------
// rv32i Debug type inst
//------------------------------------------------------------------------
`define RV_MRET       32'h30200073
`define RV_ECALL      32'h73
`define RV_EBREAK     32'h00100073

//------------------------------------------------------------------------
// rv32zicsr CSR type inst
//------------------------------------------------------------------------
`define RV_OP_CSR    7'b1110011
`define RV_F3_CSRRW  3'b001
`define RV_F3_CSRRS  3'b010
`define RV_F3_CSRRC  3'b011
`define RV_F3_CSRRWI 3'b101
`define RV_F3_CSRRSI 3'b110
`define RV_F3_CSRRCI 3'b111


//------------------------------------------------------------------------
// 通用寄存器定�?
//------------------------------------------------------------------------
`define RegNum 32        // reg num
`define RegDataWidth 32
`define RegAddrWidth $clog2(`RegNum-1)
`define RegAddrBus `RegAddrWidth-1:0
`define RegDataBus `RegDataWidth-1:0

`define DoubleRegDataBus `RegDataWidth*2-1:0
`define HRegDataBus `RegDataWidth*2-1:`RegDataWidth
`define LRegDataBus `RegDataWidth-1:0

//------------------------------------------------------------------------
// CSR寄存器定�?
//------------------------------------------------------------------------
`define CSRAddrWidth 12
`define CSRDataWidth 32
`define DoubleCSRDataWidth 64
`define CSRAddrBus `CSRAddrWidth-1:0
`define CSRDataBus `CSRDataWidth-1:0
`define DoubleCSRDataBus `DoubleCSRDataWidth-1:0
`define CSRNum 1024

//------------------------------------------------------------------------
// 常量定义
//------------------------------------------------------------------------
`define ZeroWord 32'h0
`define ZeroReg 5'h0
`define True 1'b1
`define False 1'b0
`define Enable 1'b1
`define Disable 1'b0
`define Stop 1'b1
`define NoStop 1'b0
`define INT_ASSERT 1'b1
`define INT_DEASSERT 1'b0

//------------------------------------------------------------------------
// CSR寄存器地�?定义
//------------------------------------------------------------------------
`define CSR_Addr_FFLAGS     12'h001     // Floating-Point Accrued Exceptions
`define CSR_Addr_FRM        12'h002     // Floating-Point Dynamic Rounding Mode
`define CSR_Addr_FCSR       12'h003     // Floating-Point Control and Status Register
`define CSR_Addr_MSTATUS    12'h300     // Machine Status Register
`define CSR_Addr_MIE        12'h304     // Machine Interrupt Enable Registers
`define CSR_Addr_MTVEC      12'h305     // Machine Trap-Vector Base-Address Register
`define CSR_Addr_MSCRATCH   12'h340     // Machine Scratch Register
`define CSR_Addr_MEPC       12'h341     // Machine Exception Program Counter
`define CSR_Addr_MCAUSE     12'h342     // Machine Cause Register
`define CSR_Addr_CYCLE      12'hc00     // Lower 32 bits of Cycle counter
`define CSR_Addr_CYCLEH     12'hc80     // Upper 32 bits of Cycle counter

//------------------------------------------------------------------------
// 流水线暂停定�?
//------------------------------------------------------------------------
`define StallWidth      6
`define StallBus        `StallWidth-1:0
`define Stall_pc        0
`define Stall_if_dec    1
`define Stall_dec_ex    2
`define Stall_ex_ls     3
`define Stall_ls_wb     4
`define Stall_wb        5

//------------------------------------------------------------------------
// 流水线冲刷定�?
//------------------------------------------------------------------------
`define KillWidth      4
`define KillBus        `KillWidth-1:0
`define Kill_if_dec    0
`define Kill_dec_ex    1
`define Kill_ex_ls     2
`define Kill_ls_wb     3

//------------------------------------------------------------------------
// ALU控制定义
//------------------------------------------------------------------------
`define ALUCTL_WIDTH    5
`define ALUCTL_NOP      5'b00000
`define ALUCTL_ADD      5'b00001       // Add (signed)
`define ALUCTL_SUB      5'b00010       // Subtract (signed)
`define ALUCTL_SLL      5'b00011       // Shift Left Logical
`define ALUCTL_SLT      5'b00100       // Set on Less Than
`define ALUCTL_SLTU     5'b00101       // Set on Less Than (unsigned)
`define ALUCTL_XOR      5'b00110       // XOR
`define ALUCTL_SRL      5'b00111       // Shift Right Logical
`define ALUCTL_SRA      5'b01000       // Shift Right Arithmetic
`define ALUCTL_OR       5'b01001       // OR
`define ALUCTL_AND      5'b01010      // AND
`define ALUCTL_AUIPC    5'b01011      // add upper immediate to PC
`define ALUCTL_LUI      5'b01100      // Load Upper Immediate
`define ALUCTL_JAL      5'b01101      // Jump and Link
`define ALUCTL_JALR     5'b01110      // Jump and Link Register

`define ALUCTL_MUL      5'b10000      // Multiply
`define ALUCTL_MULH     5'b10001      // Multiply High
`define ALUCTL_MULHSU   5'b10010      // Multiply High Signed Unsigned
`define ALUCTL_MULHU    5'b10011      // Multiply High Unsigned
`define ALUCTL_DIV      5'b10100      // Divide
`define ALUCTL_DIVU     5'b10101      // Divide Unsigned
`define ALUCTL_REM      5'b10110      // Remainder
`define ALUCTL_REMU     5'b10111      // Remainder Unsigned

//------------------------------------------------------------------------
// 分支跳转控制定义
//------------------------------------------------------------------------
`define BRUCTL_WIDTH    4
`define BRUCTL_NOP      4'b0000
`define BRUCTL_JAL      4'b0001
`define BRUCTL_JALR     4'b0010
`define BRUCTL_BEQ      4'b0011
`define BRUCTL_BNE      4'b0100
`define BRUCTL_BLT      4'b0101
`define BRUCTL_BGE      4'b0110
`define BRUCTL_BLTU     4'b0111
`define BRUCTL_BGEU     4'b1000

//------------------------------------------------------------------------
// CSR控制定义
//------------------------------------------------------------------------
`define CSRCTL_WIDTH    2
`define CSRCTL_NOP      2'b00
`define CSRCTL_WRI      2'b01
`define CSRCTL_SET      2'b10
`define CSRCTL_CLR      2'b11

//------------------------------------------------------------------------
// ALU源�?�择定义
//------------------------------------------------------------------------
`define ALUSrcA_sel_width   2
`define ALUSrcA_sel_nop     2'b00
`define ALUSrcA_sel_rs1     2'b01
`define ALUSrcA_sel_pc      2'b10
`define ALUSrcA_sel_0       2'b11

//------------------------------------------------------------------------
// ALU源�?�择定义
//------------------------------------------------------------------------
`define ALUSrcB_sel_width   2
`define ALUSrcB_sel_nop     2'b00
`define ALUSrcB_sel_rs2     2'b01
`define ALUSrcB_sel_imm     2'b10
`define ALUSrcB_sel_4       2'b11

//------------------------------------------------------------------------
// AGU源�?�择定义
//------------------------------------------------------------------------
`define AGUSrc_sel_width    2
`define AGUSrc_sel_nop      2'b00
`define AGUSrc_sel_rs1      2'b01
`define AGUSrc_sel_pc       2'b10
`define AGUSrc_sel_0        2'b11

//------------------------------------------------------------------------
// CSR源�?�择定义
//------------------------------------------------------------------------
`define CSRSrc_sel_width    2
`define CSRSrc_sel_nop      2'b00
`define CSRSrc_sel_rs1      2'b01
`define CSRSrc_sel_imm      2'b10

//------------------------------------------------------------------------
// FWD源�?�择定义
//------------------------------------------------------------------------
`define FWDSrc_sel_width    2
`define FWDSrc_sel_nop      2'b00
`define FWDSrc_sel_nfw      2'b01
`define FWDSrc_sel_ls       2'b10
`define FWDSrc_sel_wb       2'b11

//------------------------------------------------------------------------
// 存储和加载差异定�?
//------------------------------------------------------------------------
`define ls_diff_width   4
`define ls_diff_bus     `ls_diff_width-1:0
`define ls_nop          4'b0000
`define ls_lb           4'b0001
`define ls_lh           4'b0011
`define ls_lw           4'b0010
`define ls_lbu          4'b0110
`define ls_lhu          4'b0111
`define ls_sb           4'b1000
`define ls_sh           4'b1001
`define ls_sw           4'b1011
`define ls_flw          4'b1100
`define ls_fsw          4'b1101

//------------------------------------------------------------------------
// 中断定义
//------------------------------------------------------------------------
`define INT_WIDTH 8
`define INT_BUS `INT_WIDTH-1:0
`define INT_NONE 8'h0
`define INT_RET 8'hff
`define INT_TIMER0 8'b00000001
`define INT_TIMER0_ENTRY_ADDR 32'h4

//------------------------------------------------------------------------
// 异常类型定义
//------------------------------------------------------------------------
`define Except_Width                3
`define Except_Bus                  `Except_Width-1:0

`define EXCPT_ECALL                 0
`define EXCPT_EBREAK                1
`define EXCPT_MRET                  2

//------------------------------------------------------------------------
// 存储器定�?
//------------------------------------------------------------------------
`define MemAddrWidth 32
`define MemDataWidth 32
`define MemDataBus `MemDataWidth-1:0
`define MemAddrBus `MemAddrWidth-1:0

`define InstWidth 32
`define InstAddrWidth 32
`define InstBus `InstWidth-1:0
`define InstAddrBus `InstAddrWidth-1:0

`define DBUS_MASK 4

`define RomAddrBase 32'h8000_0000
