`timescale 1 ns / 1 ps

`include "defines.v"

// select one option only
`define TEST_PROG  1
// `define TEST_JTAG  1


// testbench module
module test_tb;

    reg clk;
    reg rst;
    wire [1:0] gpio;
    wire uart_tx_pin;
    reg uart_rx_pin;


    always #10 clk = ~clk;     // 50MHz
    
    
    integer r;


    initial begin
        clk = 0;
        rst = 1;
        $display("test running...");
        #40
        rst = 0;

    end

    // sim timeout
    initial begin
        #500000
        $display("Time Out.");
        $stop;
    end

    riscv_ic_sopc riscv_ic_sopc_inst
    (
        .clk                            (clk                ),
        .rst                            (rst                )
    
    );

    // read mem data
    initial begin
        $readmemh ("inst.data", riscv_ic_sopc_inst.irom_inst.mem);
        $readmemh ("inst.data", riscv_ic_sopc_inst.dram_inst.mem);
    end

endmodule
