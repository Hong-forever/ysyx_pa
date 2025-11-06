`include "defines.v"

module idu_exu
(
    input   wire                        clk,
    input   wire                        rst_n,

    input   wire    [`InstBus       ]   inst_i,             //指令内容
    input   wire    [`InstAddrBus   ]   inst_addr_i,        //指令地址
    input   wire    [`RegBus        ]   reg1_rdata_i,       //通用寄存器1读数据
    input   wire    [`RegBus        ]   reg2_rdata_i,       //通用寄存器2读数据
    input   wire                        reg_we_i,           //写通用寄存器标志
    input   wire    [`RegAddrBus    ]   reg_waddr_i,        //写通用寄存器地址
    input   wire                        csr_we_i,           //写CSR寄存器标志
    input   wire    [`MemAddrBus    ]   csr_waddr_i,        //写CSR寄存器地址
    input   wire    [`RegBus        ]   csr_rdata_i,        //CSR寄存器读数据
    input   wire    [`CSRCRL_WIDTH-1:0] CSRCtrl_i,
    input   wire    [`ALUCTL_WIDTH-1:0] ALUCtrl_i,          //ALU控制信号
    input   wire    [`MemAddrBus    ]   offset_memory_i,    //访存地址偏置
    input   wire                        ls_valid_i,         //访存有效标志
    input   wire    [`ls_diff_bus   ]   ls_type_i,          //访存类型，最高位为0时，访存类型为load，最高位为1时，访存类型为store
    input   wire    [`InstAddrBus   ]   link_addr_i,        //转移指令要保存的返回地址

    output  reg     [`InstBus       ]   inst_o,             //指令内容
    output  reg     [`InstAddrBus   ]   inst_addr_o,        //指令地址
    output  reg     [`RegBus        ]   reg1_rdata_o,       //通用寄存器1读数据
    output  reg     [`RegBus        ]   reg2_rdata_o,       //通用寄存器2读数据
    output  reg                         reg_we_o,           //写通用寄存器标志
    output  reg     [`RegAddrBus    ]   reg_waddr_o,        //写通用寄存器地址
    output  reg                         csr_we_o,           //写CSR寄存器标志
    output  reg     [`MemAddrBus    ]   csr_waddr_o,        //写CSR寄存器地址
    output  reg     [`RegBus        ]   csr_rdata_o,        //CSR寄存器读数据
    output  reg     [`CSRCRL_WIDTH-1:0] CSRCtrl_o,
    output  reg     [`ALUCTL_WIDTH-1:0] ALUCtrl_o,          //ALU控制信号
    output  reg     [`MemAddrBus    ]   offset_memory_o,    //访存地址偏置
    output  reg                         ls_valid_o,         //访存有效标志
    output  reg     [`ls_diff_bus   ]   ls_type_o,          //访存有效标志
    output  reg     [`InstAddrBus   ]   link_addr_o,        //转移指令要保存的返回地址

    input   wire    [`StallBus      ]   stall_i,            //流水线暂停标志
    input   wire                        flush_i             //指令冲刷

);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            inst_o          <= 'b0;
            inst_addr_o     <= 'b0;
            reg1_rdata_o    <= 'b0;
            reg2_rdata_o    <= 'b0;
            reg_we_o        <= 'b0;
            reg_waddr_o     <= 'b0;
            csr_we_o        <= 'b0;
            csr_waddr_o     <= 'b0;
            csr_rdata_o     <= 'b0;
            CSRCtrl_o       <= 'b0;
            ALUCtrl_o       <= 'b0;
            offset_memory_o <= 'b0;
            ls_valid_o      <= 'b0;
            ls_type_o       <= 'b0;
            link_addr_o     <= 'b0;
        end else if((stall_i[`Stall_dec_ex] == `Stop) &&
                    (stall_i[`Stall_ex_ls] == `NoStop) ||
                    (flush_i == `Enable)) begin
            inst_o          <= 'b0;
            inst_addr_o     <= 'b0;
            reg1_rdata_o    <= 'b0;
            reg2_rdata_o    <= 'b0;
            reg_we_o        <= 'b0;
            reg_waddr_o     <= 'b0;
            csr_we_o        <= 'b0;
            csr_waddr_o     <= 'b0;
            csr_rdata_o     <= 'b0;
            CSRCtrl_o       <= 'b0;
            ALUCtrl_o       <= 'b0;
            offset_memory_o <= 'b0;
            ls_valid_o      <= 'b0;
            ls_type_o       <= 'b0;
            link_addr_o     <= 'b0;
        end else if(stall_i[`Stall_dec_ex] == `NoStop) begin
            inst_o          <= inst_i;
            inst_addr_o     <= inst_addr_i;
            reg1_rdata_o    <= reg1_rdata_i;
            reg2_rdata_o    <= reg2_rdata_i;
            reg_we_o        <= reg_we_i;
            reg_waddr_o     <= reg_waddr_i;
            csr_we_o        <= csr_we_i;
            csr_waddr_o     <= csr_waddr_i;
            csr_rdata_o     <= csr_rdata_i;
            CSRCtrl_o       <= CSRCtrl_i;
            ALUCtrl_o       <= ALUCtrl_i;
            offset_memory_o <= offset_memory_i;
            ls_valid_o      <= ls_valid_i;
            ls_type_o       <= ls_type_i;
            link_addr_o     <= link_addr_i;
        end
    end

endmodule //idu_exu
