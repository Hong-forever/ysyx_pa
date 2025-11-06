`include "defines.v"

module top 
(
    input   wire                        clk,
    input   wire                        rst_n
);
    //ROM
    wire                rom_ce;
    wire [`InstAddrBus] inst_addr;
    wire [`InstBus    ] inst;


    //RAM
    wire                ram_ce;
    wire                ram_we;
    wire [`MemAddrBus ] data_addr;
    wire [`MemBus     ] store_data;
    wire [`MemBus     ] data;
    wire [3:0         ] ram_sel;
    
    import "DPI-C" function int pmem_read(input int raddr);
    import "DPI-C" function void pmem_write(input int waddr, input int wdata, input int wmask);

    riscv_ic riscv_ic0
    (
        .clk                            (clk                ),
        .rst_n                          (rst_n              ),

        //to rom
        .ibus_req_o                     (rom_ce             ),
        .ibus_addr_o                    (inst_addr          ),
        .ibus_data_i                    (inst               ),

        //to ram
        .dbus_req_o                     (ram_ce             ),
        .dbus_we_o                      (ram_we             ),
        .dbus_addr_o                    (data_addr          ),
        .dbus_data_i                    (data               ),
        .dbus_data_o                    (store_data         ),
        .dbus_sel_o                     (ram_sel            ),

        //from perip
        .int_i                          (                   )
    );
    
    assign inst = rom_ce ? pmem_read(inst_addr) : 0;
    assign data = ram_ce ? pmem_read(data_addr) : 0;
    
    always @(*) begin
        if(ram_ce & ram_we) begin
            pmem_write(data_addr, store_data, {28'b0, ram_sel});
        end
    end

    initial begin
        $monitor("inst_addr: 0x%08x  inst: 0x%08x\n", inst_addr, inst);
    end
    

endmodule //riscv_ic_sopc
