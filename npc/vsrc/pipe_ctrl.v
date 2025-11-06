`include "defines.v"

module pipe_ctrl
(
    input   wire                        rst_n,

    input   wire                        stallreq_from_ifu,    //if阶段暂停请求, 来自axi_master模块
    input   wire                        stallreq_from_idu,    //id阶段暂停请求
    input   wire                        stallreq_from_exu,    //ex阶段暂停请求
    input   wire                        stallreq_from_lsu,    //mem阶段暂停请求
    input   wire                        stallreq_from_clint,  //clint阶段暂停请求
    //from jtag
    input   wire                        haltreq_from_jtag,

    output  wire    [`StallBus      ]   stall_o,


    //from clint
    input   wire                        int_assert_i,       //中断标志
    input   wire    [`InstAddrBus   ]   int_addr_i,         //中断入口地址


    output  wire                        flush_o,
    output  wire    [`InstAddrBus   ]   flush_addr_o
);

    reg [`StallBus] stall;
    always @(*) begin
        if(!rst_n) begin
            stall = `StallWidth'b00000;
        end else if(stallreq_from_clint == `Stop) begin  //暂停整条流水线
            stall = `StallWidth'b11111;                       
        end else if(stallreq_from_lsu == `Stop) begin   
            stall = `StallWidth'b11111;                               
        end else if(stallreq_from_exu == `Stop) begin
            stall = `StallWidth'b01111;
        end else if(stallreq_from_idu == `Stop) begin
            stall = `StallWidth'b00111;
        end else if(stallreq_from_ifu == `Stop) begin
            stall = `StallWidth'b00011;
        end else if(haltreq_from_jtag == `Stop) begin   //暂停整条流水线
            stall = `StallWidth'b11111;
        end else begin
            stall = `StallWidth'b00000;
        end    //if
    end      //always

    //*********************// 输出 //*********************//
    assign stall_o = stall;
    assign flush_o = stallreq_from_clint | int_assert_i;
    assign flush_addr_o = int_assert_i? int_addr_i : `ZeroWord;

    initial begin
        $monitor("stall: %d\n", stall);
    end


endmodule //pipe_ctrl



