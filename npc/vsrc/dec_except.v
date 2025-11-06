`include "defines.v"

//------------------------------------------------------------------------
// 异常指令译码单元
//------------------------------------------------------------------------

module dec_except
(
    input   wire    [`InstBus       ]   I_inst,
    // output  wire                        O_except_valid,
    output  wire    [`Except_Bus    ]   O_except
);
    // assign O_except_valid = 1'b0;

    // 异常指令
    assign O_except[`EXCPT_ECALL ] = (I_inst == `RV_ECALL);
    assign O_except[`EXCPT_EBREAK] = (I_inst == `RV_EBREAK);
    assign O_except[`EXCPT_MRET  ] = (I_inst == `RV_MRET);

endmodule

