`include "defines.v"

//如果要使用和维护浮点单元，可能要添加mstatus的fs域？后面修改

module csr_reg
(
    input   wire                        clk,
    input   wire                        rst_n,

    //from idu
    input   wire                        re_i,               //idu模块读寄存器标志
    input   wire    [`MemAddrBus    ]   raddr_i,            //idu模块读寄存器地址
    //to idu
    output  wire    [`RegBus        ]   rdata_o,            //输出寄存器数据

    //form lsu_wbu
    input   wire                        we_i,               //lsu_wbu模块写寄存器标志
    input   wire    [`MemAddrBus    ]   waddr_i,            //lsu_wbu模块写寄存器地址
    input   wire    [`RegBus        ]   wdata_i,            //lsu_wbu模块写寄存器数据

    //from clint
    input   wire                        clint_we_i,         //clint模块写寄存器标志
    input   wire    [`MemAddrBus    ]   clint_waddr_i,      //clint模块写寄存器地址
    input   wire    [`RegBus        ]   clint_wdata_i,      //clint模块写寄存器数据

    //to clint
    output  wire    [`RegBus        ]   csr_mtvec_o,        //mtvec
    output  wire    [`RegBus        ]   csr_mepc_o,         //mepc
    output  wire    [`RegBus        ]   csr_mstatus_o,      //mstatus
    output  wire                        csr_timer_int_o,    //内部定时器中断

    output  wire                        global_int_en_o     //全局中断使能标志

);

    reg [`RegBus] mstatus;
    reg [`RegBus] mie;
    reg [`RegBus] mtvec;
    reg [`RegBus] mscratch;
    reg [`RegBus] mepc;
    reg [`RegBus] mcause;
    reg [`DoubleRegBus] mtimecmp;   //未定定义地址，未实现
    reg [`DoubleRegBus] cycle;


    //cycle counter
    //复位撤销后就一直计数
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cycle <= {`ZeroWord, `ZeroWord};
        end else begin
            cycle <= cycle + 1'b1;
        end
    end

    reg csr_timer_int;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            csr_timer_int <= `INT_DEASSERT;
        end else begin
            if(mtimecmp != {`ZeroWord, `ZeroWord} && cycle == mtimecmp) begin
                csr_timer_int <= `INT_ASSERT;
            end
        end
    end

    //write reg
    //写寄存器操作

    wire we = we_i | clint_we_i;
    wire [`MemAddrBus] waddr = (we_i)? waddr_i : clint_waddr_i;
    wire [`RegBus] wdata = (we_i)? wdata_i : clint_wdata_i;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mtvec <= `ZeroWord;
            mcause <= `ZeroWord;
            mepc <= `ZeroWord;
            mie <= `ZeroWord;
            mstatus <= `ZeroWord;
            mscratch <= `ZeroWord;
        end else begin
            if(we == `Enable) begin
                case(waddr[11:0])
                    `CSR_Addr_MSTATUS: mstatus <= wdata;
                    `CSR_Addr_MIE: mie <= wdata;
                    `CSR_Addr_MTVEC: mtvec <= wdata;
                    `CSR_Addr_MSCRATCH: mscratch <= wdata;
                    `CSR_Addr_MEPC: mepc <= wdata;
                    `CSR_Addr_MCAUSE: mcause <= wdata;
                    default: begin end
                endcase
            end
        end
    end


    //read reg
    //idu模块读CSR寄存器
    reg [`RegBus]   rdata;
    always @(*) begin
        if((re_i == `Enable) && (raddr_i[11:0] == waddr_i[11:0]) 
            && (we_i == `Enable)) begin
            rdata = wdata_i;
        end else begin
            case(raddr_i[11:0])
                `CSR_Addr_MSTATUS: rdata = mstatus;
                `CSR_Addr_MIE:  rdata = mie;
                `CSR_Addr_MTVEC:  rdata = mtvec;
                `CSR_Addr_MSCRATCH: rdata = mscratch;
                `CSR_Addr_MEPC: rdata = mepc;
                `CSR_Addr_MCAUSE: rdata = mcause;
                `CSR_Addr_CYCLE: rdata = cycle[31:0];
                `CSR_Addr_CYCLEH: rdata = cycle[63:32];
                default: rdata = `ZeroWord;
            endcase
        end
    end


    //*********************// 输出 //*********************//
    assign rdata_o = rdata;

    assign csr_mstatus_o = mstatus;
    assign csr_mtvec_o = mtvec;
    assign csr_mepc_o = mepc;
    assign csr_timer_int_o = csr_timer_int;
    assign global_int_en_o = (mstatus[3] == 1'b1)? `True : `False;  //mstatus[3]为mie域，全局中断使能位

endmodule
