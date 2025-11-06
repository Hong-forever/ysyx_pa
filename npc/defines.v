`define CPU_CLOCK_HZ         50_00_0000                       // CPU时钟(50MHZ)
`define JTAG_RESET_FF_LEVELS 5

`define ZeroWord 32'h0
`define ZeroReg 5'h00
`define True 1'b1
`define False 1'b0
`define Enable 1'b1
`define Disable 1'b0
`define Stop 1'b1
`define NoStop 1'b0
`define INT_ASSERT 1'b1
`define INT_DEASSERT 1'b0


`define INT_BUS 7:0
`define INT_WIDTH 8
`define INT_NONE 8'h0
`define INT_RET 8'hff
`define INT_TIMER0 8'b00000001
`define INT_TIMER0_ENTRY_ADDR 32'h4


`define RomDepth 4096  //memory depth(how many words)
`define RamDepth 4096  //memory depth(how many words)
`define MemBus 31:0
`define MemAddrBus 31:0
`define ByteWidth 7:0

`define InstBus 31:0
`define InstAddrBus 31:0
`define InstWidth 32
`define InstAddrWidth 32
`define ByteSel 4

//super scalar  //取四条指令
`define SuperAddrBus    31:0  
`define SuperAddrWidth  32 

`define SuperDataBus    `InstWidth*2-1:0
`define SuperDataWidth  `InstWidth*2
`define Inst1Bus 31:0
`define Inst2Bus 63:32

//common regs
`define RegAddrBus 4:0
`define RegBus 31:0
`define DoubleRegBus 63:0
`define RegWidth 32
`define RegNum 32        //reg num

//stall
`define StallBus        5:0
`define StallWidth      6
`define Stall_pc        0
`define Stall_if_dec    1
`define Stall_dec_ex    2
`define Stall_ex_ls     3
`define Stall_ls_wb     4
`define Stall_wb        5

//alu
`define ALUCTL_WIDTH    4
`define ALUCTL_NOP      4'd0
`define ALUCTL_ADD      4'd1       // Add (signed)
`define ALUCTL_SUB      4'd2       // Subtract (signed)
`define ALUCTL_SLL      4'd3       // Shift Left Logical
`define ALUCTL_SLT      4'd4       // Set on Less Than
`define ALUCTL_SLTU     4'd5       // Set on Less Than (unsigned)
`define ALUCTL_XOR      4'd6       // XOR
`define ALUCTL_SRL      4'd7       // Shift Right Logical
`define ALUCTL_SRA      4'd8       // Shift Right Arithmetic
`define ALUCTL_OR       4'd9       // OR
`define ALUCTL_AND      4'd10      // AND
`define ALUCTL_AUIPC    4'd11      // add upper immediate to PC
`define ALUCTL_LUI      4'd12      // Load Upper Immediate
`define ALUCTL_JAL      4'd13      // jump and link
`define ALUCTL_JALR     4'd14      // jump and link register

`define CSRCRL_WIDTH    2
`define CSRCTL_NOP      2'b00
`define CSRCTL_WRI      2'b01
`define CSRCTL_SET      2'b10
`define CSRCTL_CLR      2'b11

//store and load differ
`define ls_diff_bus 3:0
`define ls_diff_width 4
`define ls_nop 4'b0000
`define ls_lb  4'b0001
`define ls_lh  4'b0011
`define ls_lw  4'b0010
`define ls_lbu 4'b0110
`define ls_lhu 4'b0111
`define ls_sb  4'b1000
`define ls_sh  4'b1001
`define ls_sw  4'b1011

//inst differ bus
`define INST_OP_BUS     6:0
`define INST_F3_BUS     2:0
`define INST_F7_BUS     6:0

//I_L type inst
`define RV32I_OP_TYPE_IL 7'b0000011

`define RV32I_F3_LB     3'b000
`define RV32I_F3_LH     3'b001
`define RV32I_F3_LW     3'b010
`define RV32I_F3_LBU    3'b100
`define RV32I_F3_LHU    3'b101

//I type inst
`define RV32I_OP_TYPE_I 7'b0010011

`define RV32I_F3_ADDI   3'b000
`define RV32I_F3_SLLI   3'b001
`define RV32I_F3_SLTI   3'b010
`define RV32I_F3_SLTIU  3'b011
`define RV32I_F3_XORI   3'b100
`define RV32I_F3_SRI    3'b101
`define RV32I_F3_ORI    3'b110
`define RV32I_F3_ANDI   3'b111

`define RV32I_F7_SRLI   7'b0000000
`define RV32I_F7_SRAI   7'b0100000


//U type inst
`define RV32I_OP_AUIPC  7'b0010111
`define RV32I_OP_LUI    7'b0110111

//S type inst
`define RV32I_OP_TYPE_S 7'b0100011

`define RV32I_F3_SB     3'b000
`define RV32I_F3_SH     3'b001
`define RV32I_F3_SW     3'b010

//R type inst
`define RV32I_OP_TYPE_R 7'b0110011

`define RV32I_F3_ADD_SUB 3'b000
`define RV32I_F3_SLL    3'b001
`define RV32I_F3_SLT    3'b010
`define RV32I_F3_SLTU   3'b011
`define RV32I_F3_XOR    3'b100
`define RV32I_F3_SR     3'b101
`define RV32I_F3_OR     3'b110
`define RV32I_F3_AND    3'b111

`define RV32I_F7_ADD    7'b0000000
`define RV32I_F7_SUB    7'b0100000
`define RV32I_F7_SRL    7'b0000000
`define RV32I_F7_SRA    7'b0100000

//B type inst
`define RV32I_OP_TYPE_B 7'b1100011
`define RV32I_F3_BEQ    3'b000
`define RV32I_F3_BNE    3'b001
`define RV32I_F3_BLT    3'b100
`define RV32I_F3_BGE    3'b101
`define RV32I_F3_BLTU   3'b110
`define RV32I_F3_BGEU   3'b111

//J type inst
`define RV32I_OP_JALR   7'b1100111
`define RV32I_OP_JAL    7'b1101111

//
`define RV_MRET       32'h30200073
`define RV_ECALL      32'h73
`define RV_EBREAK     32'h00100073

//CSR inst

`define RV_OP_CSR    7'b1110011
`define RV_F3_CSRRW  3'b001
`define RV_F3_CSRRS  3'b010
`define RV_F3_CSRRC  3'b011
`define RV_F3_CSRRWI 3'b101
`define RV_F3_CSRRSI 3'b110
`define RV_F3_CSRRCI 3'b111

//CSR reg addr
`define CSR_Addr_MSTATUS    12'h300     //Machine Status Register
`define CSR_Addr_MIE        12'h304     //Machine Interrupt Enable Registers    
`define CSR_Addr_MTVEC      12'h305     //Machine Trap-Vector Base-Address Register
`define CSR_Addr_MSCRATCH   12'h340     //Machine Scratch Register
`define CSR_Addr_MEPC       12'h341     //Machine Exception Program Counter
`define CSR_Addr_MCAUSE     12'h342     //Machine Cause Register
`define CSR_Addr_CYCLE      12'hb00     //Lower 32 bits of Cycle counter
`define CSR_Addr_CYCLEH     12'hb80     //Upper 32 bits of Cycle counter
`define CSR_Addr_MTIMERCMP              //timer counter compare

//peripheral base addr
`define RomAddrBase     `InstWidth'h0000_0000
`define RamAddrBase     `InstWidth'h1000_0000
`define TimerAddrBase   `InstWidth'h2000_0000
`define UartAddrBase    `InstWidth'h3000_0000
`define GpioAddrBase    `InstWidth'h4000_0000
