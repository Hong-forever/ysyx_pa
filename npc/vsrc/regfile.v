`include "defines.v"

module regfile
(
    input   wire                        clk,
    input   wire                        rst_n,
    
    input   wire    [`InstBus       ]   inst_i,         //指令内容
    input   wire    [`InstAddrBus   ]   inst_addr_i,

    //from idu
    input   wire                        reg1_re_i,      //读寄存器1使能
    input   wire  [`RegAddrBus      ]   raddr1_i,       //读寄存器1地址
    //to idu
    output  wire  [`RegBus          ]   rdata1_o,       //输出寄存器1数据

    //from idu
    input   wire                        reg2_re_i,      //读寄存器2使能
    input   wire  [`RegAddrBus      ]   raddr2_i,       //读寄存器2地址
    //to idu
    output  wire  [`RegBus          ]   rdata2_o,       //输出寄存器2数据

    //from lsu
    input   wire                        we_i,           //写寄存器标志
    input   wire  [`RegAddrBus      ]   waddr_i,        //写寄存器地址
    input   wire  [`RegBus          ]   wdata_i         //写寄存器数据

);

    reg [`RegBus] regs[0:`RegNum-1];   //寄存器组

    reg [`RegBus] rdata1;
    reg [`RegBus] rdata2;


    //写寄存器
    integer i;
    always @(posedge clk) begin
        // if(rst_n == `RstEnable) begin
        //     for (i = 0; i < `RegNum; i = i + 1) begin
        //         regs[i] <= `ZeroWord;
        //     end
        // end else begin
            if((we_i == `Enable) && (waddr_i != `ZeroReg)) begin
                regs[waddr_i] <= wdata_i;
            end
        // end
    end

    //读寄存器1
    always @(*) begin
        if(raddr1_i == `ZeroReg) begin
            rdata1 = `ZeroWord;
        //在IDU和WBU之间的数据相关处理
        end else if((raddr1_i == waddr_i) && (we_i == `Enable)
                     && (reg1_re_i == `Enable)) begin
            rdata1 = wdata_i;
        end else begin
            rdata1 = regs[raddr1_i];
        end
    end

    //读寄存器2
    always @(*) begin
        if(raddr2_i == `ZeroReg) begin
            rdata2 = `ZeroWord;
        //在IDU和WBU之间的数据相关处理
        end else if((raddr2_i == waddr_i) && (we_i == `Enable)
                     && (reg2_re_i == `Enable)) begin
            rdata2 = wdata_i;
        end else begin
            rdata2 = regs[raddr2_i];
        end
    end

    //*********************// 输出 //*********************//
    assign rdata1_o = rdata1;
    assign rdata2_o = rdata2;


    //for debug
    wire [`RegBus] zero    = regs[0];
    wire [`RegBus] ra_x1   = regs[1];
    wire [`RegBus] sp_x2   = regs[2];
    wire [`RegBus] gp_x3   = regs[3];
    wire [`RegBus] tp_x4   = regs[4];
    wire [`RegBus] t0_x5   = regs[5];
    wire [`RegBus] t1_x6   = regs[6];
    wire [`RegBus] t2_x7   = regs[7];
    wire [`RegBus] s0_x8   = regs[8];
    wire [`RegBus] fp_x8   = regs[8];
    wire [`RegBus] s1_x9   = regs[9];
    wire [`RegBus] a0_x10  = regs[10];
    wire [`RegBus] a1_x11  = regs[11];
    wire [`RegBus] a2_x12  = regs[12];
    wire [`RegBus] a3_x13  = regs[13];
    wire [`RegBus] a4_x14  = regs[14];
    wire [`RegBus] a5_x15  = regs[15];
    wire [`RegBus] a6_x16  = regs[16];
    wire [`RegBus] a7_x17  = regs[17];
    wire [`RegBus] s2_x18  = regs[18];
    wire [`RegBus] s3_x19  = regs[19];
    wire [`RegBus] s4_x20  = regs[20];
    wire [`RegBus] s5_x21  = regs[21];
    wire [`RegBus] s6_x22  = regs[22];
    wire [`RegBus] s7_x23  = regs[23];
    wire [`RegBus] s8_x24  = regs[24];
    wire [`RegBus] s9_x25  = regs[25];
    wire [`RegBus] s10_x26 = regs[26];
    wire [`RegBus] s11_x27 = regs[27];
    wire [`RegBus] t3_x28  = regs[28];
    wire [`RegBus] t4_x29  = regs[29];
    wire [`RegBus] t5_x30  = regs[30];
    wire [`RegBus] t6_x31  = regs[31];

endmodule //regfile
