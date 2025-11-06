`include "defines.v"

//------------------------------------------------------------------------
// 访存单元
//------------------------------------------------------------------------

module lsu
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`InstBus       ]   I_inst,             //指令内容
    input   wire    [`InstAddrBus   ]   I_inst_addr,
    input   wire                        I_rd_we,
    input   wire    [`RegAddrBus    ]   I_rd_waddr,
    input   wire    [`RegDataBus    ]   I_rd_wdata,
    input   wire    [`MemAddrBus    ]   I_memory_addr,
    input   wire    [`MemDataBus    ]   I_store_data,
    input   wire                        I_ls_valid,
    input   wire    [`ls_diff_bus   ]   I_ls_type,
    input   wire                        I_csr_we,
    input   wire    [`CSRAddrBus    ]   I_csr_waddr,
    input   wire    [`CSRDataBus    ]   I_csr_wdata,

    output  wire    [`InstBus       ]   O_inst,
    output  wire    [`InstAddrBus   ]   O_inst_addr,
    output  wire                        O_rd_we,
    output  wire    [`RegAddrBus    ]   O_rd_waddr,
    output  wire    [`RegDataBus    ]   O_rd_wdata,
    output  wire                        O_csr_we,
    output  wire    [`CSRAddrBus    ]   O_csr_waddr,
    output  wire    [`CSRDataBus    ]   O_csr_wdata,

    output  wire                        O_stallreq,

    //to bus
    output  wire                        O_dbus_req,
    output  wire                        O_dbus_we,
    output  wire    [`MemAddrBus    ]   O_dbus_addr,
    input   wire    [`MemDataBus    ]   I_dbus_data,
    output  wire    [`MemDataBus    ]   O_dbus_data,
    output  wire    [`DBUS_MASK-1:0 ]   O_dbus_mask
);

    //------------------------------------------------------------------------
    // 存取结果
    //------------------------------------------------------------------------
    wire [`MemDataBus] lb_00_res = {{24{I_dbus_data[7]}},  I_dbus_data[7:0]};
    wire [`MemDataBus] lb_01_res = {{24{I_dbus_data[15]}}, I_dbus_data[15:8]};
    wire [`MemDataBus] lb_10_res = {{24{I_dbus_data[23]}}, I_dbus_data[23:16]};
    wire [`MemDataBus] lb_11_res = {{24{I_dbus_data[31]}}, I_dbus_data[31:24]};

    wire [`MemDataBus] lh_00_res = {{16{I_dbus_data[15]}}, I_dbus_data[15:0]};
    wire [`MemDataBus] lh_10_res = {{16{I_dbus_data[31]}}, I_dbus_data[31:16]};

    wire [`MemDataBus] lw_res = I_dbus_data;

    wire [`MemDataBus] lbu_00_res = {{24{1'b0}}, I_dbus_data[7:0]};
    wire [`MemDataBus] lbu_01_res = {{24{1'b0}}, I_dbus_data[15:8]};
    wire [`MemDataBus] lbu_10_res = {{24{1'b0}}, I_dbus_data[23:16]};
    wire [`MemDataBus] lbu_11_res = {{24{1'b0}}, I_dbus_data[31:24]};

    wire [`MemDataBus] lhu_00_res = {{16{1'b0}}, I_dbus_data[15:0]};
    wire [`MemDataBus] lhu_10_res = {{16{1'b0}}, I_dbus_data[31:16]};

    wire [`MemDataBus] sb_00_res = {24'b0, I_store_data[7:0]};
    wire [`MemDataBus] sb_01_res = {16'b0, I_store_data[7:0], 8'b0};
    wire [`MemDataBus] sb_10_res = {8'b0, I_store_data[7:0], 16'b0};
    wire [`MemDataBus] sb_11_res = {I_store_data[7:0], 24'b0};

    wire [`MemDataBus] sh_00_res = {16'b0, I_store_data[15:0]};
    wire [`MemDataBus] sh_10_res = {I_store_data[15:0], 16'b0};

    wire [`MemDataBus] sw_res = I_store_data;

    // 地址明辨
    wire [1:0] memory_byte_addr = I_memory_addr[1:0];

    //------------------------------------------------------------------------
    // 访存逻辑
    //------------------------------------------------------------------------
    reg [`RegDataBus] rd_data;
    always @(*) begin
        rd_data = I_rd_wdata;
        case(I_ls_type)
            `ls_lb: begin
                case(memory_byte_addr)
                    2'b00: rd_data = lb_00_res;
                    2'b01: rd_data = lb_01_res;
                    2'b10: rd_data = lb_10_res;
                    2'b11: rd_data = lb_11_res;
                    default: begin end
                endcase
            end
            `ls_lh: begin
                case(memory_byte_addr[1])
                    1'b0: rd_data = lh_00_res;
                    1'b1: rd_data = lh_10_res;
                    default: begin end
                endcase
            end
            `ls_lw: begin
                rd_data = lw_res;
            end
            `ls_lbu: begin
                case(memory_byte_addr)
                    2'b00: rd_data = lbu_00_res;
                    2'b01: rd_data = lbu_01_res;
                    2'b10: rd_data = lbu_10_res;
                    2'b11: rd_data = lbu_11_res;
                    default: begin end
                endcase
            end
            `ls_lhu: begin
                case(memory_byte_addr[1])
                    1'b0: rd_data = lhu_00_res;
                    1'b1: rd_data = lhu_10_res;
                    default: begin end
                endcase
            end
            default: begin end
        endcase
    end

    //------------------------------------------------------------------------
    // 存储逻辑
    //------------------------------------------------------------------------
    reg [`MemDataBus] dbus_data;
    always @(*) begin
        dbus_data = `ZeroWord;
        case(I_ls_type)
            `ls_sb: begin
                case(memory_byte_addr)
                    2'b00: dbus_data = sb_00_res;
                    2'b01: dbus_data = sb_01_res;
                    2'b10: dbus_data = sb_10_res;
                    2'b11: dbus_data = sb_11_res;
                    default: begin end
                endcase
            end
            `ls_sh: begin
                case(memory_byte_addr[1])
                    1'b0: dbus_data = sh_00_res;
                    1'b1: dbus_data = sh_10_res;
                    default: begin end
                endcase
            end
            `ls_sw: begin
                dbus_data = sw_res;
            end
            default: begin end
        endcase
    end

    //------------------------------------------------------------------------
    // 字节选通
    //------------------------------------------------------------------------

    reg [`DBUS_MASK-1:0] dbus_mask;
    always @(*) begin
        dbus_mask = 'b0000;
        case(I_ls_type)
            `ls_lb, `ls_lbu, `ls_sb: begin
                case(memory_byte_addr)
                    2'b00: dbus_mask = 4'b0001;
                    2'b01: dbus_mask = 4'b0010;
                    2'b10: dbus_mask = 4'b0100;
                    2'b11: dbus_mask = 4'b1000;
                    default: begin end
                endcase
            end
            `ls_lh, `ls_lhu, `ls_sh: begin
                case(memory_byte_addr[1])
                    1'b0: dbus_mask = 4'b0011;
                    1'b1: dbus_mask = 4'b1100;
                    default: begin end
                endcase
            end
            `ls_lw, `ls_sw: begin
                dbus_mask = 4'b1111;
            end
            default: begin end
        endcase
    end


    //------------------------------------------------------------------------
    // 输出
    //------------------------------------------------------------------------
    assign O_inst = I_inst;
    assign O_inst_addr = I_inst_addr;
    assign O_rd_we = I_rd_we;
    assign O_rd_waddr = I_rd_waddr;
    assign O_rd_wdata = rd_data;

    assign O_csr_we = I_csr_we;
    assign O_csr_waddr = I_csr_waddr;
    assign O_csr_wdata = I_csr_wdata;

    assign O_dbus_req = I_ls_valid;
    assign O_dbus_we = I_ls_type[`ls_diff_width-1];
    assign O_dbus_addr = I_memory_addr;
    assign O_dbus_mask = dbus_mask;

    assign O_dbus_data = dbus_data;

    assign O_stallreq = 1'b0;

endmodule