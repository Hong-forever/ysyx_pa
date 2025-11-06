`include "defines.v"

module top 
(
    input   wire                        clk,
    input   wire                        rst
);

    wire clk_soc, locked;

    wire ibus_req;
    wire ibus_we;
    wire [`MemAddrBus] ibus_addr;
    wire [`MemDataBus] ibus_wdata;
    wire [`DBUS_MASK-1:0] ibus_mask;
    wire [`MemDataBus] ibus_rdata;
    wire ibus_ready;

    wire dbus_req;
    wire dbus_we;
    wire [`MemAddrBus] dbus_addr;
    wire [`MemDataBus] dbus_wdata;
    wire [`DBUS_MASK-1:0] dbus_mask;
    wire [`MemDataBus] dbus_rdata;
    wire dbus_ready;

    wire [`INT_BUS    ] inq;
    wire timer_int;

    assign inq = {{(`INT_WIDTH-1){1'b0}}, timer_int};
    
    riscv_ic riscv_ic_inst
    (
        .clk                    (clk                        ),
        .rst                    (rst                        ),

        //ibus
        .O_ibus_req             (ibus_req                   ),
        .O_ibus_we              (ibus_we                    ),
        .O_ibus_addr            (ibus_addr                  ),
        .O_ibus_data            (ibus_wdata                 ),
        .O_ibus_mask            (ibus_mask                  ),
        .I_ibus_data            (ibus_rdata                 ),

        //dbus
        .O_dbus_req             (dbus_req                   ),
        .O_dbus_we              (dbus_we                    ),
        .O_dbus_addr            (dbus_addr                  ),
        .O_dbus_data            (dbus_wdata                 ),
        .O_dbus_mask            (dbus_mask                  ),
        .I_dbus_data            (dbus_rdata                 ),

        // from peripheral
        .I_int                  (inq                        ),
        .I_jtag_haltreq         (1'b0                       )
    );

    wire [`MemAddrBus] ibus_addr_to_guost = ibus_addr - 32'h8000_0000;
    wire [`MemAddrBus] dbus_addr_to_guost = dbus_addr - 32'h8000_0000;


    import "DPI-C" function int pmem_read(input int raddr);
    import "DPI-C" function void pmem_write(input int waddr, input int wdata, input int wmask);

    assign ibus_rdata = ibus_req ? pmem_read(ibus_addr_to_guost) : 32'b0;
    assign dbus_rdata = dbus_req ? pmem_read(dbus_addr_to_guost) : 32'b0;

    always @(*) begin
        if (dbus_req && dbus_we) begin
            pmem_write(dbus_addr, dbus_wdata, {28'b0, dbus_mask});
        end
    end

    // rom #(
    //     .DATA_WIDTH     (32                      ),
    //     .ADDR_WIDTH     (32                      ),
    //     .ROM_DEPTH      (131072                  )
    // ) irom_inst
    // (
    //     .clk            (clk                      ),
    //     .rst            (rst                      ),

    //     .ce_i           (ibus_req                 ),
    //     .addr_i         (ibus_addr                ),
    //     .data_o         (ibus_rdata               )
    // );

    // ram #(
    //     .DATA_WIDTH     (32                      ),
    //     .ADDR_WIDTH     (32                      ),
    //     .RAM_DEPTH      (131072                  )
    // ) dram_inst
    // (
    //     .clk            (clk                      ),
    //     .rst            (rst                      ),

    //     .ce_i           (dbus_req                 ),
    //     .we_i           (dbus_we                  ),
    //     .addr_i         (dbus_addr                ),
    //     .data_i         (dbus_wdata               ),
    //     .data_o         (dbus_rdata               ),
    //     .sel_i          (dbus_mask                )
    // );


endmodule
