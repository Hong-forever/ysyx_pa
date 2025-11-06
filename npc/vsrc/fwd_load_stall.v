`include "defines.v"

//------------------------------------------------------------------------
// fwd load stall
//------------------------------------------------------------------------

module fwd_load_stall
(
    input   wire                        I_ex_ls_valid,
    input   wire                        I_ex_ls_load,
    input   wire    [`RegAddrBus    ]   I_ex_rd_waddr,

    input   wire                        I_dec_rs1_re,
    input   wire    [`RegAddrBus    ]   I_dec_rs1_raddr,
    input   wire                        I_dec_rs2_re,
    input   wire    [`RegAddrBus    ]   I_dec_rs2_raddr,

    input   wire                        I_bru_taken,

    output  wire                        O_stallreq
);

    wire stallreq_ex1_dec1 = ((I_dec_rs1_re & (I_ex_rd_waddr == I_dec_rs1_raddr))  | 
                            (I_dec_rs2_re & (I_ex_rd_waddr == I_dec_rs2_raddr))) & 
                            ((I_ex_ls_valid & I_ex_ls_load) & ~I_bru_taken);


    assign O_stallreq = stallreq_ex1_dec1;

endmodule
