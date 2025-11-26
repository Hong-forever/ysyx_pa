`include "defines.v"

//------------------------------------------------------------------------
// 通用寄存器
//------------------------------------------------------------------------

module regfile
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`InstBus       ]   I_inst,               //指令内容
    input   wire    [`InstAddrBus   ]   I_inst_addr,

    input   wire    [`RegAddrBus    ]   I_rs1_raddr,      //读寄存器1地址
    input   wire    [`RegAddrBus    ]   I_rs2_raddr,      //读寄存器2地址

    output  wire    [`RegDataBus    ]   O_rs1_rdata,     //输出寄存器1数据
    output  wire    [`RegDataBus    ]   O_rs2_rdata,     //输出寄存器2数据

    input   wire                        I_rd_we,         //写寄存器标志
    input   wire    [`RegAddrBus    ]   I_rd_waddr,      //写寄存器地址
    input   wire    [`RegDataBus    ]   I_rd_wdata       //写寄存器数据

);

    reg [`RegDataBus] regs[0:`RegNum-1];   //寄存器组

    integer i;
    //写寄存器
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i = 0; i < `RegNum; i = i + 1) begin
                regs[i] <= `ZeroWord;
            end
        end else begin
            if((I_rd_we == `Enable) && (I_rd_waddr != `ZeroReg)) begin
                regs[I_rd_waddr] <= I_rd_wdata;
            end
        end
    end

    //读寄存器
    assign O_rs1_rdata = 
                I_rs1_raddr == `ZeroReg ? `ZeroWord :
                (I_rd_we && I_rd_waddr == I_rs1_raddr) ? I_rd_wdata : regs[I_rs1_raddr];

    assign O_rs2_rdata = 
                I_rs2_raddr == `ZeroReg ? `ZeroWord :
                (I_rd_we && I_rd_waddr == I_rs2_raddr) ? I_rd_wdata : regs[I_rs2_raddr];

    import "DPI-C" function void trap(input int reg_data, input int halt_pc);

    always @(*) begin
        if(I_inst == `RV_EBREAK) begin
            trap(regs[10], I_inst_addr);
        end
    end

    import "DPI-C" function void cpu_value(input int valid, input int inst, input int pc, 
        input int gpr0, input int gpr1, input int gpr2, input int gpr3, 
        input int gpr4, input int gpr5, input int gpr6, input int gpr7, 
        input int gpr8, input int gpr9, input int gpr10, input int gpr11, 
        input int gpr12, input int gpr13, input int gpr14, input int gpr15, 
        input int gpr16, input int gpr17, input int gpr18, input int gpr19, 
        input int gpr20, input int gpr21, input int gpr22, input int gpr23,
        input int gpr24, input int gpr25, input int gpr26, input int gpr27, 
        input int gpr28, input int gpr29, input int gpr30, input int gpr31);

    reg [`InstBus] inst_reg;
    reg [`InstAddrBus] pc_reg;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            inst_reg <= `ZeroWord;
            pc_reg   <= `ZeroWord;
        end else begin
            inst_reg <= I_inst;
            pc_reg   <= I_inst_addr;
        end
    end

    always @(*) begin
        if(I_inst != `ZeroWord && (inst_reg != I_inst || pc_reg != I_inst_addr))
            cpu_value(1, I_inst, I_inst_addr,
                  regs[0],  regs[1],  regs[2],  regs[3],  regs[4],  regs[5],  regs[6],  regs[7],
                  regs[8],  regs[9],  regs[10], regs[11], regs[12], regs[13], regs[14], regs[15],
                  regs[16], regs[17], regs[18], regs[19], regs[20], regs[21], regs[22], regs[23],
                  regs[24], regs[25], regs[26], regs[27], regs[28], regs[29], regs[30], regs[31]);
        else begin end
    end


    //for debug
    wire [`RegDataBus] ra_x1   = regs[1];
    wire [`RegDataBus] sp_x2   = regs[2];
    wire [`RegDataBus] gp_x3   = regs[3];
    wire [`RegDataBus] tp_x4   = regs[4];
    wire [`RegDataBus] t0_x5   = regs[5];
    wire [`RegDataBus] t1_x6   = regs[6];
    wire [`RegDataBus] t2_x7   = regs[7];
    wire [`RegDataBus] s0_x8   = regs[8];
    wire [`RegDataBus] fp_x8   = regs[8];
    wire [`RegDataBus] s1_x9   = regs[9];
    wire [`RegDataBus] a0_x10  = regs[10];
    wire [`RegDataBus] a1_x11  = regs[11];
    wire [`RegDataBus] a2_x12  = regs[12];
    wire [`RegDataBus] a3_x13  = regs[13];
    wire [`RegDataBus] a4_x14  = regs[14];
    wire [`RegDataBus] a5_x15  = regs[15];
    wire [`RegDataBus] a6_x16  = regs[16];
    wire [`RegDataBus] a7_x17  = regs[17];
    wire [`RegDataBus] s2_x18  = regs[18];
    wire [`RegDataBus] s3_x19  = regs[19];
    wire [`RegDataBus] s4_x20  = regs[20];
    wire [`RegDataBus] s5_x21  = regs[21];
    wire [`RegDataBus] s6_x22  = regs[22];
    wire [`RegDataBus] s7_x23  = regs[23];
    wire [`RegDataBus] s8_x24  = regs[24];
    wire [`RegDataBus] s9_x25  = regs[25];
    wire [`RegDataBus] s10_x26 = regs[26];
    wire [`RegDataBus] s11_x27 = regs[27];
    wire [`RegDataBus] t3_x28  = regs[28];
    wire [`RegDataBus] t4_x29  = regs[29];
    wire [`RegDataBus] t5_x30  = regs[30];
    wire [`RegDataBus] t6_x31  = regs[31];

endmodule //regfile
