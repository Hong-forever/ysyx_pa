`include "defines.v"

//------------------------------------------------------------------------
// 取指单元
//------------------------------------------------------------------------

module ifetch
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire                        I_bru_taken,        //跳转指令
    input   wire    [`InstAddrBus   ]   I_bru_target,

    input   wire                        I_jtag_halt,
    input   wire                        I_stall,            // 流水线暂停标志
    input   wire                        I_flush,            // 指令冲刷
    input   wire    [`InstAddrBus   ]   I_flush_addr,       // 冲刷跳转地址

    output  wire    [`InstBus       ]   O_inst,
    output  wire    [`InstAddrBus   ]   O_inst_addr,

    output  wire                        O_stallreq,

    //to bus
    output  wire                        O_ibus_req,
    output  wire                        O_ibus_we,
    output  wire    [`InstAddrBus   ]   O_ibus_addr,
    output  wire    [`InstBus       ]   O_ibus_data,
    output  wire    [`DBUS_MASK-1:0 ]   O_ibus_mask,
    input   wire    [`InstBus       ]   I_ibus_data

);

    //------------------------------------------------------------------------
    // 变量定义
    //------------------------------------------------------------------------
    wire [`InstAddrBus] npc;
    wire [`InstAddrBus] pc_plus4;

    reg ibus_req;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            ibus_req <= `False;
        end else begin
            ibus_req <= ~I_jtag_halt;
        end
    end

    // 取指PC
    reg [`InstAddrBus] pc;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            pc <= `RomAddrBase;
        end else begin
            pc <= npc;
        end
    end

    assign npc = I_flush      ? I_flush_addr    :
                 I_stall      ? pc              :
                 I_bru_taken  ? I_bru_target    :
                 pc_plus4;

    assign pc_plus4 = pc + 32'h4;

    assign O_inst = I_ibus_data;
    assign O_inst_addr = pc;

    assign O_ibus_req = ibus_req;
    assign O_ibus_we = `False;
    assign O_ibus_addr = pc;
    assign O_ibus_data = `ZeroWord;
    assign O_ibus_mask = 4'b1111;

    assign O_stallreq = 1'b0;


endmodule
