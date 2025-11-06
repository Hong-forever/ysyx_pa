`include "defines.v"

module riscv_ic 
(
    input   wire                        clk,
    input   wire                        rst_n,

    //ibus
    output  wire                        ibus_req_o,
    output  wire    [`InstAddrBus   ]   ibus_addr_o,
    input   wire    [`InstBus       ]   ibus_data_i,   
    
    //dbus
    output  wire                        dbus_req_o,
    output  wire                        dbus_we_o,
    output  wire    [`InstAddrBus   ]   dbus_addr_o,
    input   wire    [`InstBus       ]   dbus_data_i,
    output  wire    [`InstBus       ]   dbus_data_o,
    output  wire    [`ByteSel-1:0   ]   dbus_sel_o,

    //from perip
    input   wire    [`INT_BUS       ]   int_i

);

    //**********************/ ifu /***************************//
    //IFU->IFU/IDU
    wire [`InstBus    ] ifu_inst_o;
    wire [`InstAddrBus] ifu_inst_addr_o;

    //**********************/ ifu_idu /***************************//
    //IFU/IDU->ID
    wire [`InstBus    ] idu_inst_i;
    wire [`InstAddrBus] idu_inst_addr_i;

    //**********************/ idu /***************************//
    //IDU->IFU or IFU/IDU
    wire                idu_jump_flag_o;
    wire [`InstAddrBus] idu_jump_addr_o;
    //IDU->Regfile
    wire                reg1_re_o;
    wire [`RegAddrBus ] reg1_addr_o;
    wire                reg2_re_o;
    wire [`RegAddrBus ] reg2_addr_o;
    //Regfile->IDU
    wire [`RegBus     ] reg1_rdata_i;
    wire [`RegBus     ] reg2_rdata_i;
    //IDU->CSR
    wire                csr_re_o;
    wire [`MemAddrBus ] csr_raddr_o;
    //CSR->IDU
    wire [`RegBus     ] csr_rdata_i;
    //IDU->IDU/EXU
    wire [`InstBus    ] idu_inst_o;
    wire [`InstAddrBus] idu_inst_addr_o;
    wire [`RegBus     ] idu_reg1_rdata_o;
    wire [`RegBus     ] idu_reg2_rdata_o;
    wire                idu_reg_we_o;
    wire [`RegAddrBus ] idu_reg_waddr_o;
    wire [`MemAddrBus ] idu_offset_memory_o;
    wire                idu_csr_we_o;   
    wire [`MemAddrBus ] idu_csr_waddr_o; 
    wire [`RegBus     ] idu_csr_rdata_o; 
    wire [`CSRCRL_WIDTH-1:0] idu_CSRCtrl_o;
    wire [`ALUCTL_WIDTH-1:0] idu_ALUCtrl_o;
    wire                idu_ls_valid_o;
    wire [`ls_diff_bus] idu_ls_type_o;
    wire [`InstAddrBus] idu_link_addr_o;

    //**********************/ idu_exu /***************************//
    //IDU/EXU->EXU
    wire [`InstBus    ] exu_inst_i;
    wire [`InstAddrBus] exu_inst_addr_i;
    wire [`RegBus     ] exu_reg1_rdata_i;
    wire [`RegBus     ] exu_reg2_rdata_i;
    wire                exu_reg_we_i;
    wire [`RegAddrBus ] exu_reg_waddr_i;
    wire [`InstAddrBus] exu_link_addr_i;
    wire [`MemAddrBus ] exu_offset_memory_i;
    wire                exu_csr_we_i;
    wire [`MemAddrBus ] exu_csr_waddr_i;
    wire [`RegBus     ] exu_csr_rdata_i;
    wire [`CSRCRL_WIDTH-1:0] exu_CSRCtrl_i;
    wire [`ALUCTL_WIDTH-1:0] exu_ALUCtrl_i;
    wire                exu_ls_valid_i;
    wire [`ls_diff_bus] exu_ls_type_i;


    //**********************/ exu /***************************//
    //EXU->EXU/LSU
    wire [`InstBus    ] exu_inst_o;
    wire [`InstAddrBus] exu_inst_addr_o;
    wire                exu_reg_we_o;
    wire [`RegAddrBus ] exu_reg_waddr_o;
    wire [`RegBus     ] exu_reg_wdata_o;
    wire [`MemAddrBus ] exu_memory_addr_o;
    wire [`MemBus     ] exu_store_data_o;      
    wire                exu_csr_we_o;
    wire [`MemAddrBus ] exu_csr_waddr_o;
    wire [`RegBus     ] exu_csr_wdata_o;
    wire                exu_ls_valid_o;
    wire [`ls_diff_bus] exu_ls_type_o;

    //EXU->IDU    load数据相关问题，确认上一条指令是否为load指令
    wire                exu_inst_is_load;

    //**********************/ exu_lsu /***************************//
    //EXU/LSU->LSU
    wire [`InstBus    ] lsu_inst_i;
    wire [`InstAddrBus] lsu_inst_addr_i;
    wire                lsu_reg_we_i;
    wire [`RegAddrBus ] lsu_reg_waddr_i;
    wire [`RegBus     ] lsu_reg_wdata_i;
    wire [`MemAddrBus ] lsu_memory_addr_i;
    wire [`MemBus     ] lsu_store_data_i;     
    wire                lsu_ls_valid_i;
    wire [`ls_diff_bus] lsu_ls_type_i; 
    wire                lsu_csr_we_i;
    wire [`MemAddrBus ] lsu_csr_waddr_i;
    wire [`RegBus     ] lsu_csr_wdata_i;

    //**********************/ lsu /***************************//
    //LSU->LSU/WBU
    wire [`InstBus    ] lsu_inst_o;
    wire [`InstAddrBus] lsu_inst_addr_o;
    wire                lsu_reg_we_o;
    wire [`RegAddrBus ] lsu_reg_waddr_o;
    wire [`RegBus     ] lsu_reg_wdata_o;
    wire                lsu_csr_we_o;
    wire [`MemAddrBus ] lsu_csr_waddr_o;
    wire [`RegBus     ] lsu_csr_wdata_o;
    wire                lsu_memory_misalign_o;

    //**********************/ lsu_wbu /***************************//
    //LSU/WBU->WBU   
    wire [`InstBus    ] wbu_inst_i;
    wire [`InstAddrBus] wbu_inst_addr_i;
    wire                wbu_reg_we_i;
    wire [`RegAddrBus ] wbu_reg_waddr_i;
    wire [`RegBus     ] wbu_reg_wdata_i;
    wire                wbu_csr_we_i;
    wire [`MemAddrBus ] wbu_csr_waddr_i;
    wire [`RegBus     ] wbu_csr_wdata_i;

    //**********************/ regfile /***************************//

    //**********************/ pipe_ctrl /***************************//
    wire                stallreq_from_ifu;
    wire                stallreq_from_idu;
    wire                stallreq_from_exu;
    wire                stallreq_from_lsu;
    wire                stallreq_from_clint;
    wire                jtag_haltreq;
    wire [`StallBus   ] stall_o;
    wire                flush_o;
    wire [`InstAddrBus] flush_addr_o;


    //**********************/ csr-reg /***************************//
    wire [`RegBus     ] csr_mtvec;
    wire [`RegBus     ] csr_mepc;
    wire [`RegBus     ] csr_mstatus;
    wire                csr_global_int_en;

    //**********************/ clint /***************************//
    wire                clint_we;
    wire [`MemAddrBus ] clint_waddr;
    wire [`RegBus     ] clint_wdata;
    wire                int_assert;
    wire [`InstAddrBus] int_addr;



    //ifu
    ifu ifu0
    (
        .clk                    (clk                        ),
        .rst_n                  (rst_n                      ),
        .jtag_halt_i            (jtag_haltreq               ),
        .jump_flag_i            (idu_jump_flag_o            ),
        .jump_addr_i            (idu_jump_addr_o            ),
        .stall_i                (stall_o                    ),
        .flush_i                (flush_o                    ),
        .flush_addr_i           (flush_addr_o               ),
        .inst_o                 (ifu_inst_o                 ),
        .inst_addr_o            (ifu_inst_addr_o            ),
        .ibus_req_o             (ibus_req_o                 ),
        .ibus_addr_o            (ibus_addr_o                ),
        .ibus_data_i            (ibus_data_i                ),
        .stallreq_o             (stallreq_from_ifu          )
    );

    //IFU/IDU
    ifu_idu ifu_idu0
    (
        .clk                    (clk                        ),
        .rst_n                  (rst_n                      ),

        .inst_i                 (ifu_inst_o                 ),
        .inst_addr_i            (ifu_inst_addr_o            ),

        .inst_o                 (idu_inst_i                 ),
        .inst_addr_o            (idu_inst_addr_i            ),

        .jump_flag_i            (idu_jump_flag_o            ),
        .stall_i                (stall_o                    ),
        .flush_i                (flush_o                    )
    );
    
    //IDU
    idu idu0
    (
        .rst_n                  (rst_n                      ),
        .inst_i                 (idu_inst_i                 ),
        .inst_addr_i            (idu_inst_addr_i            ),

        //to regfile
        .reg1_re_o              (reg1_re_o                  ),
        .reg2_re_o              (reg2_re_o                  ),
        .reg1_raddr_o           (reg1_addr_o                ),
        .reg2_raddr_o           (reg2_addr_o                ),
        //from regfile
        .reg1_rdata_i           (reg1_rdata_i               ),
        .reg2_rdata_i           (reg2_rdata_i               ),

        //to csr reg
        .csr_re_o               (csr_re_o                   ),
        .csr_raddr_o            (csr_raddr_o                ),
        //from csr reg
        .csr_rdata_i            (csr_rdata_i                ),

        /***data-forward***/        
        //from exu
        .exu_reg_we_i           (exu_reg_we_o               ),
        .exu_reg_waddr_i        (exu_reg_waddr_o            ),
        .exu_reg_wdata_i        (exu_reg_wdata_o            ),

        //from lsu
        .lsu_reg_we_i           (lsu_reg_we_o               ),
        .lsu_reg_waddr_i        (lsu_reg_waddr_o            ),
        .lsu_reg_wdata_i        (lsu_reg_wdata_o            ),
        /***->->->->->->***/

        /***csr_reg-data-forward***/
        //from exu
        .exu_csr_we_i           (exu_csr_we_o               ),
        .exu_csr_waddr_i        (exu_csr_waddr_o            ),
        .exu_csr_wdata_i        (exu_csr_wdata_o            ),
    
        //from lsu
        .lsu_csr_we_i           (lsu_csr_we_o               ),
        .lsu_csr_waddr_i        (lsu_csr_waddr_o            ),
        .lsu_csr_wdata_i        (lsu_csr_wdata_o            ),
        /***------------***/
    

        //to IDU/EXU
        .inst_o                 (idu_inst_o                 ), 
        .inst_addr_o            (idu_inst_addr_o            ),     
        .reg1_rdata_o           (idu_reg1_rdata_o           ),
        .reg2_rdata_o           (idu_reg2_rdata_o           ),
        .reg_we_o               (idu_reg_we_o               ),
        .reg_waddr_o            (idu_reg_waddr_o            ),
        .csr_we_o               (idu_csr_we_o               ),   
        .csr_waddr_o            (idu_csr_waddr_o            ),
        .csr_rdata_o            (idu_csr_rdata_o            ),

        .CSRCtrl_o              (idu_CSRCtrl_o              ),
        .ALUCtrl_o              (idu_ALUCtrl_o              ),

        .offset_memory_o        (idu_offset_memory_o        ),
        .ls_valid_o             (idu_ls_valid_o             ),
        .ls_type_o              (idu_ls_type_o              ),

        .link_addr_o            (idu_link_addr_o            ),
        .prev_is_load_i         (exu_inst_is_load           ),

        .jump_flag_o            (idu_jump_flag_o            ),
        .jump_addr_o            (idu_jump_addr_o            ),

        //to pipe_ctrl
        .stallreq_o             (stallreq_from_idu          )

    );

    //regfile
    regfile regfile0
    (
        .clk                    (clk                        ),
        .rst_n                  (rst_n                      ),

        .inst_i                 (wbu_inst_i                 ),
        .inst_addr_i            (wbu_inst_addr_i            ),      

        //from idu
        .reg1_re_i              (reg1_re_o                  ),
        .reg2_re_i              (reg2_re_o                  ),
        .raddr1_i               (reg1_addr_o                ),
        .raddr2_i               (reg2_addr_o                ),
        //to idu
        .rdata1_o               (reg1_rdata_i               ),
        .rdata2_o               (reg2_rdata_i               ),

        //from lsu    
        .we_i                   (wbu_reg_we_i               ),
        .waddr_i                (wbu_reg_waddr_i            ),
        .wdata_i                (wbu_reg_wdata_i            )
    );

    //IDU/EXU
    idu_exu idu_exu0
    (
        .clk                    (clk                        ),
        .rst_n                  (rst_n                      ),

        //from idu       
        .inst_i                 (idu_inst_o                 ),
        .inst_addr_i            (idu_inst_addr_o            ),
        .reg1_rdata_i           (idu_reg1_rdata_o           ),
        .reg2_rdata_i           (idu_reg2_rdata_o           ),
        .reg_we_i               (idu_reg_we_o               ),
        .reg_waddr_i            (idu_reg_waddr_o            ),
        .offset_memory_i        (idu_offset_memory_o        ),
        .csr_we_i               (idu_csr_we_o               ),
        .csr_waddr_i            (idu_csr_waddr_o            ),
        .csr_rdata_i            (idu_csr_rdata_o            ),
        .CSRCtrl_i              (idu_CSRCtrl_o              ),
        .ALUCtrl_i              (idu_ALUCtrl_o              ),

        .ls_valid_i             (idu_ls_valid_o             ),
        .ls_type_i              (idu_ls_type_o              ),

        .link_addr_i            (idu_link_addr_o            ),

        //to exu
        .inst_o                 (exu_inst_i                 ),
        .inst_addr_o            (exu_inst_addr_i            ),
        .reg1_rdata_o           (exu_reg1_rdata_i           ),
        .reg2_rdata_o           (exu_reg2_rdata_i           ),
        .reg_we_o               (exu_reg_we_i               ),
        .reg_waddr_o            (exu_reg_waddr_i            ),
        .offset_memory_o        (exu_offset_memory_i        ),
        .csr_we_o               (exu_csr_we_i               ),   
        .csr_waddr_o            (exu_csr_waddr_i            ),
        .csr_rdata_o            (exu_csr_rdata_i            ),
        .CSRCtrl_o              (exu_CSRCtrl_i              ),
        .ALUCtrl_o              (exu_ALUCtrl_i              ),

        .ls_valid_o             (exu_ls_valid_i             ),
        .ls_type_o              (exu_ls_type_i              ),

        .link_addr_o            (exu_link_addr_i            ),
        .stall_i                (stall_o                    ),
        .flush_i                (flush_o                    )

    );        

    //EXU
    exu exu0
    (
        .rst_n                  (rst_n                      ),

        //from IDU/EXU                                       
        .inst_i                 (exu_inst_i                 ),
        .inst_addr_i            (exu_inst_addr_i            ),
        .reg1_rdata_i           (exu_reg1_rdata_i           ),
        .reg2_rdata_i           (exu_reg2_rdata_i           ),
        .reg_we_i               (exu_reg_we_i               ),
        .reg_waddr_i            (exu_reg_waddr_i            ),
        .offset_memory_i        (exu_offset_memory_i        ),
        .CSRCtrl_i              (exu_CSRCtrl_i              ),
        .ALUCtrl_i              (exu_ALUCtrl_i              ),
        .ls_valid_i             (exu_ls_valid_i             ),
        .ls_type_i              (exu_ls_type_i              ),
        .link_addr_i            (exu_link_addr_i            ),
        .csr_we_i               (exu_csr_we_i               ),
        .csr_waddr_i            (exu_csr_waddr_i            ),
        .csr_rdata_i            (exu_csr_rdata_i            ),

        //to EXU/LSU
        .inst_o                 (exu_inst_o                 ),
        .inst_addr_o            (exu_inst_addr_o            ),
        .reg_we_o               (exu_reg_we_o               ),
        .reg_waddr_o            (exu_reg_waddr_o            ),
        .reg_wdata_o            (exu_reg_wdata_o            ),
        .memory_addr_o          (exu_memory_addr_o          ),
        .store_data_o           (exu_store_data_o           ),
        .ls_valid_o             (exu_ls_valid_o             ),
        .ls_type_o              (exu_ls_type_o              ),
        .csr_we_o               (exu_csr_we_o               ),   
        .csr_waddr_o            (exu_csr_waddr_o            ),
        .csr_wdata_o            (exu_csr_wdata_o            ),

        //to pipe_ctrl
        .stallreq_o             (stallreq_from_exu          ),

        //to id
        .inst_is_load_o         (exu_inst_is_load           )
    );

    //EXU/LSU
    exu_lsu exu_lsu0
    (
        .clk                    (clk                        ),
        .rst_n                  (rst_n                      ),
    
        //from EXU
        .inst_i                 (exu_inst_o                 ),
        .inst_addr_i            (exu_inst_addr_o            ),
        .reg_we_i               (exu_reg_we_o               ),
        .reg_waddr_i            (exu_reg_waddr_o            ),
        .reg_wdata_i            (exu_reg_wdata_o            ),
        .memory_addr_i          (exu_memory_addr_o          ),
        .store_data_i           (exu_store_data_o           ),
        .ls_valid_i             (exu_ls_valid_o             ),
        .ls_type_i              (exu_ls_type_o              ),
        .csr_we_i               (exu_csr_we_o               ),
        .csr_waddr_i            (exu_csr_waddr_o            ),
        .csr_wdata_i            (exu_csr_wdata_o            ),

        //to LSU
        .inst_o                 (lsu_inst_i                 ),
        .inst_addr_o            (lsu_inst_addr_i            ),
        .reg_we_o               (lsu_reg_we_i               ),
        .reg_waddr_o            (lsu_reg_waddr_i            ),	
        .reg_wdata_o            (lsu_reg_wdata_i            ),
        .memory_addr_o          (lsu_memory_addr_i          ),
        .store_data_o           (lsu_store_data_i           ),
        .ls_valid_o             (lsu_ls_valid_i             ),
        .ls_type_o              (lsu_ls_type_i              ),
        .csr_we_o               (lsu_csr_we_i               ),   
        .csr_waddr_o            (lsu_csr_waddr_i            ),
        .csr_wdata_o            (lsu_csr_wdata_i            ),
        .stall_i                (stall_o                    ),
        .flush_i                (flush_o                    )
    );

    //LSU
    lsu lsu0
    (
        .rst_n                  (rst_n                      ),

        //from EXU/LSU
        .inst_i                 (lsu_inst_i                 ),
        .inst_addr_i            (lsu_inst_addr_i            ),
        .reg_we_i               (lsu_reg_we_i               ),
        .reg_waddr_i            (lsu_reg_waddr_i            ),
        .reg_wdata_i            (lsu_reg_wdata_i            ),
        .memory_addr_i          (lsu_memory_addr_i          ), 
        .store_data_i           (lsu_store_data_i           ),   
        .ls_valid_i             (lsu_ls_valid_i             ),
        .ls_type_i              (lsu_ls_type_i              ),
        .csr_we_i               (lsu_csr_we_i               ),
        .csr_waddr_i            (lsu_csr_waddr_i            ),
        .csr_wdata_i            (lsu_csr_wdata_i            ),

        //to LSU/WBU
        .inst_o                 (lsu_inst_o                 ),
        .inst_addr_o            (lsu_inst_addr_o            ),
        .reg_we_o               (lsu_reg_we_o               ),
        .reg_waddr_o            (lsu_reg_waddr_o            ),
        .reg_wdata_o            (lsu_reg_wdata_o            ),
        .csr_we_o               (lsu_csr_we_o               ),   
        .csr_waddr_o            (lsu_csr_waddr_o            ),
        .csr_wdata_o            (lsu_csr_wdata_o            ),

        //to dbus
        .dbus_req_o             (dbus_req_o                 ),
        .dbus_we_o              (dbus_we_o                  ),        
        .dbus_addr_o            (dbus_addr_o                ),
        .dbus_data_i            (dbus_data_i                ),
        .dbus_data_o            (dbus_data_o                ),
        .dbus_sel_o             (dbus_sel_o                 )
    );

    //LSU/WBU
    lsu_wbu lsu_wbu0
    (
        .clk                    (clk                        ),
        .rst_n                  (rst_n                      ),

        //from LSU       
        .inst_i                 (lsu_inst_o                 ),
        .inst_addr_i            (lsu_inst_addr_o            ),   
        .reg_we_i               (lsu_reg_we_o               ),
        .reg_waddr_i            (lsu_reg_waddr_o            ),
        .reg_wdata_i            (lsu_reg_wdata_o            ),
        .csr_we_i               (lsu_csr_we_o               ),
        .csr_waddr_i            (lsu_csr_waddr_o            ),
        .csr_wdata_i            (lsu_csr_wdata_o            ),

        //to WBU 
        .inst_o                 (wbu_inst_i                 ),
        .inst_addr_o            (wbu_inst_addr_i            ),
        .reg_we_o               (wbu_reg_we_i               ),
        .reg_waddr_o            (wbu_reg_waddr_i            ),
        .reg_wdata_o            (wbu_reg_wdata_i            ),
        .csr_we_o               (wbu_csr_we_i               ),   
        .csr_waddr_o            (wbu_csr_waddr_i            ),
        .csr_wdata_o            (wbu_csr_wdata_i            ),

        .stall_i                (stall_o                    ),
        .flush_i                (flush_o                    )
    );  

    //PIPE_CTRL  
    pipe_ctrl pipe_ctrl0  
    (   
        .rst_n                  (rst_n                      ),
        .stallreq_from_ifu      (stallreq_from_ifu          ),
        .stallreq_from_idu      (stallreq_from_idu          ),
        .stallreq_from_exu      (stallreq_from_exu          ),
        .stallreq_from_lsu      (stallreq_from_lsu          ),
        .stallreq_from_clint    (stallreq_from_clint        ),
        .haltreq_from_jtag      (jtag_haltreq               ),
        .stall_o                (stall_o                    ),
        .int_assert_i           (int_assert                 ),
        .int_addr_i             (int_addr                   ),
        .flush_o                (flush_o                    ),
        .flush_addr_o           (flush_addr_o               )
    );

    //CSR_REG
    csr_reg csr_reg0
    (
        .clk                    (clk                        ),
        .rst_n                  (rst_n                      ),

        //from idu
        .re_i                   (csr_re_o                   ),
        .raddr_i                (csr_raddr_o                ),
        //to idu
        .rdata_o                (csr_rdata_i                ),

        //form lsu_wb
        .we_i                   (wbu_csr_we_i               ),
        .waddr_i                (wbu_csr_waddr_i            ),
        .wdata_i                (wbu_csr_wdata_i            ),
        .csr_timer_int_o        (                           ),


        //from clint
        .clint_we_i             (clint_we                   ),
        .clint_waddr_i          (clint_waddr                ),
        .clint_wdata_i          (clint_wdata                ),

        //to clint
        .csr_mtvec_o            (csr_mtvec                  ),
        .csr_mepc_o             (csr_mepc                   ),
        .csr_mstatus_o          (csr_mstatus                ),

        .global_int_en_o        (csr_global_int_en          )
    );


    //CLINT
    clint clint0
    (
        .clk                    (clk                        ),
        .rst_n                  (rst_n                      ),

        //from perip
        .int_i                  (int_i                      ),

        //from exu_lsu
        .inst_i                 (lsu_inst_i                 ),
        .inst_addr_i            (lsu_inst_addr_i            ),

        .memory_misalign_i      (lsu_memory_misalign_o      ),

        .stall_i                (stall_o                    ),

        //from csr_reg
        .csr_mtvec_i            (csr_mtvec                  ),
        .csr_mepc_i             (csr_mepc                   ),
        .csr_mstatus_i          (csr_mstatus                ),

        .global_int_en_i        (csr_global_int_en          ),

        //to csr_reg
        .csr_we_o               (clint_we                   ),
        .csr_waddr_o            (clint_waddr                ),
        .csr_wdata_o            (clint_wdata                ),

        //to pipe_ctrl
        .stallreq_o             (stallreq_from_clint        ),
        .int_assert_o           (int_assert                 ),
        .int_addr_o             (int_addr                   )
    );

endmodule //riscv_ic