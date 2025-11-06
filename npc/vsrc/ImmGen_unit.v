`include "defines.v"

//------------------------------------------------------------------------
// 立即数生成单元
//------------------------------------------------------------------------

module ImmGen_unit
(
    input   wire    [`InstBus       ]   I_inst,
    output  wire    [`RegDataBus    ]   O_imm
);

    wire [`RegDataBus] rv32i_i_type_imm = {{20{I_inst[31]}}, I_inst[31:20]};
    wire [`RegDataBus] rv32i_s_type_imm = {{20{I_inst[31]}}, I_inst[31:25], I_inst[11:7]};
    wire [`RegDataBus] rv32i_u_type_imm = {I_inst[31:12], 12'b0};
    wire [`RegDataBus] rv32i_b_type_imm = {{20{I_inst[31]}}, I_inst[7], I_inst[30:25], I_inst[11:8], 1'b0};
    wire [`RegDataBus] rv32i_j_type_imm = {{12{I_inst[31]}}, I_inst[19:12], I_inst[20], I_inst[30:21], 1'b0};
    wire [`RegDataBus] rv_csr_type_imm  = {27'h0, I_inst[19:15]};

    reg [`RegDataBus] imm;
    always @(*) begin
        case(I_inst[`RV32_OP])
            `RV32I_OP_TYPE_IL:  imm = rv32i_i_type_imm;
            `RV32I_OP_TYPE_I :  imm = rv32i_i_type_imm;
            `RV32I_OP_AUIPC  :  imm = rv32i_u_type_imm;
            `RV32I_OP_LUI    :  imm = rv32i_u_type_imm;
            `RV32I_OP_TYPE_S :  imm = rv32i_s_type_imm;
            `RV32I_OP_TYPE_B :  imm = rv32i_b_type_imm;
            `RV32I_OP_JALR   :  imm = rv32i_i_type_imm;
            `RV32I_OP_JAL    :  imm = rv32i_j_type_imm;
            `RV_OP_CSR       :  imm = rv_csr_type_imm;
            default:            imm = `ZeroWord;
        endcase
    end

    assign O_imm = imm;

endmodule
