`include "defines.v"

//------------------------------------------------------------------------
// cpu core
//------------------------------------------------------------------------

module riscv_ic
(
    input   wire                        clk,
    input   wire                        rst,

    //ibus
    output  wire                        O_ibus_req,
    output  wire                        O_ibus_we,
    output  wire    [`InstAddrBus    ]  O_ibus_addr,
    output  wire    [`InstBus        ]  O_ibus_data,
    output  wire    [`DBUS_MASK-1:0  ]  O_ibus_mask,
    input   wire    [`InstBus        ]  I_ibus_data,

    //dbus
    output  wire                        O_dbus_req,
    output  wire                        O_dbus_we,
    output  wire    [`MemAddrBus    ]   O_dbus_addr,
    output  wire    [`MemDataBus    ]   O_dbus_data,
    output  wire    [`DBUS_MASK-1:0 ]   O_dbus_mask,
    input   wire    [`MemDataBus    ]   I_dbus_data,

    //from peripheral
    input   wire    [`INT_BUS       ]   I_int,
    input   wire                        I_jtag_haltreq   //jtag暂停标志

);

    //-------------------------------------------------------------
    // ifetch
    //-------------------------------------------------------------
    wire [`InstBus    ] O_if_inst;
    wire [`InstAddrBus] O_if_inst_addr;

    //-------------------------------------------------------------
    // pipeline_if_dec
    //-------------------------------------------------------------
    wire [`InstBus    ] I_dec_inst;
    wire [`InstAddrBus] I_dec_inst_addr;

    //-------------------------------------------------------------
    // decoder
    //-------------------------------------------------------------
    wire [`RegAddrBus ] O_rs1_raddr;
    wire [`RegAddrBus ] O_rs2_raddr;
    wire [`CSRAddrBus ] O_csr_raddr;
    wire [`RegDataBus ] I_rs1_rdata;
    wire [`RegDataBus ] I_rs2_rdata;
    wire [`CSRDataBus ] I_csr_rdata;

    wire [`InstBus    ] O_dec_inst;
    wire [`InstAddrBus] O_dec_inst_addr;
    wire [`RegDataBus ] O_dec_rs1_rdata;
    wire [`RegDataBus ] O_dec_rs2_rdata;
    wire [`RegDataBus ] O_dec_imm;
    wire                O_dec_rd_we;
    wire [`RegAddrBus ] O_dec_rd_waddr;
    wire                O_dec_csr_we;
    wire [`CSRAddrBus ] O_dec_csr_waddr;
    wire [`CSRDataBus ] O_dec_csr_rdata;
    wire [`CSRCTL_WIDTH-1:0     ] O_dec_CSRCtrl;
    wire [`ALUCTL_WIDTH-1:0     ] O_dec_ALUCtrl;
    wire [`BRUCTL_WIDTH-1:0     ] O_dec_BRUCtrl;
    wire [`ALUSrcA_sel_width-1:0] O_dec_ALUSrcA_sel;
    wire [`ALUSrcB_sel_width-1:0] O_dec_ALUSrcB_sel;
    wire [`AGUSrc_sel_width-1:0 ] O_dec_AGUSrc_sel;
    wire [`CSRSrc_sel_width-1:0 ] O_dec_CSRSrc_sel;
    wire                O_dec_ls_valid;
    wire [`ls_diff_bus] O_dec_ls_type;
    wire [`Except_Bus ] O_dec_except;

    //-------------------------------------------------------------
    // pipeline_dec_ex
    //-------------------------------------------------------------
    wire [`InstBus    ] I_ex_inst;
    wire [`InstAddrBus] I_ex_inst_addr;
    wire [`RegDataBus ] I_ex_rs1_rdata;
    wire [`RegDataBus ] I_ex_rs2_rdata;
    wire [`RegDataBus ] I_ex_imm;
    wire                I_ex_rd_we;
    wire [`RegAddrBus ] I_ex_rd_waddr;
    wire                I_ex_csr_we;
    wire [`CSRAddrBus ] I_ex_csr_waddr;
    wire [`CSRDataBus ] I_ex_csr_rdata;
    wire [`CSRCTL_WIDTH-1:0] I_ex_CSRCtrl;
    wire [`ALUCTL_WIDTH-1:0] I_ex_ALUCtrl;
    wire [`BRUCTL_WIDTH-1:0] I_ex_BRUCtrl;
    wire [`ALUSrcA_sel_width-1:0] I_ex_ALUSrcA_sel;
    wire [`ALUSrcB_sel_width-1:0] I_ex_ALUSrcB_sel;
    wire [`AGUSrc_sel_width-1:0 ] I_ex_AGUSrc_sel;
    wire [`CSRSrc_sel_width-1:0 ] I_ex_CSRSrc_sel;
    wire                I_ex_ls_valid;
    wire [`ls_diff_bus] I_ex_ls_type;
    wire                I_ex_rs1_re;
    wire                I_ex_rs2_re;
    wire                I_ex_csr_re;
    wire [`RegAddrBus ] I_ex_rs1_raddr;
    wire [`RegAddrBus ] I_ex_rs2_raddr;
    wire [`CSRAddrBus ] I_ex_csr_raddr;
    wire [`Except_Bus ] I_ex_except;

    //-------------------------------------------------------------
    // fwd_unit
    //-------------------------------------------------------------
    wire [`FWDSrc_sel_width-1:0] O_dec_FWDCtrl_rs1;
    wire [`FWDSrc_sel_width-1:0] O_dec_FWDCtrl_rs2;
    wire [`FWDSrc_sel_width-1:0] O_dec_FWDCtrl_csr;

    wire [`FWDSrc_sel_width-1:0] I_ex_FWDCtrl_rs1;
    wire [`FWDSrc_sel_width-1:0] I_ex_FWDCtrl_rs2;
    wire [`FWDSrc_sel_width-1:0] I_ex_FWDCtrl_csr;

    wire                O_dec_rs1_re;
    wire                O_dec_rs2_re;
    wire                O_dec_csr_re;

    wire                I_ex_fwd_rd_we;
    wire [`RegAddrBus ] I_ex_fwd_rd_waddr;

    wire                I_ls_fwd_rd_we;
    wire [`RegAddrBus ] I_ls_fwd_rd_waddr;
    wire [`RegDataBus ] I_ls_fwd_rd_wdata;

    wire [`RegDataBus ] I_wb_fwd_rd_wdata;

    wire                I_ex_fwd_csr_we;
    wire [`CSRAddrBus ] I_ex_fwd_csr_waddr;

    wire                I_ls_fwd_csr_we;
    wire [`CSRAddrBus ] I_ls_fwd_csr_waddr;
    wire [`CSRDataBus ] I_ls_fwd_csr_wdata;

    wire [`CSRDataBus ] I_wb_fwd_csr_wdata;

    //-------------------------------------------------------------
    // exec
    //-------------------------------------------------------------
    wire                O_ex_bru_taken;
    wire [`InstAddrBus] O_ex_bru_target;

    wire [`InstBus    ] O_ex_inst;
    wire [`InstAddrBus] O_ex_inst_addr;
    wire                O_ex_rd_we;
    wire [`RegAddrBus ] O_ex_rd_waddr;
    wire [`RegDataBus ] O_ex_rd_wdata;
    wire [`MemAddrBus ] O_ex_memory_addr;
    wire [`MemDataBus ] O_ex_store_data;
    wire                O_ex_ls_valid;
    wire [`ls_diff_bus] O_ex_ls_type;
    wire                O_ex_csr_we;
    wire [`CSRAddrBus ] O_ex_csr_waddr;
    wire [`CSRDataBus ] O_ex_csr_wdata;
    wire [`Except_Bus ] O_ex_except;

    //-------------------------------------------------------------
    // pipeline_ex_ls
    //-------------------------------------------------------------
    wire [`InstBus    ] I_ls_inst;
    wire [`InstAddrBus] I_ls_inst_addr;
    wire                I_ls_rd_we;
    wire [`RegAddrBus ] I_ls_rd_waddr;
    wire [`RegDataBus ] I_ls_rd_wdata;
    wire [`MemAddrBus ] I_ls_memory_addr;
    wire [`MemDataBus ] I_ls_store_data;
    wire                I_ls_ls_valid;
    wire [`ls_diff_bus] I_ls_ls_type;
    wire                I_ls_csr_we;
    wire [`CSRAddrBus ] I_ls_csr_waddr;
    wire [`CSRDataBus ] I_ls_csr_wdata;
    wire [`Except_Bus ] I_clint_except;


    //-------------------------------------------------------------
    // ls
    //-------------------------------------------------------------
    wire [`InstBus    ] O_ls_inst;
    wire [`InstAddrBus] O_ls_inst_addr;
    wire                O_ls_rd_we;
    wire [`RegAddrBus ] O_ls_rd_waddr;
    wire [`RegDataBus ] O_ls_rd_wdata;
    wire                O_ls_csr_we;
    wire [`CSRAddrBus ] O_ls_csr_waddr;
    wire [`CSRDataBus ] O_ls_csr_wdata;

    //-------------------------------------------------------------
    // pipeline_ls_wb
    //-------------------------------------------------------------
    wire [`InstBus    ] I_wb_inst;
    wire [`InstAddrBus] I_wb_inst_addr;
    wire                I_wb_rd_we;
    wire [`RegAddrBus ] I_wb_rd_waddr;
    wire [`RegDataBus ] I_wb_rd_wdata;
    wire                I_wb_csr_we;
    wire [`CSRAddrBus ] I_wb_csr_waddr;
    wire [`CSRDataBus ] I_wb_csr_wdata;

    //-------------------------------------------------------------
    // pipe_ctrl
    //-------------------------------------------------------------
    wire                stallreq_from_if;
    wire                stallreq_from_dec;
    wire                stallreq_from_ex;
    wire                stallreq_from_ls;
    wire                stallreq_from_clint;
    wire [`StallBus   ] Stall;
    wire [`KillBus    ] Kill;


    //-------------------------------------------------------------
    // csr_reg
    //-------------------------------------------------------------
    wire [`CSRDataBus]  csr_mtvec;
    wire [`CSRDataBus]  csr_mepc;
    wire [`CSRDataBus]  csr_mstatus;
    wire                csr_global_int_en;

    //-------------------------------------------------------------
    // clint
    //-------------------------------------------------------------
    wire                clint_we;
    wire [`CSRAddrBus]  clint_waddr;
    wire [`CSRDataBus]  clint_wdata;
    wire                O_flush;
    wire [`InstAddrBus] O_flush_addr;

    //-------------------------------------------------------------
    // instantiate modules
    //-------------------------------------------------------------

    ifetch u_ifetch
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_bru_taken            (O_ex_bru_taken             ),
        .I_bru_target           (O_ex_bru_target            ),

        .I_jtag_halt            (I_jtag_haltreq             ),
        .I_stall                (Stall[`Stall_pc]           ),
        .I_flush                (O_flush                    ),
        .I_flush_addr           (O_flush_addr               ),

        .O_inst                 (O_if_inst                  ),
        .O_inst_addr            (O_if_inst_addr             ),
        
        .O_stallreq             (stallreq_from_if           ),

        .O_ibus_req             (O_ibus_req                 ),
        .O_ibus_we              (O_ibus_we                  ),
        .O_ibus_addr            (O_ibus_addr                ),
        .O_ibus_data            (O_ibus_data                ),
        .O_ibus_mask            (O_ibus_mask                ),
        .I_ibus_data            (I_ibus_data                )
    );


    decoder u0_decoder
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_inst                 (I_dec_inst                 ),
        .I_inst_addr            (I_dec_inst_addr            ),

        .O_rs1_raddr            (O_rs1_raddr                ),
        .O_rs2_raddr            (O_rs2_raddr                ),
        .O_csr_raddr            (O_csr_raddr                ),
        .I_rs1_rdata            (I_rs1_rdata                ),
        .I_rs2_rdata            (I_rs2_rdata                ),
        .I_csr_rdata            (I_csr_rdata                ),

        .O_inst                 (O_dec_inst                 ),
        .O_inst_addr            (O_dec_inst_addr            ),
        .O_rs1_rdata            (O_dec_rs1_rdata            ),
        .O_rs2_rdata            (O_dec_rs2_rdata            ),
        .O_imm                  (O_dec_imm                  ),
        .O_rd_we                (O_dec_rd_we                ),
        .O_rd_waddr             (O_dec_rd_waddr             ),
        .O_csr_we               (O_dec_csr_we               ),
        .O_csr_waddr            (O_dec_csr_waddr            ),
        .O_csr_rdata            (O_dec_csr_rdata            ),
        .O_CSRCtrl              (O_dec_CSRCtrl              ),
        .O_ALUCtrl              (O_dec_ALUCtrl              ),
        .O_BRUCtrl              (O_dec_BRUCtrl              ),
        .O_ALUSrcA_sel          (O_dec_ALUSrcA_sel          ),
        .O_ALUSrcB_sel          (O_dec_ALUSrcB_sel          ),
        .O_AGUSrc_sel           (O_dec_AGUSrc_sel           ),
        .O_CSRSrc_sel           (O_dec_CSRSrc_sel           ),
        .O_ls_valid             (O_dec_ls_valid             ),
        .O_ls_type              (O_dec_ls_type              ),
        .O_rs1_re               (O_dec_rs1_re               ),
        .O_rs2_re               (O_dec_rs2_re               ),
        .O_csr_re               (O_dec_csr_re               ),
        .O_except               (O_dec_except               )    
    );


    fwd_unit u0_fwd_unit
    (
        .I_rs1_re               (O_dec_rs1_re               ),
        .I_rs2_re               (O_dec_rs2_re               ),
        .I_csr_re               (O_dec_csr_re               ),

        .I_rs1_raddr            (O_rs1_raddr                ),
        .I_rs2_raddr            (O_rs2_raddr                ),
        .I_csr_raddr            (O_csr_raddr                ),

        .I_ls_rd_we             (I_ex_fwd_rd_we             ),
        .I_ls_rd_waddr          (I_ex_fwd_rd_waddr          ),
        .I_wb_rd_we             (I_ls_fwd_rd_we             ),
        .I_wb_rd_waddr          (I_ls_fwd_rd_waddr          ),

        .I_ls_csr_we            (I_ex_fwd_csr_we            ),
        .I_ls_csr_waddr         (I_ex_fwd_csr_waddr         ),
        .I_wb_csr_we            (I_ls_fwd_csr_we            ),
        .I_wb_csr_waddr         (I_ls_fwd_csr_waddr         ),

        .O_FWDCtrl_rs1          (O_dec_FWDCtrl_rs1          ),
        .O_FWDCtrl_rs2          (O_dec_FWDCtrl_rs2          ),
        .O_FWDCtrl_csr          (O_dec_FWDCtrl_csr          )

    );

    fwd_load_stall u_fwd_load_stall
    (
        .I_ex_ls_valid          (I_ex_ls_valid              ),
        .I_ex_ls_load           (~I_ex_ls_type[`ls_diff_width-1]),
        .I_ex_rd_waddr          (I_ex_rd_waddr              ),

        .I_dec_rs1_re           (O_dec_rs1_re               ),
        .I_dec_rs1_raddr        (O_rs1_raddr                ),
        .I_dec_rs2_re           (O_dec_rs2_re               ),
        .I_dec_rs2_raddr        (O_rs2_raddr                ),

        .I_bru_taken            (O_ex_bru_taken             ),

        .O_stallreq             (stallreq_from_dec          )

    );

    regfile u_regfile
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_inst                 (I_wb_inst                  ),
        .I_inst_addr            (I_wb_inst_addr             ),

        .I_if_addr              (O_if_inst_addr             ),
        .I_dec_addr             (O_dec_inst_addr            ),
        .I_ex_addr              (O_ex_inst_addr             ),
        .I_ls_addr              (O_ls_inst_addr             ),

        .I_rs1_raddr            (O_rs1_raddr                ),
        .I_rs2_raddr            (O_rs2_raddr                ),

        .O_rs1_rdata            (I_rs1_rdata                ),
        .O_rs2_rdata            (I_rs2_rdata                ),

        .I_rd_we                (I_wb_rd_we                 ),
        .I_rd_waddr             (I_wb_rd_waddr              ),
        .I_rd_wdata             (I_wb_rd_wdata              )
    );

    wire [`RegAddrBus] I_rs1; // for ftrace npc

    exec u0_exec
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_inst                 (I_ex_inst                  ),
        .I_inst_addr            (I_ex_inst_addr             ),
        .I_rd_we                (I_ex_rd_we                 ),
        .I_rd_waddr             (I_ex_rd_waddr              ),
        .I_imm                  (I_ex_imm                   ),
        .I_csr_we               (I_ex_csr_we                ),
        .I_csr_waddr            (I_ex_csr_waddr             ),
        .I_CSRCtrl              (I_ex_CSRCtrl               ),
        .I_ALUCtrl              (I_ex_ALUCtrl               ),
        .I_BRUCtrl              (I_ex_BRUCtrl               ),
        .I_FWDCtrl_rs1          (I_ex_FWDCtrl_rs1           ),
        .I_FWDCtrl_rs2          (I_ex_FWDCtrl_rs2           ),
        .I_FWDCtrl_csr          (I_ex_FWDCtrl_csr           ),
        .I_ALUSrcA_sel          (I_ex_ALUSrcA_sel           ),
        .I_ALUSrcB_sel          (I_ex_ALUSrcB_sel           ),
        .I_AGUSrc_sel           (I_ex_AGUSrc_sel            ),
        .I_CSRSrc_sel           (I_ex_CSRSrc_sel            ),
        .I_ls_valid             (I_ex_ls_valid              ),
        .I_ls_type              (I_ex_ls_type               ),

        .I_rs1_rdata            (I_ex_rs1_rdata             ),
        .I_rs2_rdata            (I_ex_rs2_rdata             ),
        .I_csr_rdata            (I_ex_csr_rdata             ),

        .I_rs1                  (I_rs1                      ), // for ftrace npc

        .I_ls_rd_wdata          (I_ls_fwd_rd_wdata          ),
        .I_wb_rd_wdata          (I_wb_fwd_rd_wdata          ),

        .I_ls_csr_wdata         (I_ls_fwd_csr_wdata         ),
        .I_wb_csr_wdata         (I_wb_fwd_csr_wdata         ),

        .I_csr_re               (I_ex_csr_re                ),
        .I_except               (I_ex_except                ),

        .O_inst                 (O_ex_inst                  ),
        .O_inst_addr            (O_ex_inst_addr             ),
        .O_rd_we                (O_ex_rd_we                 ),
        .O_rd_waddr             (O_ex_rd_waddr              ),
        .O_rd_wdata             (O_ex_rd_wdata              ),
        .O_memory_addr          (O_ex_memory_addr           ),
        .O_store_data           (O_ex_store_data            ),
        .O_ls_valid             (O_ex_ls_valid              ),
        .O_ls_type              (O_ex_ls_type               ),
        .O_csr_we               (O_ex_csr_we                ),
        .O_csr_waddr            (O_ex_csr_waddr             ),
        .O_csr_wdata            (O_ex_csr_wdata             ),
        .O_except               (O_ex_except                ),

        .O_bru_taken            (O_ex_bru_taken             ),
        .O_bru_target           (O_ex_bru_target            ),

        .O_stallreq             (stallreq_from_ex           )
    );

    lsu u0_lsu
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_inst                 (I_ls_inst                  ),
        .I_inst_addr            (I_ls_inst_addr             ),
        .I_rd_we                (I_ls_rd_we                 ),
        .I_rd_waddr             (I_ls_rd_waddr              ),
        .I_rd_wdata             (I_ls_rd_wdata              ),
        .I_memory_addr          (I_ls_memory_addr           ),
        .I_store_data           (I_ls_store_data            ),
        .I_ls_valid             (I_ls_ls_valid              ),
        .I_ls_type              (I_ls_ls_type               ),
        .I_csr_we               (I_ls_csr_we                ),
        .I_csr_waddr            (I_ls_csr_waddr             ),
        .I_csr_wdata            (I_ls_csr_wdata             ),

        .O_inst                 (O_ls_inst                  ),
        .O_inst_addr            (O_ls_inst_addr             ),
        .O_rd_we                (O_ls_rd_we                 ),
        .O_rd_waddr             (O_ls_rd_waddr              ),
        .O_rd_wdata             (O_ls_rd_wdata              ),
        .O_csr_we               (O_ls_csr_we                ),
        .O_csr_waddr            (O_ls_csr_waddr             ),
        .O_csr_wdata            (O_ls_csr_wdata             ),

        .O_stallreq             (stallreq_from_ls           ),

        .O_dbus_req             (O_dbus_req                 ),
        .O_dbus_we              (O_dbus_we                  ),
        .O_dbus_addr            (O_dbus_addr                ),
        .O_dbus_data            (O_dbus_data                ),
        .O_dbus_mask            (O_dbus_mask                ),
        .I_dbus_data            (I_dbus_data                )
    );


    csr_reg u_csr_reg
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_raddr                (O_csr_raddr                ),
        .O_rdata                (I_csr_rdata                ),

        .I_we                   (I_wb_csr_we                ),
        .I_waddr                (I_wb_csr_waddr             ),
        .I_wdata                (I_wb_csr_wdata             ),

        .I_clint_we             (clint_we                   ),
        .I_clint_waddr          (clint_waddr                ),
        .I_clint_wdata          (clint_wdata                ),

        .O_csr_mtvec            (csr_mtvec                  ),
        .O_csr_mepc             (csr_mepc                   ),
        .O_csr_mstatus          (csr_mstatus                ),
        
        .O_global_int_en        (csr_global_int_en          )
    );

    clint u_clint
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_int                  (I_int                      ),

        .I_except               (I_clint_except             ),
        .I_except_addr          (I_ls_inst_addr             ),

        .I_next_addr            (O_ex_inst_addr             ),

        .I_csr_mtvec            (csr_mtvec                  ),
        .I_csr_mepc             (csr_mepc                   ),
        .I_csr_mstatus          (csr_mstatus                ),
        .I_global_int_en        (csr_global_int_en          ),

        .O_csr_we               (clint_we                   ),
        .O_csr_waddr            (clint_waddr                ),
        .O_csr_wdata            (clint_wdata                ),

        .O_stallreq             (stallreq_from_clint        ),
        .O_flush                (O_flush                    ),
        .O_flush_addr           (O_flush_addr               )
    );


    //------------------------------------------------------------------------
    // PIPELINE
    //------------------------------------------------------------------------

    pipe_ctrl u_pipe_ctrl
    (
        .rst                    (rst                        ),
        .stallreq_from_if       (stallreq_from_if           ),
        .stallreq_from_dec      (stallreq_from_dec          ),
        .stallreq_from_ex       (stallreq_from_ex           ),
        .stallreq_from_ls       (stallreq_from_ls           ),
        .stallreq_from_clint    (stallreq_from_clint        ),
        .stallreq_from_jtag     (I_jtag_haltreq             ),

        .Stall                  (Stall                      ),
        .Kill                   (Kill                       )
    );

    pipeline_if_dec u0_pipeline_if_dec
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_inst                 (O_if_inst                  ),
        .I_inst_addr            (O_if_inst_addr             ),

        .O_inst                 (I_dec_inst                 ),
        .O_inst_addr            (I_dec_inst_addr            ),

        .I_bru_taken            (O_ex_bru_taken             ),
        .I_stall                (Stall[`Stall_if_dec]       ),
        .I_kill                 (Kill[`Kill_if_dec]         ),
        .I_flush                (O_flush                    )
    );


    pipeline_dec_ex u0_pipeline_dec_ex
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_inst                 (O_dec_inst                 ),
        .I_inst_addr            (O_dec_inst_addr            ),
        .I_rs1_rdata            (O_dec_rs1_rdata            ),
        .I_rs2_rdata            (O_dec_rs2_rdata            ),
        .I_imm                  (O_dec_imm                  ),
        .I_rd_we                (O_dec_rd_we                ),
        .I_rd_waddr             (O_dec_rd_waddr             ),
        .I_csr_we               (O_dec_csr_we               ),
        .I_csr_waddr            (O_dec_csr_waddr            ),
        .I_csr_rdata            (O_dec_csr_rdata            ),
        .I_FWDCtrl_rs1          (O_dec_FWDCtrl_rs1          ),
        .I_FWDCtrl_rs2          (O_dec_FWDCtrl_rs2          ),
        .I_FWDCtrl_csr          (O_dec_FWDCtrl_csr          ),
        .I_CSRCtrl              (O_dec_CSRCtrl              ),
        .I_ALUCtrl              (O_dec_ALUCtrl              ),
        .I_BRUCtrl              (O_dec_BRUCtrl              ),
        .I_ALUSrcA_sel          (O_dec_ALUSrcA_sel          ),
        .I_ALUSrcB_sel          (O_dec_ALUSrcB_sel          ),
        .I_AGUSrc_sel           (O_dec_AGUSrc_sel           ),
        .I_CSRSrc_sel           (O_dec_CSRSrc_sel           ),
        .I_ls_valid             (O_dec_ls_valid             ),
        .I_ls_type              (O_dec_ls_type              ),
        .I_csr_re               (O_dec_csr_re               ),
        .I_except               (O_dec_except               ),

        .I_rs1                  (O_rs1_raddr                ),

        .O_inst                 (I_ex_inst                  ),
        .O_inst_addr            (I_ex_inst_addr             ),
        .O_rs1_rdata            (I_ex_rs1_rdata             ),
        .O_rs2_rdata            (I_ex_rs2_rdata             ),

        .O_rs1                  (I_rs1                      ), // for ftrace npc

        .O_imm                  (I_ex_imm                   ),
        .O_rd_we                (I_ex_rd_we                 ),
        .O_rd_waddr             (I_ex_rd_waddr              ),
        .O_csr_we               (I_ex_csr_we                ),
        .O_csr_waddr            (I_ex_csr_waddr             ),
        .O_csr_rdata            (I_ex_csr_rdata             ),
        .O_FWDCtrl_rs1          (I_ex_FWDCtrl_rs1           ),
        .O_FWDCtrl_rs2          (I_ex_FWDCtrl_rs2           ),
        .O_FWDCtrl_csr          (I_ex_FWDCtrl_csr           ),
        .O_CSRCtrl              (I_ex_CSRCtrl               ),
        .O_ALUCtrl              (I_ex_ALUCtrl               ),
        .O_BRUCtrl              (I_ex_BRUCtrl               ),
        .O_fwd_rd_we            (I_ex_fwd_rd_we             ),
        .O_fwd_rd_waddr         (I_ex_fwd_rd_waddr          ),
        .O_fwd_csr_we           (I_ex_fwd_csr_we            ),
        .O_fwd_csr_waddr        (I_ex_fwd_csr_waddr         ),
        .O_ALUSrcA_sel          (I_ex_ALUSrcA_sel           ),
        .O_ALUSrcB_sel          (I_ex_ALUSrcB_sel           ),
        .O_AGUSrc_sel           (I_ex_AGUSrc_sel            ),
        .O_CSRSrc_sel           (I_ex_CSRSrc_sel            ),
        .O_ls_valid             (I_ex_ls_valid              ),
        .O_ls_type              (I_ex_ls_type               ),
        .O_csr_re               (I_ex_csr_re                ),
        .O_except               (I_ex_except                ),

        .I_bru_taken            (O_ex_bru_taken             ),
        .I_stall                (Stall[`Stall_dec_ex]       ),
        .I_kill                 (Kill[`Kill_dec_ex]         ),
        .I_flush                (O_flush                    )
    );

    pipeline_ex_ls u0_pipeline_ex_ls
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_inst                 (O_ex_inst                  ),
        .I_inst_addr            (O_ex_inst_addr             ),
        .I_rd_we                (O_ex_rd_we                 ),
        .I_rd_waddr             (O_ex_rd_waddr              ),
        .I_rd_wdata             (O_ex_rd_wdata              ),
        .I_memory_addr          (O_ex_memory_addr           ),
        .I_store_data           (O_ex_store_data            ),
        .I_ls_valid             (O_ex_ls_valid              ),
        .I_ls_type              (O_ex_ls_type               ),
        .I_csr_we               (O_ex_csr_we                ),
        .I_csr_waddr            (O_ex_csr_waddr             ),
        .I_csr_wdata            (O_ex_csr_wdata             ),
        .I_except               (O_ex_except                ),

        .O_inst                 (I_ls_inst                  ),
        .O_inst_addr            (I_ls_inst_addr             ),
        .O_rd_we                (I_ls_rd_we                 ),
        .O_rd_waddr             (I_ls_rd_waddr              ),
        .O_rd_wdata             (I_ls_rd_wdata              ),
        .O_memory_addr          (I_ls_memory_addr           ),
        .O_store_data           (I_ls_store_data            ),
        .O_ls_valid             (I_ls_ls_valid              ),
        .O_ls_type              (I_ls_ls_type               ),
        .O_csr_we               (I_ls_csr_we                ),
        .O_csr_waddr            (I_ls_csr_waddr             ),
        .O_csr_wdata            (I_ls_csr_wdata             ),
        .O_fwd_rd_we            (I_ls_fwd_rd_we             ),
        .O_fwd_rd_waddr         (I_ls_fwd_rd_waddr          ),
        .O_fwd_rd_wdata         (I_ls_fwd_rd_wdata          ),
        .O_fwd_csr_we           (I_ls_fwd_csr_we            ),
        .O_fwd_csr_waddr        (I_ls_fwd_csr_waddr         ),
        .O_fwd_csr_wdata        (I_ls_fwd_csr_wdata         ),
        .O_except               (I_clint_except             ),

        .I_stall                (Stall[`Stall_ex_ls]        ),
        .I_kill                 (Kill[`Kill_ex_ls]          ),
        .I_flush                (O_flush                    )
    );

    pipeline_ls_wb u0_pipeline_ls_wb
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        .I_inst                 (O_ls_inst                  ),
        .I_inst_addr            (O_ls_inst_addr             ),
        .I_rd_we                (O_ls_rd_we                 ),
        .I_rd_waddr             (O_ls_rd_waddr              ),
        .I_rd_wdata             (O_ls_rd_wdata              ),
        .I_csr_we               (O_ls_csr_we                ),
        .I_csr_waddr            (O_ls_csr_waddr             ),
        .I_csr_wdata            (O_ls_csr_wdata             ),

        .O_inst                 (I_wb_inst                  ),
        .O_inst_addr            (I_wb_inst_addr             ),
        .O_rd_we                (I_wb_rd_we                 ),
        .O_rd_waddr             (I_wb_rd_waddr              ),
        .O_rd_wdata             (I_wb_rd_wdata              ),
        .O_csr_we               (I_wb_csr_we                ),
        .O_csr_waddr            (I_wb_csr_waddr             ),
        .O_csr_wdata            (I_wb_csr_wdata             ),
        .O_fwd_rd_wdata         (I_wb_fwd_rd_wdata          ),
        .O_fwd_csr_wdata        (I_wb_fwd_csr_wdata         ),

        .I_stall                (Stall[`Stall_ls_wb]        ),
        .I_stallreq_from_lsu    (stallreq_from_ls           ),
        .I_kill                 (Kill[`Kill_ls_wb]          ),
        .I_flush                (O_flush                    )
    );


endmodule //riscv_ic
