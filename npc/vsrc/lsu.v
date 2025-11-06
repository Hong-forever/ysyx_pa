`include "defines.v"

module lsu
(
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

    //to wbu(regfile)
    output  wire    [`InstBus       ]   inst_o,                 //指令内容
    output  wire    [`InstAddrBus   ]   inst_addr_o,            //指令地址
    output  wire                        reg_we_o,
    output  wire    [`RegAddrBus    ]   reg_waddr_o,
    output  wire    [`RegBus        ]   reg_wdata_o,

    //to csr
    output  wire                        csr_we_o,               //写CSR寄存器标志
    output  wire    [`MemAddrBus    ]   csr_waddr_o,            //写CSR寄存器地址
    output  wire    [`RegBus        ]   csr_wdata_o,            //写CSR寄存器数据

    //to bus
    output  wire                        dbus_req_o,
    output  wire                        dbus_we_o,
    output  wire    [`InstAddrBus   ]   dbus_addr_o,
    input   wire    [`InstBus       ]   dbus_data_i,
    output  wire    [`InstBus       ]   dbus_data_o,
    output  wire    [`ByteSel-1:0   ]   dbus_sel_o
);



    //*********************// 存取结果 //*********************//
    wire [`MemBus] rv32i_lb_00_res = {{24{dbus_data_i[7]}},  dbus_data_i[7:0]};
    wire [`MemBus] rv32i_lb_01_res = {{24{dbus_data_i[15]}}, dbus_data_i[15:8]};
    wire [`MemBus] rv32i_lb_10_res = {{24{dbus_data_i[23]}}, dbus_data_i[23:16]};
    wire [`MemBus] rv32i_lb_11_res = {{24{dbus_data_i[31]}}, dbus_data_i[31:24]};

    wire [`MemBus] rv32i_lh_00_res = {{16{dbus_data_i[15]}}, dbus_data_i[15:0]};
    wire [`MemBus] rv32i_lh_10_res = {{16{dbus_data_i[31]}}, dbus_data_i[31:16]};

    wire [`MemBus] rv32i_lw_res = dbus_data_i;

    wire [`MemBus] rv32i_lbu_00_res = {{24{1'b0}}, dbus_data_i[7:0]};
    wire [`MemBus] rv32i_lbu_01_res = {{24{1'b0}}, dbus_data_i[15:8]};
    wire [`MemBus] rv32i_lbu_10_res = {{24{1'b0}}, dbus_data_i[23:16]};
    wire [`MemBus] rv32i_lbu_11_res = {{24{1'b0}}, dbus_data_i[31:24]};

    wire [`MemBus] rv32i_lhu_00_res = {{16{1'b0}}, dbus_data_i[15:0]};
    wire [`MemBus] rv32i_lhu_10_res = {{16{1'b0}}, dbus_data_i[31:16]};

    wire [`MemBus] rv32i_sb_00_res = {24'b0, store_data_i[7:0]};
    wire [`MemBus] rv32i_sb_01_res = {16'b0, store_data_i[7:0], 8'b0};
    wire [`MemBus] rv32i_sb_10_res = {8'b0, store_data_i[7:0], 16'b0};
    wire [`MemBus] rv32i_sb_11_res = {store_data_i[7:0], 24'b0};

    wire [`MemBus] rv32i_sh_00_res = {16'b0, store_data_i[15:0]};
    wire [`MemBus] rv32i_sh_10_res = {store_data_i[15:0], 16'b0};

    wire [`MemBus] rv32i_sw_res = store_data_i;

    //地址明辨
    wire [1:0] memory_byte_addr = memory_addr_i[1:0];


    //*********************// 访存使能 //*********************//
    wire dbus_req = ls_valid_i;

    //*********************// 访存逻辑 //*********************//
    reg [`RegBus] reg_data;
    always @(*) begin
        reg_data = reg_wdata_i;
        case(ls_type_i)
            `ls_lb: begin
                case(memory_byte_addr)
                    2'b00: reg_data = rv32i_lb_00_res;
                    2'b01: reg_data = rv32i_lb_01_res;
                    2'b10: reg_data = rv32i_lb_10_res;
                    2'b11: reg_data = rv32i_lb_11_res;
                    default: begin end
                endcase
            end
            `ls_lh: begin
                case(memory_byte_addr)
                    2'b00: reg_data = rv32i_lh_00_res;
                    2'b10: reg_data = rv32i_lh_10_res;
                    default: begin end
                endcase
            end
            `ls_lw: begin
                reg_data = rv32i_lw_res;
            end
            `ls_lbu: begin
                case(memory_byte_addr)
                    2'b00: reg_data = rv32i_lbu_00_res;
                    2'b01: reg_data = rv32i_lbu_01_res;
                    2'b10: reg_data = rv32i_lbu_10_res;
                    2'b11: reg_data = rv32i_lbu_11_res;
                    default: begin end
                endcase
            end
            `ls_lhu: begin
                case(memory_byte_addr)
                    2'b00: reg_data = rv32i_lhu_00_res;
                    2'b10: reg_data = rv32i_lhu_10_res;
                    default: begin end
                endcase
            end
            default: begin end
        endcase
    end
    //*********************// 存储使能逻辑 //*********************//
    wire dbus_we = ls_type_i[`ls_diff_width-1];

    //*********************// 存储逻辑 //*********************//
    reg [`MemBus] dbus_data;
    always @(*) begin
        dbus_data = `ZeroWord;
        case(ls_type_i)
            `ls_sb: begin
                case(memory_byte_addr)
                    2'b00: dbus_data = rv32i_sb_00_res;
                    2'b01: dbus_data = rv32i_sb_01_res;
                    2'b10: dbus_data = rv32i_sb_10_res;
                    2'b11: dbus_data = rv32i_sb_11_res;
                    default: begin end
                endcase
            end
            `ls_sh: begin
                case(memory_byte_addr)
                    2'b00: dbus_data = rv32i_sh_00_res;
                    2'b10: dbus_data = rv32i_sh_10_res;
                    default: begin end
                endcase
            end
            `ls_sw: begin
                dbus_data = rv32i_sw_res;
            end
            default: begin end
        endcase
    end

    //*********************// 字节选通 //*********************//
    // reg [`ByteSel-1:0] dbus_sel;
    // always @(*) begin
    //     dbus_sel = 'b00;
    //     case(ls_type_i)
    //         `ls_lb, `ls_lbu, `ls_sb: begin
    //             dbus_sel = 2'b00;
    //         end
    //         `ls_lh, `ls_lhu, `ls_sh: begin
    //             dbus_sel = 2'b01;
    //         end
    //         `ls_lw, `ls_sw: begin
    //             dbus_sel = 2'b10;
    //         end
    //         default: begin end
    //     endcase
    // end
    reg [`ByteSel-1:0] dbus_sel;
    always @(*) begin
        case(ls_type_i)
            `ls_lb, `ls_lbu, `ls_sb: begin
                case(memory_byte_addr)
                    2'b00: dbus_sel = 'b0001;
                    2'b01: dbus_sel = 'b0010;
                    2'b10: dbus_sel = 'b0100;
                    2'b11: dbus_sel = 'b1000;
                    default: begin end
                endcase
            end
            `ls_lh, `ls_lhu, `ls_sh: begin
                case(memory_byte_addr)
                    2'b00: dbus_sel = 'b0011;
                    2'b10: dbus_sel = 'b1100;
                    default: begin end
                endcase
            end
            `ls_lw, `ls_sw: begin
                dbus_sel = 'b1111;
            end
            default: begin
                dbus_sel = 'b0000;
            end
        endcase
    end

    //*********************// 输出 //*********************//
    assign inst_o = inst_i;
    assign inst_addr_o = inst_addr_i;
    assign reg_we_o = reg_we_i;
    assign reg_waddr_o = reg_waddr_i;
    assign reg_wdata_o = reg_data;

    assign csr_we_o = csr_we_i;
    assign csr_waddr_o = csr_waddr_i;
    assign csr_wdata_o = csr_wdata_i;

    assign dbus_req_o = dbus_req;
    assign dbus_we_o = dbus_we;
    assign dbus_addr_o = memory_addr_i;
    assign dbus_data_o = dbus_data;
    assign dbus_sel_o = dbus_sel;

endmodule //lsu
