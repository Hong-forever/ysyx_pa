`include "defines.v"

//------------------------------------------------------------------------
// 执行CSR模块
//------------------------------------------------------------------------

module exe_csr
(
    input   wire    [`CSRDataBus    ]   I_csr_src,
    input   wire    [`CSRDataBus    ]   I_csr_rdata,
    input   wire    [`CSRCTL_WIDTH-1:0] I_csr_ctrl,

    output  wire    [`CSRDataBus    ]   O_csr_wdata
);
    wire [`CSRDataBus] rv_csrrw_res = I_csr_src;
    wire [`CSRDataBus] rv_csrrs_res = I_csr_rdata | I_csr_src;
    wire [`CSRDataBus] rv_csrrc_res = I_csr_rdata & (~I_csr_src);

    reg [`CSRDataBus] csr_wdata;
    always @(*) begin
        case(I_csr_ctrl)
            `CSRCTL_WRI:   csr_wdata = rv_csrrw_res;
            `CSRCTL_SET:   csr_wdata = rv_csrrs_res;
            `CSRCTL_CLR:   csr_wdata = rv_csrrc_res;
            `CSRCTL_NOP:   csr_wdata = `ZeroWord;
        endcase
    end

    assign O_csr_wdata = csr_wdata;

endmodule
