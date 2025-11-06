`include "defines.v"

//------------------------------------------------------------------------
// 前递单元
//------------------------------------------------------------------------

module fwd_unit
(
    input   wire                        I_rs1_re,
    input   wire                        I_rs2_re,
    input   wire                        I_csr_re,

    input   wire    [`RegAddrBus    ]   I_rs1_raddr,
    input   wire    [`RegAddrBus    ]   I_rs2_raddr,
    input   wire    [`CSRAddrBus    ]   I_csr_raddr,

    input   wire                        I_ls_rd_we,
    input   wire    [`RegAddrBus    ]   I_ls_rd_waddr,

    input   wire                        I_wb_rd_we,
    input   wire    [`RegAddrBus    ]   I_wb_rd_waddr,

    input   wire                        I_ls_csr_we,
    input   wire    [`CSRAddrBus    ]   I_ls_csr_waddr,

    input   wire                        I_wb_csr_we,
    input   wire    [`CSRAddrBus    ]   I_wb_csr_waddr,


    output  wire    [`FWDSrc_sel_width-1:0] O_FWDCtrl_rs1,
    output  wire    [`FWDSrc_sel_width-1:0] O_FWDCtrl_rs2,
    output  wire    [`FWDSrc_sel_width-1:0] O_FWDCtrl_csr
);

    assign O_FWDCtrl_rs1 = (I_rs1_re & I_rs1_raddr != `ZeroReg)? 
                            (I_ls_rd_we & (I_ls_rd_waddr == I_rs1_raddr))? `FWDSrc_sel_ls :
                            (I_wb_rd_we & (I_wb_rd_waddr == I_rs1_raddr))? `FWDSrc_sel_wb :
                            `FWDSrc_sel_nfw : `FWDSrc_sel_nop;

    assign O_FWDCtrl_rs2 = (I_rs2_re & I_rs2_raddr != `ZeroReg)? 
                            (I_ls_rd_we & (I_ls_rd_waddr == I_rs2_raddr))? `FWDSrc_sel_ls :
                            (I_wb_rd_we & (I_wb_rd_waddr == I_rs2_raddr))? `FWDSrc_sel_wb :
                            `FWDSrc_sel_nfw : `FWDSrc_sel_nop;

    assign O_FWDCtrl_csr = (I_csr_re)? 
                            (I_ls_csr_we & (I_ls_csr_waddr == I_csr_raddr))? `FWDSrc_sel_ls :
                            (I_wb_csr_we & (I_wb_csr_waddr == I_csr_raddr))? `FWDSrc_sel_wb :
                            `FWDSrc_sel_nfw : `FWDSrc_sel_nop;


endmodule