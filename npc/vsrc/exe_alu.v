`include "defines.v"

//------------------------------------------------------------------------
// 执行ALU模块
//------------------------------------------------------------------------

module exe_alu
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`RegDataBus    ]   I_alu_srca,
    input   wire    [`RegDataBus    ]   I_alu_srcb,
    input   wire    [`ALUCTL_WIDTH-1:0] I_alu_ctrl,
    output  wire    [`RegDataBus    ]   O_alu_result,

    input   wire                        I_mul_start,        // 开始乘法
    output  wire                        O_mul_ready,        // 乘法运算是否结束

    input   wire                        I_signed_div,       // 是否是有符号除法
    input   wire                        I_div_start,            // 开始除法
    input   wire                        I_annul,            // 是否取消
    output  wire                        O_div_ready         // 除法运算是否结束

);
    localparam MUL_CYCLE = 3'd6;

    wire div_ready;
    wire mul_ready;

    wire [`RegDataBus] rv32i_add_res   = I_alu_srca + I_alu_srcb;
    wire [`RegDataBus] rv32i_sub_res   = I_alu_srca - I_alu_srcb;
    wire [`RegDataBus] rv32i_sll_res   = I_alu_srca << I_alu_srcb[4:0];
    wire [`RegDataBus] rv32i_slt_res   = ($signed(I_alu_srca) < $signed(I_alu_srcb));       //有符号数比较
    wire [`RegDataBus] rv32i_sltu_res  = (I_alu_srca < I_alu_srcb);        // 无符号数比较
    wire [`RegDataBus] rv32i_xor_res   = I_alu_srca ^ I_alu_srcb;
    wire [`RegDataBus] rv32i_srl_res   = I_alu_srca >> I_alu_srcb[4:0];
    wire [`RegDataBus] rv32i_sra_res   = ($signed(I_alu_srca)) >>> I_alu_srcb[4:0];
    wire [`RegDataBus] rv32i_or_res    = I_alu_srca | I_alu_srcb;
    wire [`RegDataBus] rv32i_and_res   = I_alu_srca & I_alu_srcb;
    wire [`RegDataBus] rv32i_lui_res   = I_alu_srcb;
    wire [`RegDataBus] rv32i_auipc_res = I_alu_srcb + I_alu_srca;

    wire [`DoubleRegDataBus] mul_res;
    wire [`DoubleRegDataBus] mulh_res;
    wire [`DoubleRegDataBus] mulhsu_res;

    wire [`RegDataBus] rv32m_mul_res;
    wire [`RegDataBus] rv32m_mulhu_res;
    wire [`RegDataBus] rv32m_mulh_res;
    wire [`RegDataBus] rv32m_mulhsu_res;



    wire [`DoubleRegDataBus] div_res;
    wire [`RegDataBus] rv32m_rem_res  = div_res[`HRegDataBus];
    wire [`RegDataBus] rv32m_remu_res = div_res[`HRegDataBus];
    wire [`RegDataBus] rv32m_div_res  = div_res[`LRegDataBus];
    wire [`RegDataBus] rv32m_divu_res = div_res[`LRegDataBus];

    reg [`RegDataBus] res; 
    always @(*) begin
        case(I_alu_ctrl)
            `ALUCTL_ADD:    res = rv32i_add_res;
            `ALUCTL_SUB:    res = rv32i_sub_res;
            `ALUCTL_JAL:    res = rv32i_add_res;
            `ALUCTL_JALR:   res = rv32i_add_res;
            `ALUCTL_SLL:    res = rv32i_sll_res;
            `ALUCTL_SLT:    res = rv32i_slt_res;
            `ALUCTL_SLTU:   res = rv32i_sltu_res;
            `ALUCTL_XOR:    res = rv32i_xor_res;
            `ALUCTL_SRL:    res = rv32i_srl_res;
            `ALUCTL_SRA:    res = rv32i_sra_res;
            `ALUCTL_OR:     res = rv32i_or_res;
            `ALUCTL_AND:    res = rv32i_and_res;
            `ALUCTL_LUI:    res = rv32i_lui_res;
            `ALUCTL_AUIPC:  res = rv32i_auipc_res;
            `ALUCTL_MUL:    res = rv32m_mul_res;
            `ALUCTL_MULH:   res = rv32m_mulh_res;
            `ALUCTL_MULHSU: res = rv32m_mulhsu_res;
            `ALUCTL_MULHU:  res = rv32m_mulhu_res;
            `ALUCTL_DIV:    res = rv32m_div_res;
            `ALUCTL_DIVU:   res = rv32m_divu_res;
            `ALUCTL_REM:    res = rv32m_rem_res;
            `ALUCTL_REMU:   res = rv32m_remu_res;
            default:        res = `ZeroWord;
        endcase
    end

    wire [`DoubleRegDataBus] mulhsu_res_inverted = ~mulhsu_res + 1;

    wire [`RegDataBus] mulhsu_op1 = (I_alu_srca[`RegDataWidth-1])? ~I_alu_srca + 1 : I_alu_srca;
    wire [`RegDataBus] mulhsu_op2 = I_alu_srcb;

    assign rv32m_mul_res    = mul_res[`LRegDataBus];
    assign rv32m_mulhu_res  = mul_res[`HRegDataBus];
    assign rv32m_mulh_res   = mulh_res[`HRegDataBus];
    assign rv32m_mulhsu_res = (I_alu_srca[`RegDataWidth-1])? mulhsu_res_inverted[`HRegDataBus] : mulhsu_res[`HRegDataBus];

    Booth_mul 
    #(
        .LENGTH                 (`RegDataWidth              ),
        .UNSINGED_BOOTH         (1'b1                       )
    ) mul_inst (
        .clk                    (clk                        ),
        .rst                    (rst                        ),
        .A                      (I_alu_srca                 ),
        .B                      (I_alu_srcb                 ),
        .P                      (mul_res                    ),
        .start                  (I_mul_start                ),
        .done                   (mul_ready                  )
    );

    Booth_mul 
    #(
        .LENGTH                 (`RegDataWidth              ),
        .UNSINGED_BOOTH         (1'b0                       )
    ) mulh_inst (
        .clk                    (clk                        ),
        .rst                    (rst                        ),
        .A                      (I_alu_srca                 ),
        .B                      (I_alu_srcb                 ),
        .P                      (mulh_res                   ),
        .start                  (I_mul_start                ),
        .done                   (                           )
    );

    Booth_mul 
    #(
        .LENGTH                 (`RegDataWidth              ),
        .UNSINGED_BOOTH         (1'b1                       )
    ) mulhsu_inst (
        .clk                    (clk                        ),
        .rst                    (rst                        ),
        .A                      (mulhsu_op1                 ),
        .B                      (mulhsu_op2                 ),
        .P                      (mulhsu_res                 ),
        .start                  (I_mul_start                ),
        .done                   (                           )
    );

    exe_div div_inst    // 除法类型，00:除法，01:无符号除法，10:取余，11:无符号取余
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),
        .I_signed_div           (I_signed_div               ),
        .I_op_div               (I_alu_ctrl[1:0]            ),
        .I_opdata1              (I_alu_srca                 ),
        .I_opdata2              (I_alu_srcb                 ),
        .I_start                (I_div_start                ),
        .I_annul                (I_annul                    ),
        .O_result               (div_res                    ),
        .O_ready                (div_ready                  )
    );

    assign O_alu_result = res;
    assign O_div_ready = div_ready;
    assign O_mul_ready = mul_ready;
    
endmodule
    


