`include "defines.v"

//------------------------------------------------------------------------
// 执行分支跳转模块
//------------------------------------------------------------------------

module exe_bru
(
    input   wire    [`RegDataBus    ]   I_alu_srca,
    input   wire    [`RegDataBus    ]   I_alu_srcb,
    input   wire    [`BRUCTL_WIDTH-1:0] I_bru_ctrl,
    
    output  wire                        O_bru_taken
);
    reg bru_taken;

    wire alu_equal = I_alu_srca == I_alu_srcb;
    wire alu_less = $signed(I_alu_srca) < $signed(I_alu_srcb);
    wire alu_lessu = I_alu_srca < I_alu_srcb;

    always @(*) begin
        case(I_bru_ctrl)
            `BRUCTL_JAL:  bru_taken = `Enable;
            `BRUCTL_JALR: bru_taken = `Enable;
            `BRUCTL_BEQ:  bru_taken = alu_equal;
            `BRUCTL_BNE:  bru_taken = ~alu_equal;
            `BRUCTL_BLT:  bru_taken = alu_less;
            `BRUCTL_BLTU: bru_taken = alu_lessu;
            `BRUCTL_BGE:  bru_taken = ~alu_less;
            `BRUCTL_BGEU: bru_taken = ~alu_lessu;
            default:      bru_taken = `Disable;
        endcase
    end

    assign O_bru_taken = bru_taken;


endmodule
