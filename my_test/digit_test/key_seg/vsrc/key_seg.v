module top
#(
    parameter DATA_WIDTH = 8
)(
    input   wire                  clk,
    input   wire                  rstn,
    
    input   wire                  ps2_clk,
    input   wire                  ps2_data,
    
    output  wire                  ready,
    output  wire                  overflow,
    
    output  wire [7:0]            seg0,
    output  wire [7:0]            seg1,
    output  wire [7:0]            seg2,
    output  wire [7:0]            seg3,
    output  wire [7:0]            seg4,
    output  wire [7:0]            seg5,
    output  wire [7:0]            seg6,
    output  wire [7:0]            seg7
);

    wire [8:0] key_event;
    wire [7:0] key_code = key_event[7:0];
    reg [7:0] ascii_map;
    reg next_data;

    wire break_flag = key_event[8];        // 看到 0xF0，下一字节为释放（break）
    reg key_down;          // 当前有按键被按下
    reg [7:0] disp_scan;   // 显示的扫描码（0xFF 表示空白）
    reg [7:0] disp_ascii;  // 显示的 ASCII（0xFF 表示空白）
    reg [7:0] press_cnt;   // 按键计数（总次数，0..99）

    always @(posedge clk) begin
        if(~rstn) next_data <= 1'b1;
        else if(ready) next_data <= 1'b0;
        else next_data <= 1'b1;
    end

    ps2_key ps2_key_inst
    (
        .clk                (clk        ),
        .clrn               (rstn       ),
        .ps2_clk            (ps2_clk    ),
        .ps2_data           (ps2_data   ),
        .data               (key_event  ),
        .ready              (ready      ),
        .nextdata_n         (next_data  ),
        .overflow           (overflow   )
    );

    always @(*) begin
        case(key_code)
            8'h45: ascii_map = 8'h30; // 0
            8'h16: ascii_map = 8'h31; // 1
            8'h1E: ascii_map = 8'h32; // 2
            8'h26: ascii_map = 8'h33; // 3
            8'h25: ascii_map = 8'h34; // 4
            8'h2E: ascii_map = 8'h35; // 5
            8'h36: ascii_map = 8'h36; // 6
            8'h3D: ascii_map = 8'h37; // 7
            8'h3E: ascii_map = 8'h38; // 8
            8'h46: ascii_map = 8'h39; // 9

            // a-z
                // 小写字母 a-z
            8'h1C: ascii_map = 8'h61; // a
            8'h32: ascii_map = 8'h62; // b
            8'h21: ascii_map = 8'h63; // c
            8'h23: ascii_map = 8'h64; // d
            8'h24: ascii_map = 8'h65; // e
            8'h2B: ascii_map = 8'h66; // f
            8'h34: ascii_map = 8'h67; // g
            8'h33: ascii_map = 8'h68; // h
            8'h43: ascii_map = 8'h69; // i
            8'h3B: ascii_map = 8'h6A; // j
            8'h42: ascii_map = 8'h6B; // k
            8'h4B: ascii_map = 8'h6C; // l
            8'h3A: ascii_map = 8'h6D; // m
            8'h31: ascii_map = 8'h6E; // n
            8'h44: ascii_map = 8'h6F; // o
            8'h4D: ascii_map = 8'h70; // p
            8'h15: ascii_map = 8'h71; // q
            8'h2D: ascii_map = 8'h72; // r
            8'h1B: ascii_map = 8'h73; // s
            8'h2C: ascii_map = 8'h74; // t
            8'h3C: ascii_map = 8'h75; // u
            8'h2A: ascii_map = 8'h76; // v
            8'h1D: ascii_map = 8'h77; // w
            8'h22: ascii_map = 8'h78; // x
            8'h35: ascii_map = 8'h79; // y
            8'h1A: ascii_map = 8'h7A; // z
            default: ascii_map = 8'hff;
        endcase
    end

    always @(posedge clk) begin
        if (~rstn) begin
            key_down <= 1'b0;
            disp_scan <= 8'hff;    // 0xFF used as 'blank' sentinel
            disp_ascii <= 8'hff;
            press_cnt <= 8'd0;
        end else begin
            if (ready) begin
                if (break_flag) begin
                    key_down <= 1'b0;
                    disp_scan <= 8'hff;
                    disp_ascii <= 8'hff;
                end else begin
                    if (!key_down) begin
                        key_down <= 1'b1;
                        if (press_cnt < 8'hff) press_cnt <= press_cnt + 1'b1;
                        else press_cnt <= 8'd0;
                        disp_scan <= key_code;
                    end
                    if (ascii_map != 8'hff) disp_ascii <= ascii_map;
                    else disp_ascii <= 8'hff;
                end
            end
        end
    end

    segs segs_inst0
    (
        .din                (disp_scan   ),

        .seg0               (seg0       ),
        .seg1               (seg1       )
    );

    segs segs_inst1
    (
        .din                (disp_ascii ),

        .seg0               (seg2       ),
        .seg1               (seg3       )
    );

    segs segs_inst2
    (
        .din                (8'hff      ),

        .seg0               (seg4       ),
        .seg1               (seg5       )
    );

    segs segs_inst3
    (
        .din                (press_cnt  ),

        .seg0               (seg6       ),
        .seg1               (seg7       )
    );

endmodule

