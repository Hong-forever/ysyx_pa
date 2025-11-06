`include "defines.v"

//ifu模块
module ifu
(
    input   wire                        clk,
    input   wire                        rst_n,

    //from jtag
    input   wire                        jtag_halt_i,

    //from idu
    input   wire                        jump_flag_i,    //跳转指令，分支预测？？？待改
    input   wire    [`InstAddrBus   ]   jump_addr_i,

    //from pipe_ctrl
    input   wire    [`StallBus      ]   stall_i,        //流水线暂停标志
    input   wire                        flush_i,        //指令冲刷
    input   wire    [`InstAddrBus   ]   flush_addr_i,   //冲刷跳转地址

    //to ifu_idu
    output  wire    [`InstBus       ]   inst_o,
    output  wire    [`InstAddrBus   ]   inst_addr_o,

    //to bus
    output  wire                        ibus_req_o,
    output  wire    [`InstAddrBus   ]   ibus_addr_o,
    input   wire    [`InstBus       ]   ibus_data_i,

    //to pipe_ctrl
    output  wire                        stallreq_o

);
    //*********************// 握手信号 //*********************//

    wire stall = stall_i[`Stall_pc];

    reg ibus_req;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ibus_req <= `False;
        end else begin
            ibus_req <= `True;
        end
    end

    reg [`InstAddrBus] pc;
    always @(posedge clk) begin
        if(!ibus_req) begin
            pc <= `RomAddrBase;
        end else if(flush_i) begin
            pc <= flush_addr_i;
        end else if(!stall) begin
            if(jump_flag_i) begin
                pc <= jump_addr_i;
            end else begin
                pc <= pc + 32'h4;
            end
        end
    end


    //*********************// 输出 //*********************//
    assign ibus_addr_o = pc;
    assign inst_addr_o = pc;
    assign inst_o = ibus_data_i;

    assign ibus_req_o = ibus_req; 

    initial begin
        $monitor("ifu========= inst: 0x%08x, pc: 0x%08x\n", inst_o, pc);
    end


endmodule //ifu
