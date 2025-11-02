module vga_ctrl (
    input wire      pclk,
    input wire      reset,
    input wire [23:0] vga_data,
    output wire [9:0] h_addr,
    output wire [9:0] v_addr,
    output wire hsync,
    output wire vsync,
    output wire valid,
    output wire [7:0] vga_r,
    output wire [7:0] vga_g,
    output wire [7:0] vga_b
);

    parameter h_frontporch = 96;
    parameter h_active = 144;
    parameter h_backporch = 784;
    parameter h_total = 800;

    parameter v_frontporch = 2;
    parameter v_active = 35;
    parameter v_backporch = 515;
    parameter v_total = 525;

    reg [9:0] x_cnt;
    reg [9:0] y_cnt;
    wire h_valid;
    wire v_valid;

    always @(posedge pclk) begin
        if(reset == 1'b1) begin
            x_cnt <= 1;
            y_cnt <= 1;
        end else begin
            if(x_cnt == h_total)begin
                x_cnt <= 1;
                if(y_cnt == v_total) y_cnt <= 1;
                else y_cnt <= y_cnt + 1;
                
            end else begin
                x_cnt <= x_cnt + 1;
            end
        end
    end


    assign hsync = (x_cnt > h_frontporch);
    assign vsync = (y_cnt > v_frontporch);


    assign h_valid = (x_cnt > h_active) & (x_cnt <= h_backporch);
    assign v_valid = (y_cnt > v_active) & (y_cnt <= v_backporch);
    assign valid = h_valid & v_valid;


    assign h_addr = h_valid ? (x_cnt - 10'd145) : 10'd0;
    assign v_addr = v_valid ? (y_cnt - 10'd36) : 10'd0;

    assign {vga_r, vga_g, vga_b} = vga_data;

   endmodule
