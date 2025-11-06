`include "defines.v"

//core local interruptor module
//核心中断管理、仲裁模块
module clint
(
    input   wire                        clk,
    input   wire                        rst_n,

    //外部信号
    input   wire    [`INT_BUS       ]   int_i,              //中断输入信号

    //from exu_lsu
    input   wire    [`InstBus       ]   inst_i,             //指令内容
    input   wire    [`InstAddrBus   ]   inst_addr_i,        //指令地址

    //from lsu
    input   wire                        memory_misalign_i,  //字节对其检查

    //from pipe_ctrl
    input   wire    [`StallBus      ]   stall_i,            //流水线暂停标志

    //from csr_reg
    input   wire    [`RegBus        ]   csr_mtvec_i,        //mtvec寄存器
    input   wire    [`RegBus        ]   csr_mepc_i,         //mepc寄存器
    input   wire    [`RegBus        ]   csr_mstatus_i,      //mstatus寄存器

    //from csr
    input   wire                        global_int_en_i,    //全局中断使能标志

    //to csr_reg
    output  wire                        csr_we_o,           //写CSR寄存器标志
    output  wire    [`MemAddrBus    ]   csr_waddr_o,        //写CSR寄存器地址
    output  wire    [`RegBus        ]   csr_wdata_o,        //写CSR寄存器数据

    //to pipe_ctrl
    output  wire                        stallreq_o,         //流水线暂停标志
    output  wire                        int_assert_o,       //中断标志
    output  wire    [`InstAddrBus   ]   int_addr_o          //中断入口地址

);

    //中断状态定义
    localparam S_INT_IDLE            = 4'b0001;
    localparam S_INT_SYNC_ASSERT     = 4'b0010;
    localparam S_INT_ASYNC_ASSERT    = 4'b0100;
    localparam S_INT_MRET            = 4'b1000;

    //写CSR寄存器状态定义
    localparam S_CSR_IDLE            = 5'b00001;
    localparam S_CSR_MSTATUS         = 5'b00010;
    localparam S_CSR_MEPC            = 5'b00100;
    localparam S_CSR_MSTATUS_MRET    = 5'b01000;
    localparam S_CSR_MCAUSE          = 5'b10000;

    reg [3:0] int_state;
    reg [4:0] csr_state;
    reg [`InstAddrBus] inst_addr;
    reg [31:0] cause;

    //中断仲裁逻辑
    always @(*) begin
        if(!rst_n) begin
            int_state = S_INT_IDLE;
        end else begin
            if(inst_i == `RV_ECALL || inst_i == `RV_EBREAK || memory_misalign_i) begin
                int_state = S_INT_SYNC_ASSERT;
            end else if(int_i != `INT_NONE && global_int_en_i == `True) begin
                int_state = S_INT_ASYNC_ASSERT;
            end else if(inst_i == `RV_MRET) begin
                int_state = S_INT_MRET;
            end else begin
                int_state = S_INT_IDLE;
            end
        end
    end

    //写CSR寄存器状态切换
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            csr_state <= S_CSR_IDLE;
            cause <= `ZeroWord;
            inst_addr <= `ZeroWord;
        end else begin
            case(csr_state)
                S_CSR_IDLE: begin
                    case(int_state)
                        //同步中断
                        S_INT_SYNC_ASSERT: begin
                            csr_state <= S_CSR_MEPC;
                            inst_addr <= inst_addr_i;
                            cause <= (inst_i == `RV_EBREAK)? 32'd3 :
                                     (inst_i == `RV_ECALL)? 32'd11 :
                                     (memory_misalign_i)? 32'd4 : 32'd10;
                        end
                        //异步中断
                        S_INT_ASYNC_ASSERT: begin
                            csr_state <= S_CSR_MEPC;
                            inst_addr <= inst_addr_i;
                            //定时器中断
                            cause <= 32'h80000004;
                        end
                        //中断返回
                        S_INT_MRET: begin
                            csr_state <= S_CSR_MSTATUS_MRET;
                        end
                        default: begin end
                    endcase
                end
                S_CSR_MEPC: csr_state <= S_CSR_MSTATUS;
                S_CSR_MSTATUS: csr_state <= S_CSR_MCAUSE;
                S_CSR_MCAUSE: csr_state <= S_CSR_IDLE;
                S_CSR_MSTATUS_MRET: csr_state <= S_CSR_IDLE;
                default: csr_state <= S_CSR_IDLE;
            endcase
        end
    end

    reg csr_we;  
    reg [`MemAddrBus] csr_waddr;
    reg [`RegBus] csr_wdata;
    

    //发出中断信号前，暂停流水线，写CSR寄存器
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            csr_we <= `Disable;
            csr_waddr <= `ZeroWord;
            csr_wdata <= `ZeroWord;
        end else begin
            case(csr_state)
                //将mepc寄存器的值设为当前指令地址
                S_CSR_MEPC: begin
                    csr_we <= `Enable;
                    csr_waddr <= {20'h0, `CSR_Addr_MEPC};
                    csr_wdata <= inst_addr;
                end
                //关闭全局中断
                S_CSR_MSTATUS: begin
                    csr_we <= `Enable;
                    csr_waddr <= {20'h0, `CSR_Addr_MSTATUS};
                    csr_wdata <= {csr_mstatus_i[31:8], csr_mstatus_i[3], csr_mstatus_i[6:4], 1'b0, csr_mstatus_i[2:0]};
                end
                //写中断产生的原因
                S_CSR_MCAUSE: begin
                    csr_we <= `Enable;
                    csr_waddr <= {20'h0, `CSR_Addr_MCAUSE};
                    csr_wdata <= cause;
                end
                //中断返回
                S_CSR_MSTATUS_MRET: begin
                    csr_we <= `Enable;
                    csr_waddr <= {20'h0, `CSR_Addr_MSTATUS};
                    csr_wdata <= {csr_mstatus_i[31:8], 1'b1, csr_mstatus_i[6:4], csr_mstatus_i[7], csr_mstatus_i[2:0]};
                end
                default: begin
                    csr_we <= `Disable;
                    csr_waddr <= `ZeroWord;
                    csr_wdata <= `ZeroWord;
                end
            endcase
        end
    end

    //*********************// 输出 //*********************//

    assign csr_we_o = csr_we;
    assign csr_waddr_o = csr_waddr;
    assign csr_wdata_o = csr_wdata;

    assign stallreq_o = (int_state != S_INT_IDLE) | (csr_state != S_CSR_IDLE);
    assign int_assert_o = (csr_state == S_CSR_MCAUSE) | (csr_state == S_CSR_MSTATUS_MRET);
    assign int_addr_o = (csr_state == S_CSR_MCAUSE)? csr_mtvec_i:
                        (csr_state == S_CSR_MSTATUS_MRET)? csr_mepc_i:
                        `ZeroWord;

endmodule
