`include "defines.v"

//------------------------------------------------------------------------
// 核心中断管理
//------------------------------------------------------------------------

module clint
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`INT_BUS       ]   I_int,

    input   wire    [`Except_Bus    ]   I_except,
    input   wire    [`InstAddrBus   ]   I_except_addr,

    input   wire    [`InstAddrBus   ]   I_next_addr,        //下一个指令，用以判断是否当前指令地址空泡

    input   wire    [`CSRDataBus    ]   I_csr_mtvec,        //mtvec寄存器
    input   wire    [`CSRDataBus    ]   I_csr_mepc,         //mepc寄存器
    input   wire    [`CSRDataBus    ]   I_csr_mstatus,      //mstatus寄存器
    input   wire                        I_global_int_en,    //全局中断使能标志

    output  wire                        O_csr_we,           //写CSR寄存器标志
    output  wire    [`CSRAddrBus    ]   O_csr_waddr,        //写CSR寄存器地址
    output  wire    [`CSRDataBus    ]   O_csr_wdata,        //写CSR寄存器数据

    output  wire                        O_stallreq,         //流水线暂停标志
    output  wire                        O_flush,            //刷新标志
    output  wire    [`InstAddrBus   ]   O_flush_addr        //刷新地址

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

    wire is_ecall  = I_except[`EXCPT_ECALL ];
    wire is_ebreak = I_except[`EXCPT_EBREAK];
    wire is_mret   = I_except[`EXCPT_MRET  ];

    reg ext_int_valid;
    reg [`INT_BUS] int_r;
    reg [`InstAddrBus] ext_int_addr;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            ext_int_valid <= `Disable;
            ext_int_addr <= `ZeroWord;
            int_r <= `INT_NONE;
        end else if(I_next_addr != `ZeroWord) begin
            ext_int_valid <= `Enable;
            ext_int_addr <= I_next_addr;
            int_r <= `INT_NONE;
        end else begin
            ext_int_valid <= `Disable;
            ext_int_addr <= `ZeroWord;
            int_r <= I_int;
        end
    end

    //中断仲裁逻辑
    always @(*) begin
        if(rst) begin
            int_state = S_INT_IDLE;
        end else begin
            if(is_ecall || is_ebreak) begin
                int_state = S_INT_SYNC_ASSERT;
            end else if(ext_int_valid && (|I_int || |int_r) && I_global_int_en) begin
                int_state = S_INT_ASYNC_ASSERT;
            end else if(is_mret) begin
                int_state = S_INT_MRET;
            end else begin
                int_state = S_INT_IDLE;
            end
        end
    end

    //写CSR寄存器状态切换
    always @(posedge clk or posedge  rst) begin
        if(rst) begin
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
                            inst_addr <= I_except_addr;
                            cause <= (is_ebreak)? 32'd3 :
                                     (is_ecall)? 32'd11 :
                                     32'd10;
                        end
                        //异步中断
                        S_INT_ASYNC_ASSERT: begin
                            csr_state <= S_CSR_MEPC;
                            inst_addr <= ext_int_addr;    
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
    reg [`CSRAddrBus] csr_waddr;
    reg [`CSRDataBus] csr_wdata;


    //发出中断信号前，暂停流水线，写CSR寄存器
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            csr_we <= `Disable;
            csr_waddr <= 12'b0;
            csr_wdata <= `ZeroWord;
        end else begin
            case(csr_state)
                //将mepc寄存器的值设为当前指令地址
                S_CSR_MEPC: begin
                    csr_we <= `Enable;
                    csr_waddr <= `CSR_Addr_MEPC;
                    csr_wdata <= inst_addr;
                end
                //关闭全局中断
                S_CSR_MSTATUS: begin
                    csr_we <= `Enable;
                    csr_waddr <= `CSR_Addr_MSTATUS;
                    csr_wdata <= {I_csr_mstatus[31:8], I_csr_mstatus[3], I_csr_mstatus[6:4], 1'b0, I_csr_mstatus[2:0]};
                end
                //写中断产生的原因
                S_CSR_MCAUSE: begin
                    csr_we <= `Enable;
                    csr_waddr <= `CSR_Addr_MCAUSE;
                    csr_wdata <= cause;
                end
                //中断返回
                S_CSR_MSTATUS_MRET: begin
                    csr_we <= `Enable;
                    csr_waddr <= `CSR_Addr_MSTATUS;
                    csr_wdata <= {I_csr_mstatus[31:8], 1'b1, I_csr_mstatus[6:4], I_csr_mstatus[7], I_csr_mstatus[2:0]};
                end
                default: begin
                    csr_we <= `Disable;
                    csr_waddr <= 12'b0;
                    csr_wdata <= `ZeroWord;
                end
            endcase
        end
    end

    //------------------------------------------------------------------------
    // 输出
    //------------------------------------------------------------------------

    assign O_csr_we = csr_we;
    assign O_csr_waddr = csr_waddr;
    assign O_csr_wdata = csr_wdata;

    assign O_stallreq = (int_state != S_INT_IDLE) | (csr_state != S_CSR_IDLE);
    assign O_flush = (csr_state == S_CSR_MCAUSE) | (csr_state == S_CSR_MSTATUS_MRET);
    assign O_flush_addr = (csr_state == S_CSR_MCAUSE)? I_csr_mtvec:
                        (csr_state == S_CSR_MSTATUS_MRET)? I_csr_mepc:
                        `ZeroWord;

endmodule
