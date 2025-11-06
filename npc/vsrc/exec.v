`include "defines.v"

//------------------------------------------------------------------------
// 执行模块
//------------------------------------------------------------------------

module exec
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`InstBus       ]   I_inst,
    input   wire    [`InstAddrBus   ]   I_inst_addr,

    input   wire                        I_rd_we,
    input   wire    [`RegAddrBus    ]   I_rd_waddr,
    input   wire    [`RegDataBus    ]   I_imm,
    input   wire                        I_csr_we,
    input   wire    [`CSRAddrBus    ]   I_csr_waddr,
    input   wire    [`CSRCTL_WIDTH-1:0] I_CSRCtrl,
    input   wire    [`ALUCTL_WIDTH-1:0] I_ALUCtrl,
    input   wire    [`BRUCTL_WIDTH-1:0] I_BRUCtrl,
    input   wire    [`FWDSrc_sel_width-1:0] I_FWDCtrl_rs1,
    input   wire    [`FWDSrc_sel_width-1:0] I_FWDCtrl_rs2,
    input   wire    [`FWDSrc_sel_width-1:0] I_FWDCtrl_csr,
    input   wire    [`ALUSrcA_sel_width-1:0] I_ALUSrcA_sel,
    input   wire    [`ALUSrcB_sel_width-1:0] I_ALUSrcB_sel,
    input   wire    [`AGUSrc_sel_width-1:0]  I_AGUSrc_sel,
    input   wire    [`CSRSrc_sel_width-1:0]  I_CSRSrc_sel,
    input   wire                        I_ls_valid,         //访存有效标志
    input   wire    [`ls_diff_bus   ]   I_ls_type,

    input   wire    [`RegDataBus]       I_rs1_rdata,
    input   wire    [`RegDataBus]       I_rs2_rdata,
    input   wire    [`CSRDataBus]       I_csr_rdata,

    input   wire    [`RegDataBus]       I_ls_rd_wdata,
    input   wire    [`RegDataBus]       I_wb_rd_wdata,

    input   wire    [`CSRDataBus]       I_ls_csr_wdata,
    input   wire    [`CSRDataBus]       I_wb_csr_wdata,

    input   wire                        I_csr_re,           //判断结果是否来自csr
    input   wire    [`Except_Bus    ]   I_except,           //异常

    output  wire    [`InstBus       ]   O_inst,
    output  wire    [`InstAddrBus   ]   O_inst_addr,
    output  wire                        O_rd_we,
    output  wire    [`RegAddrBus    ]   O_rd_waddr,
    output  wire    [`RegDataBus    ]   O_rd_wdata,
    output  wire    [`MemAddrBus    ]   O_memory_addr,
    output  wire    [`MemDataBus    ]   O_store_data,
    output  wire                        O_ls_valid,         //访存有效标志
    output  wire    [`ls_diff_bus   ]   O_ls_type,

    output  wire                        O_csr_we,
    output  wire    [`CSRAddrBus    ]   O_csr_waddr,
    output  wire    [`CSRDataBus    ]   O_csr_wdata,
    output  wire    [`Except_Bus    ]   O_except,

    //bru
    output  wire                        O_bru_taken,
    output  wire    [`InstAddrBus   ]   O_bru_target,

    output  wire                        O_stallreq

);

    //------------------------------------------------------------------------
    // fwd选择
    //------------------------------------------------------------------------
    reg [`RegDataBus] final_rs1_rdata;
    reg [`RegDataBus] final_rs2_rdata;
    reg [`RegDataBus] final_agu_src;
    reg [`CSRDataBus] final_csr_rdata;

    always @(*) begin
        case(I_FWDCtrl_rs1)
            `FWDSrc_sel_nfw     :   final_rs1_rdata = I_rs1_rdata;
            `FWDSrc_sel_ls      :   final_rs1_rdata = I_ls_rd_wdata;
            `FWDSrc_sel_wb      :   final_rs1_rdata = I_wb_rd_wdata;
            default             :   final_rs1_rdata = `ZeroWord;
        endcase
    end

    always @(*) begin
        case(I_FWDCtrl_rs2)
            `FWDSrc_sel_nfw     :   final_rs2_rdata = I_rs2_rdata;
            `FWDSrc_sel_ls      :   final_rs2_rdata = I_ls_rd_wdata;
            `FWDSrc_sel_wb      :   final_rs2_rdata = I_wb_rd_wdata;
            default             :   final_rs2_rdata = `ZeroWord;
        endcase
    end

    always @(*) begin
        case(I_FWDCtrl_csr)
            `FWDSrc_sel_nfw     :   final_csr_rdata = I_csr_rdata;
            `FWDSrc_sel_ls      :   final_csr_rdata = I_ls_csr_wdata;
            `FWDSrc_sel_wb      :   final_csr_rdata = I_wb_csr_wdata;
            default             :   final_csr_rdata = `ZeroWord;
        endcase
    end

    always @(*) begin
        case(I_FWDCtrl_rs1)
            `FWDSrc_sel_nfw     :   final_agu_src = I_rs1_rdata;
            `FWDSrc_sel_ls      :   final_agu_src = I_ls_rd_wdata;
            `FWDSrc_sel_wb      :   final_agu_src = I_wb_rd_wdata;
            default             :   final_agu_src = `ZeroWord;
        endcase
    end

    //------------------------------------------------------------------------
    // src选择
    //------------------------------------------------------------------------
    reg [`RegDataBus] alu_srca;
    reg [`RegDataBus] alu_srcb;
    reg [`RegDataBus] agu_src;
    reg [`CSRDataBus] csr_src;

    always @(*) begin
        case(I_ALUSrcA_sel)
            `ALUSrcA_sel_rs1: alu_srca = final_rs1_rdata;
            `ALUSrcA_sel_pc:  alu_srca = I_inst_addr;
            default:          alu_srca = `ZeroWord;
        endcase
    end

    always @(*) begin
        case(I_ALUSrcB_sel)
            `ALUSrcB_sel_rs2: alu_srcb = final_rs2_rdata;
            `ALUSrcB_sel_imm: alu_srcb = I_imm;
            `ALUSrcB_sel_4:   alu_srcb = 4;
            default:          alu_srcb = `ZeroWord;
        endcase
    end

    always @(*) begin
        case(I_AGUSrc_sel)
            `AGUSrc_sel_rs1: agu_src = final_agu_src;
            `AGUSrc_sel_pc:  agu_src = I_inst_addr;
            default:         agu_src = `ZeroWord;
        endcase
    end

    always @(*) begin
        case(I_CSRSrc_sel)
            `CSRSrc_sel_rs1: csr_src = final_rs1_rdata;
            `CSRSrc_sel_imm: csr_src = I_imm;
            `CSRSrc_sel_nop: csr_src = `ZeroWord;
            default        : csr_src = `ZeroWord;
        endcase
    end

    //------------------------------------------------------------------------
    // alu运算
    //------------------------------------------------------------------------
    wire [`RegDataBus] alu_result;

    wire mul_ready;
    wire start_mul = I_ALUCtrl[`ALUCTL_WIDTH-1] & ~I_ALUCtrl[`ALUCTL_WIDTH-3] & ~mul_ready;
    wire stallreq_mul = start_mul;

    reg start_mul_reg;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            start_mul_reg <= 0;
        end else begin
            start_mul_reg <= start_mul;
        end
    end

    wire mul_start_one_cycle = start_mul & ~start_mul_reg;

    wire div_ready;
    wire signed_div = (I_ALUCtrl == `ALUCTL_DIV) | (I_ALUCtrl == `ALUCTL_REM);
    wire start_div = I_ALUCtrl[`ALUCTL_WIDTH-1] & I_ALUCtrl[`ALUCTL_WIDTH-3] & ~div_ready;
    wire stallreq_div = start_div;
    wire annul_div = 0;

    exe_alu alu
    (
        .clk                        (clk                    ),
        .rst                        (rst                    ),
        .I_alu_srca                 (alu_srca               ),
        .I_alu_srcb                 (alu_srcb               ),
        .I_alu_ctrl                 (I_ALUCtrl              ),
        .O_alu_result               (alu_result             ),
        .I_mul_start                (mul_start_one_cycle    ),
        .O_mul_ready                (mul_ready              ),

        .I_signed_div               (signed_div             ),
        .I_div_start                (start_div              ),
        .I_annul                    (annul_div              ),
        .O_div_ready                (div_ready              )
    );

    //------------------------------------------------------------------------
    // agu运算
    //------------------------------------------------------------------------

    wire [`RegDataBus] agu_result;
    assign agu_result = agu_src + I_imm;

    //------------------------------------------------------------------------
    // bru运算
    //------------------------------------------------------------------------
    wire bru_taken;
    exe_bru bru
    (
        .I_alu_srca                 (alu_srca               ),
        .I_alu_srcb                 (alu_srcb               ),
        .I_bru_ctrl                 (I_BRUCtrl              ),
        .O_bru_taken                (bru_taken              )
    );

    //------------------------------------------------------------------------
    // csr运算
    //------------------------------------------------------------------------
    wire [`CSRDataBus] csr_wdata;
    exe_csr csr
    (
        .I_csr_src                  (csr_src                ),
        .I_csr_rdata                (final_csr_rdata        ),
        .I_csr_ctrl                 (I_CSRCtrl              ),
        .O_csr_wdata                (csr_wdata              )
    );

    //------------------------------------------------------------------------
    // 输出
    //------------------------------------------------------------------------
    assign O_inst = I_inst;
    assign O_inst_addr = I_inst_addr;

    assign O_rd_we = I_rd_we;
    assign O_rd_waddr = I_rd_waddr;
    assign O_rd_wdata = I_csr_re? final_csr_rdata : alu_result;
    assign O_memory_addr = agu_result;
    assign O_store_data = final_rs2_rdata;

    assign O_ls_valid = I_ls_valid;
    assign O_ls_type = I_ls_type;

    assign O_csr_we = I_csr_we;
    assign O_csr_waddr = I_csr_waddr;
    assign O_csr_wdata = csr_wdata;

    assign O_bru_taken = bru_taken;
    assign O_bru_target = agu_result;

    assign O_except = I_except;

    assign O_stallreq = stallreq_div | stallreq_mul;
    
endmodule //exu
