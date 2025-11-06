`include "defines.v"

module lsu_wbu 
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire    [`InstBus       ]   inst_i,             //指令内容
    input   wire    [`InstAddrBus   ]   inst_addr_i,        //指令地址
    input   wire                        reg_we_i, 
    input   wire    [`RegAddrBus    ]   reg_waddr_i,
    input   wire    [`RegBus        ]   reg_wdata_i,               
    input   wire                        csr_we_i,           //写CSR寄存器标志
    input   wire    [`MemAddrBus    ]   csr_waddr_i,        //写CSR寄存器地址
    input   wire    [`RegBus        ]   csr_wdata_i,        //写CSR寄存器数据


    output  reg     [`InstBus       ]   inst_o,             //指令内容
    output  reg     [`InstAddrBus   ]   inst_addr_o,        //指令地址
    output  reg                         reg_we_o, 
    output  reg     [`RegAddrBus    ]   reg_waddr_o,
    output  reg     [`RegBus        ]   reg_wdata_o,
    output  reg                         csr_we_o,           //写CSR寄存器标志
    output  reg     [`MemAddrBus    ]   csr_waddr_o,        //写CSR寄存器地址
    output  reg     [`RegBus        ]   csr_wdata_o,        //写CSR寄存器数据

    input   wire    [`StallBus      ]   stall_i,            //流水线暂停标志
    input   wire                        flush_i             //指令冲刷

);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            inst_o      <= 'b0;
            inst_addr_o <= 'b0;
            reg_we_o    <= 'b0;
            reg_waddr_o <= 'b0;
            reg_wdata_o <= 'b0;
            csr_we_o    <= 'b0;
            csr_waddr_o <= 'b0;
            csr_wdata_o <= 'b0;
        end else if((stall_i[`Stall_ls_wb] == `Stop) && 
                    (stall_i[`Stall_wb] == `NoStop) ||
                    (flush_i == `Enable)) begin
            inst_o      <= 'b0;
            inst_addr_o <= 'b0;
            reg_we_o    <= 'b0;
            reg_waddr_o <= 'b0;
            reg_wdata_o <= 'b0;
            csr_we_o    <= 'b0;
            csr_waddr_o <= 'b0;
            csr_wdata_o <= 'b0;
        end else if(stall_i[`Stall_ls_wb] == `NoStop) begin
            inst_o      <= inst_i;
            inst_addr_o <= inst_addr_i;
            reg_we_o    <= reg_we_i;
            reg_waddr_o <= reg_waddr_i;
            reg_wdata_o <= reg_wdata_i;
            csr_we_o    <= csr_we_i;
            csr_waddr_o <= csr_waddr_i;
            csr_wdata_o <= csr_wdata_i;
        end
    end

endmodule