module vga_mem
(
    input   wire                  clk,
    input   wire                  rst,
    output  wire                  VGA_CLK,
    output  wire                  VGA_HSYNC,
    output  wire                  VGA_VSYNC,
    output  wire                  VGA_BLANK_N,
    output  wire    [7:0]         VGA_R,
    output  wire    [7:0]         VGA_G,
    output  wire    [7:0]         VGA_B
    
);
    assign VGA_CLK = clk;

    wire [9:0] h_addr;
    wire [9:0] v_addr;
    wire [23:0] vga_data;

    vga_ctrl my_vga_ctrl(
        .pclk(clk),
        .reset(rst),
        .vga_data(vga_data),
        .h_addr(h_addr),
        .v_addr(v_addr),
        .hsync(VGA_HSYNC),
        .vsync(VGA_VSYNC),
        .valid(VGA_BLANK_N),
        .vga_r(VGA_R),
        .vga_g(VGA_G),
        .vga_b(VGA_B)
    );

    vmem my_vmem(
        .h_addr(h_addr),
        .v_addr(v_addr[8:0]),
        .vga_data(vga_data)
    );
    
endmodule

module vmem(
    input [9:0] h_addr,
    input [8:0] v_addr,
    output [23:0] vga_data
);

reg [23:0] vga_mem [524287:0];

initial begin
    $readmemh("resource/picture.hex", vga_mem);
end

assign vga_data = vga_mem[{h_addr,v_addr}];

endmodule
