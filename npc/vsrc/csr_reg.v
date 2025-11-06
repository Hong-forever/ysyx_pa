`include "defines.v"

//------------------------------------------------------------------------
// CSR寄存器
//------------------------------------------------------------------------

module csr_reg
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`CSRAddrBus    ]   I_raddr,
    output  wire    [`CSRDataBus    ]   O_rdata,

    input   wire                        I_we,
    input   wire    [`CSRAddrBus    ]   I_waddr,
    input   wire    [`CSRDataBus    ]   I_wdata,

    input   wire                        I_clint_we,           //写CSR寄存器标志
    input   wire    [`CSRAddrBus    ]   I_clint_waddr,        //写CSR寄存器地址
    input   wire    [`CSRDataBus    ]   I_clint_wdata,        //写CSR寄存器数据

    output  wire    [`CSRDataBus    ]   O_csr_mtvec,        //mtvec寄存器
    output  wire    [`CSRDataBus    ]   O_csr_mepc,         //mepc寄存器
    output  wire    [`CSRDataBus    ]   O_csr_mstatus,      //mstatus寄存器
    output  wire                        O_global_int_en      //全局中断使能标志

);

    reg [`CSRDataBus] mstatus;
    reg [`CSRDataBus] mie;
    reg [`CSRDataBus] mtvec;
    reg [`CSRDataBus] mscratch;
    reg [`CSRDataBus] mepc;
    reg [`CSRDataBus] mcause;
    // reg [`DoubleCSRDataBus] mtimecmp;   //未定义地址，未实现
    reg [`DoubleCSRDataBus] cycle;


    //cycle counter
    //复位撤销后就一直计数
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            cycle <= {`ZeroWord, `ZeroWord};
        end else begin
            cycle <= cycle + 1'b1;
        end
    end

    // reg csr_timer_int;
    // always @(posedge clk or posedge rst) begin
    //     if(rst) begin
    //         csr_timer_int <= `INT_DEASSERT;
    //     end else begin
    //         if(mtimecmp != {`ZeroWord, `ZeroWord} && cycle == mtimecmp) begin
    //             csr_timer_int <= `INT_ASSERT;
    //         end
    //     end
    // end

    //write reg
    //写寄存器操作
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            mtvec <= `ZeroWord;
            mcause <= `ZeroWord;
            mepc <= `ZeroWord;
            mie <= `ZeroWord;
            mstatus <= `ZeroWord;
            mscratch <= `ZeroWord;
        end else begin
            if(I_clint_we) begin
                case(I_clint_waddr)
                    `CSR_Addr_MSTATUS:  mstatus     <= I_clint_wdata;
                    `CSR_Addr_MIE:      mie         <= I_clint_wdata;
                    `CSR_Addr_MTVEC:    mtvec       <= I_clint_wdata;
                    `CSR_Addr_MSCRATCH: mscratch    <= I_clint_wdata;
                    `CSR_Addr_MEPC:     mepc        <= I_clint_wdata;
                    `CSR_Addr_MCAUSE:   mcause      <= I_clint_wdata;
                    default: begin end
                endcase
            end else begin    
                if(I_we) begin
                    case(I_waddr)
                        `CSR_Addr_MSTATUS:  mstatus     <= I_wdata;
                        `CSR_Addr_MIE:      mie         <= I_wdata;
                        `CSR_Addr_MTVEC:    mtvec       <= I_wdata;
                        `CSR_Addr_MSCRATCH: mscratch    <= I_wdata;
                        `CSR_Addr_MEPC:     mepc        <= I_wdata;
                        `CSR_Addr_MCAUSE:   mcause      <= I_wdata;
                        default: begin end
                    endcase
                end
            end
        end
    end


    //read reg
    //idu模块读CSR寄存器
    reg [`CSRDataBus]   rdata1;
    always @(*) begin
        if(I_we && I_raddr == I_waddr) begin
            rdata1 = I_wdata;
        end else begin
            case(I_raddr)
                `CSR_Addr_MSTATUS:  rdata1 = mstatus;
                `CSR_Addr_MIE:      rdata1 = mie;
                `CSR_Addr_MTVEC:    rdata1 = mtvec;
                `CSR_Addr_MSCRATCH: rdata1 = mscratch;
                `CSR_Addr_MEPC:     rdata1 = mepc;
                `CSR_Addr_MCAUSE:   rdata1 = mcause;
                `CSR_Addr_CYCLE:    rdata1 = cycle[31:0];
                `CSR_Addr_CYCLEH:   rdata1 = cycle[63:32];
                default:            rdata1 = `ZeroWord;
            endcase
        end
    end


    //------------------------------------------------------------------------
    // 输出
    //------------------------------------------------------------------------
    assign O_rdata = rdata1;

    assign O_csr_mtvec = mtvec;
    assign O_csr_mepc = mepc;
    assign O_csr_mstatus = mstatus;

    assign O_global_int_en = mstatus[3]; //mstatus[3]为mie域，全局中断使能位

endmodule
