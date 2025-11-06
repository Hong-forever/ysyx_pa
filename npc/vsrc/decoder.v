`include "defines.v"

//------------------------------------------------------------------------
// 译码单元
//------------------------------------------------------------------------

module decoder 
(
    input   wire                        clk,
    input   wire                        rst,

    input   wire    [`InstBus       ]   I_inst,
    input   wire    [`InstAddrBus   ]   I_inst_addr,

    output  wire    [`RegAddrBus    ]   O_rs1_raddr,        //regfiles读通用寄存器1地址
    output  wire    [`RegAddrBus    ]   O_rs2_raddr,        //regfiles读通用寄存器2地址       
    output  wire    [`CSRAddrBus    ]   O_csr_raddr,        //读CSR寄存器地址

    input   wire    [`RegDataBus    ]   I_rs1_rdata,        //获取通用寄存器1地址指向的数据
    input   wire    [`RegDataBus    ]   I_rs2_rdata,        //获取通用寄存器2地址指向的数据
    input   wire    [`CSRDataBus    ]   I_csr_rdata,        //CSR寄存器输入数据

    output  wire    [`InstBus       ]   O_inst,             //指令内容
    output  wire    [`InstAddrBus   ]   O_inst_addr,        //指令地址
    output  wire    [`RegDataBus    ]   O_rs1_rdata,        //通用寄存器1数据
    output  wire    [`RegDataBus    ]   O_rs2_rdata,        //通用寄存器2数据
    output  wire    [`RegDataBus    ]   O_imm,              //立即数
    output  wire                        O_rd_we,            //写通用寄存器标志
    output  wire    [`RegAddrBus    ]   O_rd_waddr,         //写通用寄存器地址
    output  wire                        O_csr_we,           //写CSR寄存器标志
    output  wire    [`CSRAddrBus    ]   O_csr_waddr,        //写CSR寄存器地址
    output  wire    [`CSRDataBus    ]   O_csr_rdata,        //CSR寄存器数据

    output  wire    [`CSRCTL_WIDTH-1:0] O_CSRCtrl,
    output  wire    [`ALUCTL_WIDTH-1:0] O_ALUCtrl,          //ALU控制信号
    output  wire    [`BRUCTL_WIDTH-1:0] O_BRUCtrl,          //BRU控制信号
    output  wire    [`ALUSrcA_sel_width-1:0] O_ALUSrcA_sel,
    output  wire    [`ALUSrcB_sel_width-1:0] O_ALUSrcB_sel,
    output  wire    [`AGUSrc_sel_width-1:0]  O_AGUSrc_sel,
    output  wire    [`CSRSrc_sel_width-1:0]  O_CSRSrc_sel,
    
    //ls明辨
    output  wire                        O_ls_valid,         //访存有效标志
    output  wire    [`ls_diff_bus   ]   O_ls_type,          //访存类型

    //forward
    output  wire                        O_rs1_re,
    output  wire                        O_rs2_re,
    output  wire                        O_csr_re,

    // 异常
    output  wire    [`Except_Bus    ]   O_except
);
    
    //------------------------------------------------------------------------
    // 指令解码
    //------------------------------------------------------------------------
    wire [`RV32_OP_WIDTH-1:0]  opcode;
    wire [`RV32_F3_WIDTH-1:0]  funct3;
    wire [`RV32_F7_WIDTH-1:0]  funct7;
    wire [`RV32_RD_WIDTH-1:0]  rd;
    wire [`RV32_RS1_WIDTH-1:0] rs1;
    wire [`RV32_RS2_WIDTH-1:0] rs2;
    
    RV32_Inst_Unpack inst_unpack_inst
    (
        .I_inst                 (I_inst                     ),
        .opcode                 (opcode                     ),
        .funct3                 (funct3                     ),
        .funct7                 (funct7                     ),
        .rd                     (rd                         ),
        .rs1                    (rs1                        ),
        .rs2                    (rs2                        )
    );

    //------------------------------------------------------------------------
    // 立即数生成
    //------------------------------------------------------------------------
    wire [`RegDataBus] imm;
    ImmGen_unit imm_gen_inst
    (
        .I_inst                 (I_inst                     ),
        .O_imm                  (imm                        )
    );

    //------------------------------------------------------------------------
    // 操作数选择
    //------------------------------------------------------------------------
    wire [`ALUSrcA_sel_width-1:0] ALUSrcA_sel;
    wire [`ALUSrcB_sel_width-1:0] ALUSrcB_sel;
    ALUSrcSel_unit alu_src_sel_inst
    (
        .opcode                 (opcode                     ),
        .ALUSrcA_sel            (ALUSrcA_sel                ),
        .ALUSrcB_sel            (ALUSrcB_sel                )
    );

    wire [`AGUSrc_sel_width-1:0] AGUSrc_sel;
    AGUSrcSel_unit agu_src_sel_inst
    (
        .opcode                 (opcode                     ),
        .AGUSrc_sel             (AGUSrc_sel                 )
    );

    wire [`CSRSrc_sel_width-1:0] CSRSrc_sel;
    CSRSrcSel_unit csr_src_sel_inst
    (
        .opcode                 (opcode                     ),
        .funct3                 (funct3                     ),
        .CSRSrc_sel             (CSRSrc_sel                 )
    );


    //------------------------------------------------------------------------
    // 各指令解码
    //------------------------------------------------------------------------


    wire inst_is_jalr = (opcode == `RV32I_OP_JALR);
    wire inst_is_jal = (opcode == `RV32I_OP_JAL);
    wire inst_is_lui = (opcode == `RV32I_OP_LUI);
    wire inst_is_auipc = (opcode == `RV32I_OP_AUIPC);
    wire inst_is_type_i = (opcode == `RV32I_OP_TYPE_I);
    wire inst_is_type_r = (opcode == `RV32IM_OP_TYPE_R_M);
    wire inst_is_type_b = (opcode == `RV32I_OP_TYPE_B);
    wire inst_is_type_s = (opcode == `RV32I_OP_TYPE_S);
    wire inst_is_type_l = (opcode == `RV32I_OP_TYPE_IL);
    wire inst_is_csr = (opcode == `RV_OP_CSR);
    wire inst_is_csrrw = inst_is_csr & (funct3 == `RV_F3_CSRRW);
    wire inst_is_csrrs = inst_is_csr & (funct3 == `RV_F3_CSRRS);
    wire inst_is_csrrc = inst_is_csr & (funct3 == `RV_F3_CSRRC);
    wire inst_is_csrrwi = inst_is_csr & (funct3 == `RV_F3_CSRRWI);
    wire inst_is_csrrsi = inst_is_csr & (funct3 == `RV_F3_CSRRSI);
    wire inst_is_csrrci = inst_is_csr & (funct3 == `RV_F3_CSRRCI);

    wire rs1_re = inst_is_type_l | inst_is_type_i | inst_is_type_s | inst_is_type_r | inst_is_type_b | inst_is_jalr | inst_is_jal | inst_is_csrrw | inst_is_csrrs | inst_is_csrrc;
    wire rs2_re = inst_is_type_s | inst_is_type_r | inst_is_type_b;
    wire rd_we = inst_is_type_l | inst_is_type_i | inst_is_auipc | inst_is_lui | inst_is_type_r | inst_is_jalr | inst_is_jal | inst_is_csr;
    wire imm_use = inst_is_type_l | inst_is_type_i | inst_is_auipc | inst_is_lui | inst_is_type_s | inst_is_type_b | inst_is_jalr | inst_is_jal | inst_is_csrrwi | inst_is_csrrsi | inst_is_csrrci;
    wire csr_re = inst_is_csr;
    wire csr_we = inst_is_csr;
    wire ls_valid = inst_is_type_l | inst_is_type_s;

    reg [`ls_diff_bus     ] ls_type;
    reg [`ALUCTL_WIDTH-1:0] alu_ctrl;
    reg [`CSRCTL_WIDTH-1:0] csr_ctrl;
    reg [`BRUCTL_WIDTH-1:0] bru_ctrl;


    always @(*) begin
        ls_type = `ls_nop;
        alu_ctrl = `ALUCTL_NOP;
        csr_ctrl = `CSRCTL_NOP;
        bru_ctrl = `BRUCTL_NOP;
        case(opcode)
            `RV32I_OP_TYPE_IL: begin
                case(funct3)
                    `RV32I_F3_LB: ls_type = `ls_lb;
                    `RV32I_F3_LH: ls_type = `ls_lh;
                    `RV32I_F3_LW: ls_type = `ls_lw;
                    `RV32I_F3_LBU: ls_type = `ls_lbu;
                    `RV32I_F3_LHU: ls_type = `ls_lhu;
                    default: begin end
                endcase
            end
            `RV32I_OP_TYPE_I: begin
                case(funct3)
                    `RV32I_F3_ADDI: alu_ctrl = `ALUCTL_ADD;
                    `RV32I_F3_SLLI: alu_ctrl = `ALUCTL_SLL;
                    `RV32I_F3_SLTI: alu_ctrl = `ALUCTL_SLT;
                    `RV32I_F3_SLTIU: alu_ctrl = `ALUCTL_SLTU;
                    `RV32I_F3_XORI: alu_ctrl = `ALUCTL_XOR;
                    `RV32I_F3_SRI: alu_ctrl = I_inst[30]? `ALUCTL_SRA : `ALUCTL_SRL;
                    `RV32I_F3_ORI: alu_ctrl = `ALUCTL_OR;
                    `RV32I_F3_ANDI: alu_ctrl = `ALUCTL_AND;
                    default: begin end
                endcase
            end
            `RV32I_OP_AUIPC: begin
                alu_ctrl = `ALUCTL_AUIPC;
            end
            `RV32I_OP_LUI: begin
                alu_ctrl = `ALUCTL_LUI;
            end
            `RV32I_OP_TYPE_S: begin
                case(funct3)
                    `RV32I_F3_SB: ls_type = `ls_sb;
                    `RV32I_F3_SH: ls_type = `ls_sh;
                    `RV32I_F3_SW: ls_type = `ls_sw;
                    default: begin end
                endcase
            end
            `RV32IM_OP_TYPE_R_M: begin
                case(funct7)
                    `RV32I_F7_R1, `RV32I_F7_R2: begin
                        case(funct3)
                            `RV32I_F3_ADD_SUB: alu_ctrl = I_inst[30]? `ALUCTL_SUB : `ALUCTL_ADD;
                            `RV32I_F3_SLL: alu_ctrl = `ALUCTL_SLL;
                            `RV32I_F3_SLT: alu_ctrl = `ALUCTL_SLT;
                            `RV32I_F3_SLTU: alu_ctrl = `ALUCTL_SLTU;
                            `RV32I_F3_XOR: alu_ctrl = `ALUCTL_XOR;
                            `RV32I_F3_SR: alu_ctrl = I_inst[30]? `ALUCTL_SRA : `ALUCTL_SRL;
                            `RV32I_F3_OR: alu_ctrl = `ALUCTL_OR;
                            `RV32I_F3_AND: alu_ctrl = `ALUCTL_AND;
                            default: begin end
                        endcase
                    end
                    `RV32M_F7_MUL: begin
                        case(funct3)
                            `RV32M_F3_MUL: alu_ctrl = `ALUCTL_MUL;
                            `RV32M_F3_MULH: alu_ctrl = `ALUCTL_MULH;
                            `RV32M_F3_MULHSU: alu_ctrl = `ALUCTL_MULHSU;
                            `RV32M_F3_MULHU: alu_ctrl = `ALUCTL_MULHU;
                            `RV32M_F3_DIV: alu_ctrl = `ALUCTL_DIV;
                            `RV32M_F3_DIVU: alu_ctrl = `ALUCTL_DIVU;
                            `RV32M_F3_REM: alu_ctrl = `ALUCTL_REM;
                            `RV32M_F3_REMU: alu_ctrl = `ALUCTL_REMU;
                            default: begin end
                        endcase
                    end
                    default: begin end
                endcase
            end
            `RV32I_OP_TYPE_B: begin
                case(funct3)
                    `RV32I_F3_BEQ: bru_ctrl = `BRUCTL_BEQ;
                    `RV32I_F3_BNE: bru_ctrl = `BRUCTL_BNE;
                    `RV32I_F3_BLT: bru_ctrl = `BRUCTL_BLT;
                    `RV32I_F3_BGE: bru_ctrl = `BRUCTL_BGE;
                    `RV32I_F3_BLTU: bru_ctrl = `BRUCTL_BLTU;
                    `RV32I_F3_BGEU: bru_ctrl = `BRUCTL_BGEU;
                    default: begin end
                endcase
            end
            `RV32I_OP_JALR: begin
                bru_ctrl = `BRUCTL_JALR;
                alu_ctrl = `ALUCTL_JALR;
            end
            `RV32I_OP_JAL: begin
                bru_ctrl = `BRUCTL_JAL;
                alu_ctrl = `ALUCTL_JAL;
            end
            `RV_OP_CSR: begin
                case(funct3)
                    `RV_F3_CSRRW:  csr_ctrl = `CSRCTL_WRI;
                    `RV_F3_CSRRS:  csr_ctrl = `CSRCTL_SET;
                    `RV_F3_CSRRC:  csr_ctrl = `CSRCTL_CLR;
                    `RV_F3_CSRRWI: csr_ctrl = `CSRCTL_WRI;
                    `RV_F3_CSRRSI: csr_ctrl = `CSRCTL_SET;
                    `RV_F3_CSRRCI: csr_ctrl = `CSRCTL_CLR;
                    default: begin end
                endcase
            end
            default: begin end
        endcase
    end

    wire [`Except_Bus] except;
    //------------------------------------------------------------------------
    // 异常解码
    //------------------------------------------------------------------------
    dec_except dec_except_inst
    (
        .I_inst                 (I_inst                     ),
        .O_except               (except                     )
    );

    assign O_except = 0;

    //------------------------------------------------------------------------
    // 输出
    //------------------------------------------------------------------------
    assign O_inst = I_inst;
    assign O_inst_addr = I_inst_addr;

    assign O_rs1_raddr = rs1;
    assign O_rs2_raddr = rs2;
    assign O_rs1_rdata = I_rs1_rdata;
    assign O_rs2_rdata = I_rs2_rdata;
    assign O_imm = imm;
    assign O_rd_we = rd_we;
    assign O_rd_waddr = rd;
    assign O_ALUCtrl = alu_ctrl;
    assign O_CSRCtrl = csr_ctrl;
    assign O_BRUCtrl = bru_ctrl;
    assign O_ls_valid = ls_valid;
    assign O_ls_type = ls_type;
    assign O_csr_re = csr_re;
    assign O_csr_raddr = I_inst[31:20];
    assign O_csr_rdata = I_csr_rdata;
    assign O_csr_we = csr_we;
    assign O_csr_waddr = I_inst[31:20];

    assign O_rs1_re = rs1_re;
    assign O_rs2_re = rs2_re;
    assign O_csr_re = csr_re;

    assign O_ALUSrcA_sel = ALUSrcA_sel;
    assign O_ALUSrcB_sel = ALUSrcB_sel;
    assign O_AGUSrc_sel  = AGUSrc_sel;
    assign O_CSRSrc_sel  = CSRSrc_sel;

endmodule
