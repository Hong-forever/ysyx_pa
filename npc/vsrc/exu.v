`include "defines.v"

module exu
(
    input   wire    rst_n,

    //from idu_exu
    input   wire    [`InstBus       ]   inst_i,
    input   wire    [`InstAddrBus   ]   inst_addr_i,

    input   wire    [`RegBus        ]   reg1_rdata_i,
    input   wire    [`RegBus        ]   reg2_rdata_i,
    input   wire                        reg_we_i,
    input   wire    [`RegAddrBus    ]   reg_waddr_i,
    input   wire                        csr_we_i,
    input   wire    [`MemAddrBus    ]   csr_waddr_i,
    input   wire    [`RegBus        ]   csr_rdata_i,
    input   wire    [`CSRCRL_WIDTH-1:0] CSRCtrl_i,
    input   wire    [`ALUCTL_WIDTH-1:0] ALUCtrl_i,
    input   wire    [`MemAddrBus    ]   offset_memory_i,    //IL or S type 需要访问的数据寄存器地址偏移量，即是imm
    input   wire                        ls_valid_i,         //访存有效标志
    input   wire    [`ls_diff_bus   ]   ls_type_i,
    input   wire    [`RegBus        ]   link_addr_i,        //jal和jalr指令的链接地址

    //to exu_lsu
    output  wire    [`InstBus       ]   inst_o,
    output  wire    [`InstAddrBus   ]   inst_addr_o,
    output  wire                        reg_we_o,
    output  wire    [`RegAddrBus    ]   reg_waddr_o,
    output  wire    [`RegBus        ]   reg_wdata_o,
    output  wire    [`MemAddrBus    ]   memory_addr_o,
    output  wire    [`MemBus        ]   store_data_o,
    output  wire                        ls_valid_o,         //访存有效标志
    output  wire    [`ls_diff_bus   ]   ls_type_o,

    output  wire                        csr_we_o,
    output  wire    [`MemAddrBus    ]   csr_waddr_o,
    output  wire    [`RegBus        ]   csr_wdata_o,

    output  wire                        inst_is_load_o,       //解决load相关指令问题

    //to pipe_ctrl
    output  wire                        stallreq_o

);
    //*********************// alu运算 //*********************//
    wire is_add   = ALUCtrl_i == `ALUCTL_ADD;
    wire is_sub   = ALUCtrl_i == `ALUCTL_SUB;
    wire is_sll   = ALUCtrl_i == `ALUCTL_SLL;
    wire is_slt   = ALUCtrl_i == `ALUCTL_SLT;
    wire is_sltu  = ALUCtrl_i == `ALUCTL_SLTU;
    wire is_xor   = ALUCtrl_i == `ALUCTL_XOR;
    wire is_srl   = ALUCtrl_i == `ALUCTL_SRL;
    wire is_sra   = ALUCtrl_i == `ALUCTL_SRA;
    wire is_or    = ALUCtrl_i == `ALUCTL_OR;
    wire is_and   = ALUCtrl_i == `ALUCTL_AND;
    wire is_auipc = ALUCtrl_i == `ALUCTL_AUIPC;
    wire is_lui   = ALUCtrl_i == `ALUCTL_LUI;

    wire is_jal   = ALUCtrl_i == `ALUCTL_JAL;
    wire is_jalr  = ALUCtrl_i == `ALUCTL_JALR;

    wire is_lb    = ls_type_i == `ls_lb;
    wire is_lh    = ls_type_i == `ls_lh;
    wire is_lw    = ls_type_i == `ls_lw;
    wire is_lbu   = ls_type_i == `ls_lbu;
    wire is_lhu   = ls_type_i == `ls_lhu;
    wire is_sb    = ls_type_i == `ls_sb;
    wire is_sh    = ls_type_i == `ls_sh;
    wire is_sw    = ls_type_i == `ls_sw;

    wire is_csrwri = CSRCtrl_i == `CSRCTL_WRI;
    wire is_csrset = CSRCtrl_i == `CSRCTL_SET;
    wire is_csrclr = CSRCtrl_i == `CSRCTL_CLR;


    wire [`RegBus] rv32i_add_res   = reg1_rdata_i + reg2_rdata_i;
    wire [`RegBus] rv32i_sub_res   = reg1_rdata_i - reg2_rdata_i;
    wire [`RegBus] rv32i_sll_res   = reg1_rdata_i << reg2_rdata_i[4:0];
    wire [`RegBus] rv32i_slt_res   = {31'b0, ($signed(reg1_rdata_i) < $signed(reg2_rdata_i))};       //有符号数比较
    wire [`RegBus] rv32i_sltu_res  = {31'b0, (reg1_rdata_i < reg2_rdata_i)};        //无符号数比较
    wire [`RegBus] rv32i_xor_res   = reg1_rdata_i ^ reg2_rdata_i;
    wire [`RegBus] rv32i_srl_res   = reg1_rdata_i >> reg2_rdata_i[4:0];
    wire [`RegBus] rv32i_sra_res   = ($signed(reg1_rdata_i)) >>> reg2_rdata_i[4:0];
    wire [`RegBus] rv32i_or_res    = reg1_rdata_i | reg2_rdata_i;
    wire [`RegBus] rv32i_and_res   = reg1_rdata_i & reg2_rdata_i;
    wire [`RegBus] rv32i_lui_res   = reg2_rdata_i;
    wire [`RegBus] rv32i_auipc_res = reg2_rdata_i + inst_addr_i;
    wire [`RegBus] memory_addr_res = reg1_rdata_i + offset_memory_i;   //需要访问的数据寄存器地址计算结果
   
    wire [`RegBus] rv_csrrw_res    = reg1_rdata_i;
    wire [`RegBus] rv_csrrs_res    = csr_rdata_i | reg1_rdata_i;
    wire [`RegBus] rv_csrrc_res    = csr_rdata_i & (~reg1_rdata_i);


    reg [`RegBus] Result;
    always @(*) begin
        case(1'b1)
            //alu
            is_add:    Result = rv32i_add_res;
            is_sub:    Result = rv32i_sub_res;
            is_sll:    Result = rv32i_sll_res;
            is_slt:    Result = rv32i_slt_res;
            is_sltu:   Result = rv32i_sltu_res;
            is_xor:    Result = rv32i_xor_res;
            is_srl:    Result = rv32i_srl_res;
            is_sra:    Result = rv32i_sra_res;
            is_or:     Result = rv32i_or_res;
            is_and:    Result = rv32i_and_res;
            is_lui:    Result = rv32i_lui_res;
            is_auipc:  Result = rv32i_auipc_res;

            //branch, addr
            is_jal:    Result = link_addr_i;
            is_jalr:   Result = link_addr_i;

            //ls, addr
            is_lb:     Result = memory_addr_res;
            is_lh:     Result = memory_addr_res;
            is_lw:     Result = memory_addr_res;
            is_lbu:    Result = memory_addr_res;
            is_lhu:    Result = memory_addr_res;
            is_sb:     Result = memory_addr_res;
            is_sh:     Result = memory_addr_res;
            is_sw:     Result = memory_addr_res;

            //csr
            is_csrwri: Result = csr_rdata_i;
            is_csrset: Result = csr_rdata_i;
            is_csrclr: Result = csr_rdata_i;

            default:  Result = `ZeroWord;
        endcase
    end

    reg [`RegBus] csr_result;
    always @(*) begin
        case(1'b1)
            is_csrwri: csr_result = rv_csrrw_res;
            is_csrset: csr_result = rv_csrrs_res;
            is_csrclr: csr_result = rv_csrrc_res;
            default:  csr_result = `ZeroWord;
        endcase
    end


    //*********************// 输出 //*********************//
    assign inst_o = inst_i;
    assign inst_addr_o = inst_addr_i;

    assign reg_we_o = reg_we_i;
    assign reg_waddr_o = reg_waddr_i;
    assign reg_wdata_o = Result;
    assign memory_addr_o = Result;
    assign store_data_o = reg2_rdata_i;
    assign ls_valid_o = ls_valid_i;
    assign ls_type_o = ls_type_i;
    assign inst_is_load_o = ls_valid_i && !ls_type_i[`ls_diff_width-1];

    assign csr_we_o = csr_we_i;
    assign csr_waddr_o = csr_waddr_i;
    assign csr_wdata_o = csr_result;

    initial begin
        $monitor("exu================ ls_valid(%d) inst(0x%08x) pc(0x%08x)\n", ls_valid_o, inst_o, inst_addr_o);
    end

endmodule //exu
