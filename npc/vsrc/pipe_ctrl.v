`include "defines.v"

//------------------------------------------------------------------------
// 流水线控制单元
//------------------------------------------------------------------------

module pipe_ctrl
(
    input   wire                        rst,

    input   wire                        stallreq_from_if,
    input   wire                        stallreq_from_dec,
    input   wire                        stallreq_from_ex,
    input   wire                        stallreq_from_ls,
    input   wire                        stallreq_from_clint,
    input   wire                        stallreq_from_jtag,

    output  wire    [`StallBus      ]   Stall,
    output  wire    [`KillBus       ]   Kill
);

    assign Stall =  stallreq_from_clint   ?    `StallWidth'b111111 :
                    stallreq_from_ls      ?    `StallWidth'b111111 :
                    stallreq_from_ex      ?    `StallWidth'b111111 :
                    stallreq_from_dec     ?    `StallWidth'b000111 :
                    stallreq_from_if      ?    `StallWidth'b000011 :
                    stallreq_from_jtag    ?    `StallWidth'b111111 :
                                               `StallWidth'b000000 ;

    assign Kill[`Kill_if_dec] = (Stall[`Stall_if_dec] & ~Stall[`Stall_dec_ex]);
    assign Kill[`Kill_dec_ex] = (Stall[`Stall_dec_ex] & ~Stall[`Stall_ex_ls]);
    assign Kill[`Kill_ex_ls ] = (Stall[`Stall_ex_ls] & ~Stall[`Stall_ls_wb]);
    assign Kill[`Kill_ls_wb ] = (Stall[`Stall_ls_wb] & ~Stall[`Stall_wb]);

endmodule



