`include "defines.v"

//------------------------------------------------------------------------
// 指令解包模块
//------------------------------------------------------------------------

module RV32_Inst_Unpack
(
    input   wire    [`InstBus           ] I_inst,
    output  wire    [`RV32_OP_WIDTH-1:0 ] opcode,
    output  wire    [`RV32_F3_WIDTH-1:0 ] funct3,
    output  wire    [`RV32_F7_WIDTH-1:0 ] funct7,
    output  wire    [`RV32_RD_WIDTH-1:0 ] rd,
    output  wire    [`RV32_RS1_WIDTH-1:0] rs1,
    output  wire    [`RV32_RS2_WIDTH-1:0] rs2
);

    assign opcode = I_inst[`RV32_OP ];
    assign funct3 = I_inst[`RV32_F3 ];
    assign funct7 = I_inst[`RV32_F7 ];
    assign rd     = I_inst[`RV32_RD ];
    assign rs1    = I_inst[`RV32_RS1];
    assign rs2    = I_inst[`RV32_RS2];

endmodule
