`include "defines.v"

//------------------------------------------------------------------------
// 取指译码流水线单元
//------------------------------------------------------------------------

module pipeline_if_dec
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`InstBus       ]   I_inst,             // 指令内容
    input   wire    [`InstAddrBus   ]   I_inst_addr,        // 指令地址

    output  reg     [`InstBus       ]   O_inst,             // 指令内容
    output  reg     [`InstAddrBus   ]   O_inst_addr,        // 指令地址

    input   wire                        I_bru_taken,
    input   wire                        I_stall,            // 流水线暂停标志
    input   wire                        I_kill,             // 指令冲刷
    input   wire                        I_flush             // 指令冲刷
);
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            O_inst          <= 'b0;
            O_inst_addr     <= 'b0;
        end else if(I_kill | I_flush  | (I_bru_taken & ~I_stall)) begin
            O_inst          <= 'b0;
            O_inst_addr     <= 'b0;
        end else if(~I_stall) begin
            O_inst          <= I_inst;
            O_inst_addr     <= I_inst_addr;
        end
    end

endmodule



//------------------------------------------------------------------------
// 译码执行流水线单元
//------------------------------------------------------------------------

module pipeline_dec_ex
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`InstBus       ]   I_inst,             // 指令内容
    input   wire    [`InstAddrBus   ]   I_inst_addr,        // 指令地址
    input   wire    [`RegDataBus    ]   I_rs1_rdata,        // 通用寄存器1读数据
    input   wire    [`RegDataBus    ]   I_rs2_rdata,        // 通用寄存器2读数据
    input   wire    [`RegDataBus    ]   I_imm,              // 立即数
    input   wire                        I_rd_we,            // 写通用寄存器标志
    input   wire    [`RegAddrBus    ]   I_rd_waddr,         // 写通用寄存器地址
    input   wire                        I_csr_we,           // 写CSR寄存器标志
    input   wire    [`CSRAddrBus    ]   I_csr_waddr,        // 写CSR寄存器地址
    input   wire    [`CSRDataBus    ]   I_csr_rdata,        // CSR寄存器读数据
    input   wire    [`CSRCTL_WIDTH-1:0] I_CSRCtrl,
    input   wire    [`ALUCTL_WIDTH-1:0] I_ALUCtrl,          // ALU控制信号
    input   wire    [`BRUCTL_WIDTH-1:0] I_BRUCtrl,          // BRU控制信号
    input   wire    [`FWDSrc_sel_width-1:0] I_FWDCtrl_rs1,
    input   wire    [`FWDSrc_sel_width-1:0] I_FWDCtrl_rs2,
    input   wire    [`FWDSrc_sel_width-1:0] I_FWDCtrl_csr,
    input   wire    [`ALUSrcA_sel_width-1:0] I_ALUSrcA_sel,
    input   wire    [`ALUSrcB_sel_width-1:0] I_ALUSrcB_sel,
    input   wire    [`AGUSrc_sel_width-1:0]  I_AGUSrc_sel,
    input   wire    [`CSRSrc_sel_width-1:0]  I_CSRSrc_sel,
    input   wire                        I_ls_valid,         // 访存有效标志
    input   wire    [`ls_diff_bus   ]   I_ls_type,          // 访存有效标志
    input   wire                        I_csr_re,
    input   wire    [`Except_Bus    ]   I_except,           // 异常

    output  reg     [`InstBus       ]   O_inst,             // 指令内容
    output  reg     [`InstAddrBus   ]   O_inst_addr,        // 指令地址
    output  reg     [`RegDataBus    ]   O_rs1_rdata,        // 通用寄存器1读数据
    output  reg     [`RegDataBus    ]   O_rs2_rdata,        // 通用寄存器2读数据
    output  reg     [`RegDataBus    ]   O_imm,              // 立即数
    output  reg                         O_rd_we,            // 写通用寄存器标志
    output  reg     [`RegAddrBus    ]   O_rd_waddr,         // 写通用寄存器地址
    output  reg                         O_csr_we,           // 写CSR寄存器标志
    output  reg     [`CSRAddrBus    ]   O_csr_waddr,        // 写CSR寄存器地址
    output  reg     [`CSRDataBus    ]   O_csr_rdata,        // CSR寄存器读数据
    output  reg     [`CSRCTL_WIDTH-1:0] O_CSRCtrl,
    output  reg     [`ALUCTL_WIDTH-1:0] O_ALUCtrl,          // ALU控制信号
    output  reg     [`BRUCTL_WIDTH-1:0] O_BRUCtrl,          // BRU控制信号
    output  reg     [`FWDSrc_sel_width-1:0] O_FWDCtrl_rs1,
    output  reg     [`FWDSrc_sel_width-1:0] O_FWDCtrl_rs2,
    output  reg     [`FWDSrc_sel_width-1:0] O_FWDCtrl_csr,
    output  reg                         O_fwd_rd_we,            // 写通用寄存器标志
    output  reg     [`RegAddrBus    ]   O_fwd_rd_waddr,         // 写通用寄存器地址
    output  reg                         O_fwd_csr_we,           // 写CSR寄存器标志
    output  reg     [`CSRAddrBus    ]   O_fwd_csr_waddr,        // 写CSR寄存器地址
    output  reg     [`ALUSrcA_sel_width-1:0] O_ALUSrcA_sel,
    output  reg     [`ALUSrcB_sel_width-1:0] O_ALUSrcB_sel,
    output  reg     [`AGUSrc_sel_width-1:0]  O_AGUSrc_sel,
    output  reg     [`CSRSrc_sel_width-1:0]  O_CSRSrc_sel,
    output  reg                         O_ls_valid,         // 访存有效标志
    output  reg     [`ls_diff_bus   ]   O_ls_type,          // 访存有效标志
    output  reg                         O_csr_re,
    output  reg     [`Except_Bus    ]   O_except,           // 异常

    input   wire                        I_bru_taken,
    input   wire                        I_stall,            // 流水线暂停标志
    input   wire                        I_kill,             // 指令冲刷
    input   wire                        I_flush             // 指令冲刷
);
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            O_inst          <= 'b0;
            O_inst_addr     <= 'b0;
            O_rs1_rdata     <= 'b0;
            O_rs2_rdata     <= 'b0;
            O_rd_we         <= 'b0;
            O_imm           <= 'b0;
            O_rd_waddr      <= 'b0;
            O_csr_we        <= 'b0;
            O_csr_waddr     <= 'b0;
            O_csr_rdata     <= 'b0;
            O_CSRCtrl       <= 'b0;
            O_ALUCtrl       <= 'b0;
            O_BRUCtrl       <= 'b0;
            O_FWDCtrl_rs1   <= 'b0;
            O_FWDCtrl_rs2   <= 'b0;
            O_FWDCtrl_csr   <= 'b0;
            O_fwd_rd_we     <= 'b0;
            O_fwd_rd_waddr  <= 'b0;
            O_fwd_csr_we    <= 'b0;
            O_fwd_csr_waddr <= 'b0;
            O_ALUSrcA_sel   <= 'b0;
            O_ALUSrcB_sel   <= 'b0;
            O_AGUSrc_sel    <= 'b0;
            O_CSRSrc_sel    <= 'b0;
            O_ls_valid      <= 'b0;
            O_ls_type       <= 'b0;
            O_csr_re        <= 'b0;
            O_except        <= 'b0;
        end else if(I_kill | I_flush | (I_bru_taken & ~I_stall)) begin
            O_inst          <= 'b0;
            O_inst_addr     <= 'b0;
            O_rs1_rdata     <= 'b0;
            O_rs2_rdata     <= 'b0;
            O_rd_we         <= 'b0;
            O_imm           <= 'b0;
            O_rd_waddr      <= 'b0;
            O_csr_we        <= 'b0;
            O_csr_waddr     <= 'b0;
            O_csr_rdata     <= 'b0;
            O_CSRCtrl       <= 'b0;
            O_ALUCtrl       <= 'b0;
            O_BRUCtrl       <= 'b0;
            O_FWDCtrl_rs1   <= 'b0;
            O_FWDCtrl_rs2   <= 'b0;
            O_FWDCtrl_csr   <= 'b0;
            O_fwd_rd_we     <= 'b0;
            O_fwd_rd_waddr  <= 'b0;
            O_fwd_csr_we    <= 'b0;
            O_fwd_csr_waddr <= 'b0;
            O_ALUSrcA_sel   <= 'b0;
            O_ALUSrcB_sel   <= 'b0;
            O_AGUSrc_sel    <= 'b0;
            O_CSRSrc_sel    <= 'b0;
            O_ls_valid      <= 'b0;
            O_ls_type       <= 'b0;
            O_csr_re        <= 'b0;
            O_except        <= 'b0;
        end else if(~I_stall) begin
            O_inst          <= I_inst;
            O_inst_addr     <= I_inst_addr;
            O_rs1_rdata     <= I_rs1_rdata;
            O_rs2_rdata     <= I_rs2_rdata;
            O_rd_we         <= I_rd_we;
            O_rd_waddr      <= I_rd_waddr;
            O_imm           <= I_imm;
            O_csr_we        <= I_csr_we;
            O_csr_waddr     <= I_csr_waddr;
            O_csr_rdata     <= I_csr_rdata;
            O_CSRCtrl       <= I_CSRCtrl;
            O_ALUCtrl       <= I_ALUCtrl;
            O_BRUCtrl       <= I_BRUCtrl;
            O_FWDCtrl_rs1   <= I_FWDCtrl_rs1;
            O_FWDCtrl_rs2   <= I_FWDCtrl_rs2;
            O_FWDCtrl_csr   <= I_FWDCtrl_csr;
            O_fwd_rd_we     <= I_rd_we;
            O_fwd_rd_waddr  <= I_rd_waddr;
            O_fwd_csr_we    <= I_csr_we;
            O_fwd_csr_waddr <= I_csr_waddr;
            O_ALUSrcA_sel   <= I_ALUSrcA_sel;
            O_ALUSrcB_sel   <= I_ALUSrcB_sel;
            O_AGUSrc_sel    <= I_AGUSrc_sel;
            O_CSRSrc_sel    <= I_CSRSrc_sel;
            O_ls_valid      <= I_ls_valid;
            O_ls_type       <= I_ls_type;
            O_csr_re        <= I_csr_re;
            O_except        <= I_except;
        end
    end

endmodule


//------------------------------------------------------------------------
// 执行访存流水线单元
//------------------------------------------------------------------------

module pipeline_ex_ls
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`InstBus       ]   I_inst,             // 指令内容
    input   wire    [`InstAddrBus   ]   I_inst_addr,
    input   wire                        I_rd_we,
    input   wire    [`RegAddrBus    ]   I_rd_waddr,
    input   wire    [`RegDataBus    ]   I_rd_wdata,
    input   wire    [`MemAddrBus    ]   I_memory_addr,
    input   wire    [`MemDataBus    ]   I_store_data,
    input   wire                        I_ls_valid,         // 访存有效标志
    input   wire    [`ls_diff_bus   ]   I_ls_type,
    input   wire                        I_csr_we,           // 写CSR寄存器标志
    input   wire    [`CSRAddrBus    ]   I_csr_waddr,        // 写CSR寄存器地址
    input   wire    [`CSRDataBus    ]   I_csr_wdata,        // 写CSR寄存器数据
    input   wire    [`Except_Bus    ]   I_except,           // 异常

    output  reg     [`InstBus       ]   O_inst,             // 指令内容
    output  reg     [`InstAddrBus   ]   O_inst_addr,        // 指令地址
    output  reg                         O_rd_we,
    output  reg     [`RegAddrBus    ]   O_rd_waddr,
    output  reg     [`RegDataBus    ]   O_rd_wdata,
    output  reg     [`MemAddrBus    ]   O_memory_addr,
    output  reg     [`MemDataBus    ]   O_store_data,
    output  reg                         O_ls_valid,         // 访存有效标志
    output  reg     [`ls_diff_bus   ]   O_ls_type,
    output  reg                         O_csr_we,           // 写CSR寄存器标志
    output  reg     [`CSRAddrBus    ]   O_csr_waddr,        // 写CSR寄存器地址
    output  reg     [`CSRDataBus    ]   O_csr_wdata,        // 写CSR寄存器数据
    output  reg                         O_fwd_rd_we,
    output  reg     [`RegAddrBus    ]   O_fwd_rd_waddr,
    output  reg     [`RegDataBus    ]   O_fwd_rd_wdata,
    output  reg                         O_fwd_csr_we,
    output  reg     [`CSRAddrBus    ]   O_fwd_csr_waddr,
    output  reg     [`CSRDataBus    ]   O_fwd_csr_wdata,
    output  reg     [`Except_Bus    ]   O_except,           // 异常

    input   wire                        I_stall,            // 流水线暂停标志
    input   wire                        I_kill,             // 指令冲刷
    input   wire                        I_flush             // 指令冲刷

);
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            O_inst        <= 'b0;
            O_inst_addr   <= 'b0;
            O_rd_we       <= 'b0;
            O_rd_waddr    <= 'b0;
            O_rd_wdata    <= 'b0;
            O_memory_addr <= 'b0;
            O_store_data  <= 'b0;
            O_fwd_rd_we   <= 'b0;
            O_fwd_rd_waddr<= 'b0;
            O_fwd_rd_wdata<= 'b0;
            O_fwd_csr_we  <= 'b0;
            O_fwd_csr_waddr<= 'b0;
            O_fwd_csr_wdata<= 'b0;
            O_ls_valid    <= 'b0;
            O_ls_type     <= 'b0;
            O_csr_we      <= 'b0;
            O_csr_waddr   <= 'b0;
            O_csr_wdata   <= 'b0;
            O_except      <= 'b0;
        end else if(I_kill | I_flush) begin
            O_inst        <= 'b0;
            O_inst_addr   <= 'b0;
            O_rd_we       <= 'b0;
            O_rd_waddr    <= 'b0;
            O_rd_wdata    <= 'b0;
            O_memory_addr <= 'b0;
            O_store_data  <= 'b0;
            O_fwd_rd_we   <= 'b0;
            O_fwd_rd_waddr<= 'b0;
            O_fwd_rd_wdata<= 'b0;
            O_fwd_csr_we  <= 'b0;
            O_fwd_csr_waddr<= 'b0;
            O_fwd_csr_wdata<= 'b0;
            O_ls_valid    <= 'b0;
            O_ls_type     <= 'b0;
            O_csr_we      <= 'b0;
            O_csr_waddr   <= 'b0;
            O_csr_wdata   <= 'b0;
            O_except      <= 'b0;
        end else if(~I_stall) begin
            O_inst        <= I_inst;
            O_inst_addr   <= I_inst_addr;
            O_rd_we       <= I_rd_we;
            O_rd_waddr    <= I_rd_waddr;
            O_rd_wdata    <= I_rd_wdata;
            O_memory_addr <= I_memory_addr;
            O_store_data  <= I_store_data;
            O_fwd_rd_we   <= I_rd_we;
            O_fwd_rd_waddr<= I_rd_waddr;
            O_fwd_rd_wdata<= I_rd_wdata;
            O_fwd_csr_we  <= I_csr_we;
            O_fwd_csr_waddr<= I_csr_waddr;
            O_fwd_csr_wdata<= I_csr_wdata;
            O_ls_valid    <= I_ls_valid;
            O_ls_type     <= I_ls_type;
            O_csr_we      <= I_csr_we;
            O_csr_waddr   <= I_csr_waddr;
            O_csr_wdata   <= I_csr_wdata;
            O_except      <= I_except;
        end
    end

endmodule


//------------------------------------------------------------------------
// 访存写回流水线单元
//------------------------------------------------------------------------

module pipeline_ls_wb
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`InstBus       ]   I_inst,             // 指令内容
    input   wire    [`InstAddrBus   ]   I_inst_addr,        // 指令地址
    input   wire                        I_rd_we,
    input   wire    [`RegAddrBus    ]   I_rd_waddr,
    input   wire    [`RegDataBus    ]   I_rd_wdata,
    input   wire                        I_csr_we,           // 写CSR寄存器标志
    input   wire    [`CSRAddrBus    ]   I_csr_waddr,        // 写CSR寄存器地址
    input   wire    [`CSRDataBus    ]   I_csr_wdata,        // 写CSR寄存器数据


    output  reg     [`InstBus       ]   O_inst,             // 指令内容
    output  reg     [`InstAddrBus   ]   O_inst_addr,        // 指令地址
    output  reg                         O_rd_we,
    output  reg     [`RegAddrBus    ]   O_rd_waddr,
    output  reg     [`RegDataBus    ]   O_rd_wdata,
    output  reg                         O_csr_we,           // 写CSR寄存器标志
    output  reg     [`CSRAddrBus    ]   O_csr_waddr,        // 写CSR寄存器地址
    output  reg     [`CSRDataBus    ]   O_csr_wdata,        // 写CSR寄存器数据
    output  reg     [`RegDataBus    ]   O_fwd_rd_wdata,
    output  reg     [`CSRDataBus    ]   O_fwd_csr_wdata,
    input   wire                        I_stall,            // 流水线暂停标志
    input   wire                        I_stallreq_from_lsu, // 流水线暂停标志
    input   wire                        I_kill,             // 指令冲刷
    input   wire                        I_flush             // 指令冲刷

);

    reg stall_from_lsu;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            stall_from_lsu <= `Disable;
        end else begin
            stall_from_lsu <= I_stallreq_from_lsu;
        end
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            O_inst      <= 'b0;
            O_inst_addr <= 'b0;
            O_rd_we     <= 'b0;
            O_rd_waddr  <= 'b0;
            O_rd_wdata  <= 'b0;
            O_fwd_rd_wdata<= 'b0;
            O_fwd_csr_wdata<= 'b0;
            O_csr_we    <= 'b0;
            O_csr_waddr <= 'b0;
            O_csr_wdata <= 'b0;
        end else if(I_kill | I_flush) begin
            O_inst      <= 'b0;
            O_inst_addr <= 'b0;
            O_rd_we     <= 'b0;
            O_rd_waddr  <= 'b0;
            O_rd_wdata  <= 'b0;
            O_fwd_rd_wdata<= 'b0;
            O_fwd_csr_wdata<= 'b0;
            O_csr_we    <= 'b0;
            O_csr_waddr <= 'b0;
            O_csr_wdata <= 'b0;
        end else if(~I_stall | (stall_from_lsu & I_stall)) begin
            O_inst      <= I_inst;
            O_inst_addr <= I_inst_addr;
            O_rd_we     <= I_rd_we;
            O_rd_waddr  <= I_rd_waddr;
            O_rd_wdata  <= I_rd_wdata;
            O_fwd_rd_wdata<= I_rd_wdata;
            O_fwd_csr_wdata<= I_csr_wdata;
            O_csr_we    <= I_csr_we;
            O_csr_waddr <= I_csr_waddr;
            O_csr_wdata <= I_csr_wdata;
        end
    end



endmodule