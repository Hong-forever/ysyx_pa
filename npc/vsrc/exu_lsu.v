`include "defines.v"

module exu_lsu
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire    [`InstBus       ]   inst_i,             //指令内容
    input   wire    [`InstAddrBus   ]   inst_addr_i,
    input   wire                        reg_we_i,
    input   wire    [`RegAddrBus    ]   reg_waddr_i,
    input   wire    [`RegBus        ]   reg_wdata_i,
    input   wire    [`MemAddrBus    ]   memory_addr_i,
    input   wire    [`MemBus        ]   store_data_i,
    input   wire                        ls_valid_i,         //访存有效标志
    input   wire    [`ls_diff_bus   ]   ls_type_i,

    input   wire                        csr_we_i,           //写CSR寄存器标志
    input   wire    [`MemAddrBus    ]   csr_waddr_i,        //写CSR寄存器地址
    input   wire    [`RegBus        ]   csr_wdata_i,        //写CSR寄存器数据

    output  reg     [`InstBus       ]   inst_o,             //指令内容
    output  reg     [`InstAddrBus   ]   inst_addr_o,        //指令地址
    output  reg                         reg_we_o,
    output  reg     [`RegAddrBus    ]   reg_waddr_o,
    output  reg     [`RegBus        ]   reg_wdata_o,
    output  reg     [`MemAddrBus    ]   memory_addr_o,
    output  reg     [`MemBus        ]   store_data_o,
    output  reg                         ls_valid_o,         //访存有效标志
    output  reg     [`ls_diff_bus   ]   ls_type_o,

    output  reg                         csr_we_o,           //写CSR寄存器标志
    output  reg     [`MemAddrBus    ]   csr_waddr_o,        //写CSR寄存器地址
    output  reg     [`RegBus        ]   csr_wdata_o,        //写CSR寄存器数据

    input   wire    [`StallBus      ]   stall_i,            //流水线暂停标志
    input   wire                        flush_i             //指令冲刷

);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            inst_o        <= 'b0;
            inst_addr_o   <= 'b0;
            reg_we_o      <= 'b0;
            reg_waddr_o   <= 'b0;
            reg_wdata_o   <= 'b0;
            memory_addr_o <= 'b0;
            store_data_o  <= 'b0;
            ls_valid_o    <= 'b0;
            ls_type_o     <= 'b0;
            csr_we_o      <= 'b0;
            csr_waddr_o   <= 'b0;
            csr_wdata_o   <= 'b0;
        end else if((stall_i[`Stall_ex_ls] == `Stop) &&
                    (stall_i[`Stall_ls_wb] == `NoStop) ||
                    (flush_i == `Enable)) begin
            //流水线ex阶段暂停，mem阶段继续，插入空指令进入lsu
            //或者遇到异常后进行冲刷
            inst_o        <= 'b0;
            inst_addr_o   <= 'b0;
            reg_we_o      <= 'b0;
            reg_waddr_o   <= 'b0;
            reg_wdata_o   <= 'b0;
            memory_addr_o <= 'b0;
            store_data_o  <= 'b0;
            ls_valid_o    <= 'b0;
            ls_type_o     <= 'b0;
            csr_we_o      <= 'b0;
            csr_waddr_o   <= 'b0;
            csr_wdata_o   <= 'b0;
        end else if(stall_i[`Stall_ex_ls] == `NoStop) begin
            inst_o        <= inst_i;
            inst_addr_o   <= inst_addr_i;
            reg_we_o      <= reg_we_i;
            reg_waddr_o   <= reg_waddr_i;
            reg_wdata_o   <= reg_wdata_i;
            memory_addr_o <= memory_addr_i;
            store_data_o  <= store_data_i;
            ls_valid_o    <= ls_valid_i;
            ls_type_o     <= ls_type_i;
            csr_we_o      <= csr_we_i;
            csr_waddr_o   <= csr_waddr_i;
            csr_wdata_o   <= csr_wdata_i;
        end
    end

endmodule //exu_lsu