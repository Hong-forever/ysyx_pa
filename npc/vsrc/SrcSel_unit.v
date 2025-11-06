`include "defines.v"

//------------------------------------------------------------------------
// ALU源选择单元
//------------------------------------------------------------------------

module ALUSrcSel_unit
(
    input   wire    [`RV32_OP_WIDTH-1:0    ] opcode, 
    output  reg     [`ALUSrcA_sel_width-1:0] ALUSrcA_sel,
    output  reg     [`ALUSrcB_sel_width-1:0] ALUSrcB_sel
);

    always @(*) begin
        case(opcode)
            `RV32IM_OP_TYPE_R_M: ALUSrcA_sel = `ALUSrcA_sel_rs1;
            `RV32I_OP_TYPE_I:    ALUSrcA_sel = `ALUSrcA_sel_rs1;
            `RV32I_OP_TYPE_B:    ALUSrcA_sel = `ALUSrcA_sel_rs1;
            `RV32I_OP_JALR:      ALUSrcA_sel = `ALUSrcA_sel_pc;
            `RV32I_OP_JAL:       ALUSrcA_sel = `ALUSrcA_sel_pc;
            `RV32I_OP_AUIPC:     ALUSrcA_sel = `ALUSrcA_sel_pc;
            `RV32I_OP_LUI:       ALUSrcA_sel = `ALUSrcA_sel_0;
            default:             ALUSrcA_sel = `ALUSrcA_sel_nop;
        endcase
    end

    always @(*) begin
        case(opcode)
            `RV32IM_OP_TYPE_R_M: ALUSrcB_sel = `ALUSrcB_sel_rs2;
            `RV32I_OP_TYPE_B:    ALUSrcB_sel = `ALUSrcB_sel_rs2;
            `RV32I_OP_TYPE_I:    ALUSrcB_sel = `ALUSrcB_sel_imm;
            `RV32I_OP_AUIPC:     ALUSrcB_sel = `ALUSrcB_sel_imm;
            `RV32I_OP_LUI:       ALUSrcB_sel = `ALUSrcB_sel_imm;
            `RV32I_OP_JALR:      ALUSrcB_sel = `ALUSrcB_sel_4;
            `RV32I_OP_JAL:       ALUSrcB_sel = `ALUSrcB_sel_4;
            default:             ALUSrcB_sel = `ALUSrcB_sel_nop;
        endcase
    end

endmodule


//------------------------------------------------------------------------
// AGU源选择单元
//------------------------------------------------------------------------

module AGUSrcSel_unit   
(
    input   wire    [`RV32_OP_WIDTH-1:0    ] opcode,
    output  reg     [`AGUSrc_sel_width-1:0] AGUSrc_sel
);

    always @(*) begin
        case(opcode)
            `RV32I_OP_TYPE_IL: AGUSrc_sel = `AGUSrc_sel_rs1;
            `RV32I_OP_TYPE_S:  AGUSrc_sel = `AGUSrc_sel_rs1;
            `RV32I_OP_JALR:    AGUSrc_sel = `AGUSrc_sel_rs1;
            `RV32I_OP_TYPE_B:  AGUSrc_sel = `AGUSrc_sel_pc;
            `RV32I_OP_JAL:     AGUSrc_sel = `AGUSrc_sel_pc;
            default:           AGUSrc_sel = `AGUSrc_sel_nop;
        endcase
    end

endmodule

//------------------------------------------------------------------------
// CSR源选择单元
//------------------------------------------------------------------------

module CSRSrcSel_unit
(
    input   wire    [`RV32_OP_WIDTH-1:0    ] opcode,
    input   wire    [`RV32_F3_WIDTH-1:0    ] funct3,
    output  reg     [`CSRSrc_sel_width-1:0] CSRSrc_sel
);

    always @(*) begin
        if(opcode == `RV_OP_CSR) begin
            case(funct3)
                `RV_F3_CSRRW:  CSRSrc_sel = `CSRSrc_sel_rs1;
                `RV_F3_CSRRS:  CSRSrc_sel = `CSRSrc_sel_rs1;
                `RV_F3_CSRRC:  CSRSrc_sel = `CSRSrc_sel_rs1;
                `RV_F3_CSRRWI: CSRSrc_sel = `CSRSrc_sel_imm;
                `RV_F3_CSRRSI: CSRSrc_sel = `CSRSrc_sel_imm;
                `RV_F3_CSRRCI: CSRSrc_sel = `CSRSrc_sel_imm;
                default:       CSRSrc_sel = `CSRSrc_sel_nop;
            endcase
        end else begin
                               CSRSrc_sel = `CSRSrc_sel_nop;
        end
    end

endmodule
