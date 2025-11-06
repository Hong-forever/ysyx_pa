`include "defines.v"

module ifu_idu 
(
    input   wire                        clk,
    input   wire                        rst_n,
        
    input   wire    [`InstBus       ]   inst_i,             //指令内容
    input   wire    [`InstAddrBus   ]   inst_addr_i,        //指令地址

    output  reg     [`InstBus       ]   inst_o,             //指令内容
    output  reg     [`InstAddrBus   ]   inst_addr_o,        //指令地址

    input   wire                        jump_flag_i,
    input   wire    [`StallBus      ]   stall_i,            //流水线暂停标志
    input   wire                        flush_i             //指令冲刷
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            inst_o          <= 'b0;
            inst_addr_o     <= 'b0;
        end else if(((stall_i[`Stall_if_dec] == `Stop) && 
                     (stall_i[`Stall_dec_ex] == `NoStop)) ||
                     (flush_i == `Enable)) begin
            inst_o          <= 'b0;
            inst_addr_o     <= 'b0;
        end else if(stall_i[`Stall_if_dec] == `NoStop) begin
            if(jump_flag_i) begin
                inst_o      <= 'b0;
                inst_addr_o <= 'b0;
            end else begin
                inst_o      <= inst_i;
                inst_addr_o <= inst_addr_i;
            end
        end
    end

endmodule //ifu_idu