`include "defines.v"

module idu 
(
    input   wire                        rst_n,

    input   wire    [`InstBus       ]   inst_i,
    input   wire    [`InstAddrBus   ]   inst_addr_i,

    //to regfiles
    output  wire                        reg1_re_o,           //regfiles读通用寄存器1使能
    output  wire    [`RegAddrBus    ]   reg1_raddr_o,        //regfiles读通用寄存器1地址
    output  wire                        reg2_re_o,           //regfiles读通用寄存器2使能
    output  wire    [`RegAddrBus    ]   reg2_raddr_o,        //regfiles读通用寄存器2地址       
    //from regfiles
    input   wire    [`RegBus        ]   reg1_rdata_i,        //获取通用寄存器1地址指向的数据
    input   wire    [`RegBus        ]   reg2_rdata_i,        //获取通用寄存器2地址指向的数据
 
    //to csr reg
    output  wire                        csr_re_o,            //读CSR寄存器使能
    output  wire    [`MemAddrBus    ]   csr_raddr_o,         //读CSR寄存器地址
    //from csr reg
    input   wire    [`RegBus        ]   csr_rdata_i,         //CSR寄存器输入数据

        /***data-forward***/
    //from exu
    input   wire                        exu_reg_we_i,
    input   wire    [`RegAddrBus    ]   exu_reg_waddr_i,
    input   wire    [`RegBus        ]   exu_reg_wdata_i,

    //from lsu
    input   wire                        lsu_reg_we_i,
    input   wire    [`RegAddrBus    ]   lsu_reg_waddr_i,
    input   wire    [`RegBus        ]   lsu_reg_wdata_i,
    /***------------***/

    /***csr_reg-data-forward***/
    //from exu
    input   wire                        exu_csr_we_i,
    input   wire    [`MemAddrBus    ]   exu_csr_waddr_i,
    input   wire    [`RegBus        ]   exu_csr_wdata_i,

    //from lsu
    input   wire                        lsu_csr_we_i,
    input   wire    [`MemAddrBus    ]   lsu_csr_waddr_i,
    input   wire    [`RegBus        ]   lsu_csr_wdata_i,
    /***------------***/


    output  wire    [`InstBus       ]   inst_o,             //指令内容
    output  wire    [`InstAddrBus   ]   inst_addr_o,        //指令地址
    output  wire    [`RegBus        ]   reg1_rdata_o,       //通用寄存器1数据
    output  wire    [`RegBus        ]   reg2_rdata_o,       //通用寄存器2数据
    output  wire                        reg_we_o,           //写通用寄存器标志
    output  wire    [`RegAddrBus    ]   reg_waddr_o,        //写通用寄存器地址
    output  wire                        csr_we_o,           //写CSR寄存器标志
    output  wire    [`MemAddrBus    ]   csr_waddr_o,        //写CSR寄存器地址
    output  wire    [`RegBus        ]   csr_rdata_o,        //CSR寄存器数据
    output  wire    [`CSRCRL_WIDTH-1:0] CSRCtrl_o,
    output  wire    [`ALUCTL_WIDTH-1:0] ALUCtrl_o,          //ALU控制信号

    output  wire    [`MemAddrBus    ]   offset_memory_o,    //访存地址偏置
    output  wire                        ls_valid_o,         //访存有效标志
    output  wire    [`ls_diff_bus   ]   ls_type_o,

    output  wire    [`InstAddrBus   ]   link_addr_o,        //转移指令要保存的返回地址
    input   wire                        prev_is_load_i,     //解决load相关指令问题
    output  wire                        jump_flag_o,        //跳转指令标志
    output  wire    [`InstAddrBus   ]   jump_addr_o,        //跳转指令地址
    output  wire                        stallreq_o

);
    //*********************// 指令域解码 //*********************//
    wire [6:0 ] opcode = inst_i[6:0];
    wire [2:0 ] funct3 = inst_i[14:12];
    wire [6:0 ] funct7 = inst_i[31:25];
    wire [4:0 ] rd     = inst_i[11:7];
    wire [4:0 ] rs1    = inst_i == `RV_EBREAK ? 5'd10 : inst_i[19:15];
    wire [4:0 ] rs2    = inst_i[24:20];

    //指令中的立即数
    wire[`RegBus] rv32i_i_type_imm = {{20{inst_i[31]}}, inst_i[31:20]};
    wire[`RegBus] rv32i_s_type_imm = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
    wire[`RegBus] rv32i_u_type_imm = {inst_i[31:12], 12'b0};
    wire[`RegBus] rv32i_b_type_imm = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
    wire[`RegBus] rv32i_j_type_imm = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
    wire[`RegBus] rv_csr_type_imm = {27'h0, inst_i[19:15]};

    //*********************// 各指令解码 //*********************//
    reg                     reg_we;
    reg                     csr_we;
    reg [`ALUCTL_WIDTH-1:0] alu_ctl;
    reg [`RegBus        ]   imm;
    reg                     ls_valid;
    reg [`ls_diff_bus]      ls_type;

    reg                     reg1_re;
    reg                     reg2_re;
    reg [`RegBus]           reg1_rdata;
    reg [`RegBus]           reg2_rdata;

    reg                     csr_re;
    reg [`RegBus]           csr_rdata;

    reg [`CSRCRL_WIDTH-1:0] csr_ctl;
    
    import "DPI-C" function void trap(input int reg_data);
    
    always @(*) begin
        if(inst_i == `RV_EBREAK) begin
            trap(reg1_rdata);
        end
    end


    always @(*) begin
        reg_we = `Disable;
        csr_we = `Disable;
        alu_ctl = `ALUCTL_NOP;
        imm = `ZeroWord;
        ls_valid = `Disable;
        ls_type = `ls_nop;
        reg1_re = inst_i == `RV_EBREAK ? `Enable : `Disable;
        reg2_re = `Disable;
        csr_re = `Disable;
        csr_ctl = `CSRCTL_NOP;

        case(opcode)
            `RV32I_OP_TYPE_IL: begin
                case(funct3)
                    `RV32I_F3_LB: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        ls_valid = `Enable;
                        ls_type = `ls_lb;
                    end
                    `RV32I_F3_LH: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        ls_valid = `Enable;
                        ls_type = `ls_lh;
                    end
                    `RV32I_F3_LW: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        ls_valid = `Enable;
                        ls_type = `ls_lw;
                    end
                    `RV32I_F3_LBU: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        ls_valid = `Enable;
                        ls_type = `ls_lbu;
                    end
                    `RV32I_F3_LHU: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        ls_valid = `Enable;
                        ls_type = `ls_lhu;
                    end
                    default: begin end
                endcase
            end
            `RV32I_OP_TYPE_I: begin
                case(funct3)
                    `RV32I_F3_ADDI: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        alu_ctl = `ALUCTL_ADD;
                    end
                    `RV32I_F3_SLLI: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        alu_ctl = `ALUCTL_SLL;
                    end
                    `RV32I_F3_SLTI: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        alu_ctl = `ALUCTL_SLT;
                    end
                    `RV32I_F3_SLTIU: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        alu_ctl = `ALUCTL_SLTU;
                    end
                    `RV32I_F3_XORI: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        alu_ctl = `ALUCTL_XOR;
                    end
                    `RV32I_F3_SRI: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        alu_ctl = inst_i[30]? `ALUCTL_SRA : `ALUCTL_SRL;
                    end
                    `RV32I_F3_ORI: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        alu_ctl = `ALUCTL_OR;
                    end
                    `RV32I_F3_ANDI: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        imm = rv32i_i_type_imm;
                        alu_ctl = `ALUCTL_AND;
                    end
                    default: begin end
                endcase
            end
            `RV32I_OP_AUIPC: begin
                reg_we = `Enable;
                imm = rv32i_u_type_imm;
                alu_ctl = `ALUCTL_AUIPC;
            end
            `RV32I_OP_LUI: begin
                reg_we = `Enable;
                imm = rv32i_u_type_imm;
                alu_ctl = `ALUCTL_LUI;
            end
            `RV32I_OP_TYPE_S: begin
                case(funct3)
                    `RV32I_F3_SB: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        imm = rv32i_s_type_imm;
                        ls_valid = `Enable;
                        ls_type = `ls_sb;
                    end
                    `RV32I_F3_SH: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        imm = rv32i_s_type_imm;
                        ls_valid = `Enable;
                        ls_type = `ls_sh;
                    end
                    `RV32I_F3_SW: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        imm = rv32i_s_type_imm;
                        ls_valid = `Enable;
                        ls_type = `ls_sw;
                    end
                    default: begin end
                endcase
            end
            `RV32I_OP_TYPE_R: begin
                case(funct3)
                    `RV32I_F3_ADD_SUB: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        reg_we = `Enable;
                        alu_ctl = inst_i[30]? `ALUCTL_SUB : `ALUCTL_ADD;
                    end
                    `RV32I_F3_SLL: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        reg_we = `Enable;
                        alu_ctl = `ALUCTL_SLL;
                    end
                    `RV32I_F3_SLT: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        reg_we = `Enable;
                        alu_ctl = `ALUCTL_SLT;
                    end
                    `RV32I_F3_SLTU: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        reg_we = `Enable;
                        alu_ctl = `ALUCTL_SLTU;
                    end
                    `RV32I_F3_XOR: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        reg_we = `Enable;
                        alu_ctl = `ALUCTL_XOR;
                    end
                    `RV32I_F3_SR: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        reg_we = `Enable;
                        alu_ctl = inst_i[30]? `ALUCTL_SRA : `ALUCTL_SRL;
                    end
                    `RV32I_F3_OR: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        reg_we = `Enable;
                        alu_ctl = `ALUCTL_OR;
                    end
                    `RV32I_F3_AND: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        reg_we = `Enable;
                        alu_ctl = `ALUCTL_AND;
                    end
                    default: begin end
                endcase
            end
            `RV32I_OP_TYPE_B: begin
                case(funct3)
                    `RV32I_F3_BEQ, `RV32I_F3_BNE, `RV32I_F3_BLT, `RV32I_F3_BGE, `RV32I_F3_BLTU, `RV32I_F3_BGEU: begin
                        reg1_re = `Enable;
                        reg2_re = `Enable;
                        imm = rv32i_b_type_imm;
                    end
                    default: begin end
                endcase
            end

            `RV32I_OP_JALR: begin
                reg1_re = `Enable;
                reg_we = `Enable;
                imm = rv32i_i_type_imm;
                alu_ctl = `ALUCTL_JALR;
            end
            `RV32I_OP_JAL: begin
                reg1_re = `Enable;
                reg_we = `Enable;
                imm = rv32i_j_type_imm;
                alu_ctl = `ALUCTL_JAL;
            end
            `RV_OP_CSR: begin
                case(funct3)
                    `RV_F3_CSRRW: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        csr_re = `Enable;
                        csr_we = `Enable;
                        csr_ctl = `CSRCTL_WRI;
                    end
                    `RV_F3_CSRRS: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        csr_re = `Enable;
                        csr_we = `Enable;
                        csr_ctl = `CSRCTL_SET;
                    end
                    `RV_F3_CSRRC: begin
                        reg1_re = `Enable;
                        reg_we = `Enable;
                        csr_re = `Enable;
                        csr_we = `Enable;
                        csr_ctl = `CSRCTL_CLR;
                    end
                    `RV_F3_CSRRWI: begin
                        imm = rv_csr_type_imm;
                        reg_we = `Enable;
                        csr_re = `Enable;
                        csr_we = `Enable;
                        csr_ctl = `CSRCTL_WRI;
                    end
                    `RV_F3_CSRRSI: begin
                        imm = rv_csr_type_imm;
                        reg_we = `Enable;
                        csr_re = `Enable;
                        csr_we = `Enable;
                        csr_ctl = `CSRCTL_SET;
                    end
                    `RV_F3_CSRRCI: begin
                        imm = rv_csr_type_imm;
                        reg_we = `Enable;
                        csr_re = `Enable;
                        csr_we = `Enable;
                        csr_ctl = `CSRCTL_CLR;
                    end
                    default: begin end
                endcase
            end
            default: begin end
        endcase
    end

    //rs1读数据
    always @(*) begin
        if(!rst_n) begin
            reg1_rdata = `ZeroWord;
        //在IDU和EXU之间的数据相关处理
        end else if((reg1_re == `Enable) && (exu_reg_we_i == `Enable)
                     && (exu_reg_waddr_i == reg1_raddr_o)) begin
            reg1_rdata = (exu_reg_waddr_i != `ZeroReg)? exu_reg_wdata_i : `ZeroWord;
        //在IDU和LSU之间的数据相关处理
        end else if((reg1_re == `Enable) && (lsu_reg_we_i == `Enable)
                     && (lsu_reg_waddr_i == reg1_raddr_o)) begin
            reg1_rdata = (lsu_reg_waddr_i != `ZeroReg)? lsu_reg_wdata_i : `ZeroWord;
        end else if(reg1_re == `Enable) begin
            reg1_rdata = reg1_rdata_i;
        end else if(reg1_re == `Disable)begin
            reg1_rdata = imm;
        end else begin
            reg1_rdata = `ZeroWord;
        end
    end

    //rs2读数据
    always @(*) begin
        if(!rst_n) begin
            reg2_rdata = `ZeroWord;
        //在IDU和EXU之间的数据相关处理
        end else if((reg2_re == `Enable) && (exu_reg_we_i == `Enable)
                     && (exu_reg_waddr_i == reg2_raddr_o)) begin
            reg2_rdata = (exu_reg_waddr_i != `ZeroReg)? exu_reg_wdata_i : `ZeroWord;
        //在IDU和LSU之间的数据相关处理
        end else if((reg2_re == `Enable) && (lsu_reg_we_i == `Enable)
                     && (lsu_reg_waddr_i == reg2_raddr_o)) begin
            reg2_rdata = (lsu_reg_waddr_i != `ZeroReg)? lsu_reg_wdata_i : `ZeroWord;
        end else if(reg2_re == `Enable) begin
            reg2_rdata = reg2_rdata_i;
        end else if(reg2_re == `Disable)begin
            reg2_rdata = imm;
        end else begin
            reg2_rdata = `ZeroWord;
        end
    end


    //csr读数据
    always @(*) begin
        if(!rst_n) begin
            csr_rdata = `ZeroWord;
        //在ID和EX之间的数据相关处理
        end else if((csr_re == `Enable) && (csr_raddr_o == exu_csr_waddr_i) 
                     && (exu_csr_we_i == `Enable)) begin
            csr_rdata = exu_csr_wdata_i;
        //在ID和MEM之间的数据相关处理
        end else if((csr_re == `Enable) && (csr_raddr_o == lsu_csr_waddr_i) 
                     && (lsu_csr_we_i == `Enable)) begin
            csr_rdata = lsu_csr_wdata_i;
        end else if(csr_re == `Enable)begin
            csr_rdata = csr_rdata_i;
        end else begin
            csr_rdata = `ZeroWord;
        end
    end

    /*使用分支预测改进，待实现*/
    //B type instruction implementation

    wire [`InstAddrBus] jump_addr_jalr = reg1_rdata + imm;
    wire [`InstAddrBus] bta_jta = inst_addr_i + imm;

    reg jump_flag;
    always @(*) begin
        jump_flag = `Disable;
        case(opcode) 
            `RV32I_OP_TYPE_B:
                case(funct3)
                    `RV32I_F3_BEQ: begin
                        if(reg1_rdata == reg2_rdata) begin
                            jump_flag = `Enable;
                        end else begin end
                    end
                    `RV32I_F3_BNE: begin
                        if(reg1_rdata != reg2_rdata) begin
                            jump_flag = `Enable;
                        end else begin end
                    end
                    `RV32I_F3_BLT: begin
                        if($signed(reg1_rdata) < $signed(reg2_rdata)) begin
                            jump_flag = `Enable;
                        end else begin end
                    end
                    `RV32I_F3_BGE: begin
                        if($signed(reg1_rdata) >= $signed(reg2_rdata)) begin
                            jump_flag = `Enable;
                        end else begin end
                    end
                     `RV32I_F3_BLTU: begin
                        if(reg1_rdata < reg2_rdata) begin
                            jump_flag = `Enable;
                        end else begin end
                    end
                    `RV32I_F3_BGEU: begin
                        if(reg1_rdata >= reg2_rdata) begin
                            jump_flag = `Enable;
                        end else begin end
                    end
                    default: begin end
                endcase
            `RV32I_OP_JALR: begin
                jump_flag = `Enable;
            end
            `RV32I_OP_JAL: begin
                jump_flag = `Enable;
            end
            default: begin end
        endcase
    end

    reg stallreq_for_reg1_loadrelate;    //要读取的寄存器1是否与上一条指令存在load相关
    reg stallreq_for_reg2_loadrelate;    //要读取的寄存器2是否与上一条指令存在load相关

    //load相关
    always @(*) begin
        if(!rst_n) begin
            stallreq_for_reg1_loadrelate = `NoStop;  
        //处理上一条指令是load指令而现在指令与load指令存在相关的情况，需要stop一个时钟周期，再进行前递
        end else if((prev_is_load_i == `True) && (exu_reg_waddr_i == reg1_raddr_o) 
                     && (reg1_re == `Enable)) begin
            stallreq_for_reg1_loadrelate = `Stop;                            
        end else begin
            stallreq_for_reg1_loadrelate = `NoStop; 
        end
    end

    always @(*) begin
        if(!rst_n) begin
            stallreq_for_reg2_loadrelate = `NoStop;  
        //处理上一条指令是load指令而现在指令与load指令存在相关的情况，需要stop一个时钟周期，再进行前递
        end else if((prev_is_load_i == `True) && (exu_reg_waddr_i == reg2_raddr_o) 
                     && (reg2_re == `Enable)) begin
            stallreq_for_reg2_loadrelate = `Stop;                            
        end else begin
            stallreq_for_reg2_loadrelate = `NoStop; 
        end
    end

    wire inst_is_jalr = (opcode == `RV32I_OP_JALR);


    //*********************// 输出 //*********************//
    assign inst_o = inst_i;
    assign inst_addr_o = inst_addr_i;

    assign reg1_re_o = reg1_re;
    assign reg2_re_o = reg2_re;
    assign reg1_raddr_o = rs1;
    assign reg2_raddr_o = rs2;
    assign reg1_rdata_o = reg1_rdata;
    assign reg2_rdata_o = reg2_rdata;

    assign reg_we_o = reg_we;
    assign reg_waddr_o = rd;

    assign ALUCtrl_o = alu_ctl;

    assign offset_memory_o = ls_type[`ls_diff_width-1]? rv32i_s_type_imm : rv32i_i_type_imm;
    assign ls_valid_o = ls_valid;
    assign ls_type_o = ls_type;

    assign csr_re_o = csr_re;
    assign csr_raddr_o = {20'h0, inst_i[31:20]};
    assign csr_rdata_o = csr_rdata;
    assign csr_we_o = csr_we;
    assign csr_waddr_o = {20'h0, inst_i[31:20]};
    assign CSRCtrl_o = csr_ctl;

    assign stallreq_o = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

    assign link_addr_o = inst_addr_i + 32'h4;
    assign jump_flag_o = jump_flag;
    assign jump_addr_o = inst_is_jalr? jump_addr_jalr : bta_jta;



endmodule //decoder
