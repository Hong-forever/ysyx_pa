module segs
(
    input   wire    [7:0]           din,

    output  reg     [7:0]           seg0,
    output  reg     [7:0]           seg1
);

// 共阳极数码管段码定义 (a,b,c,d,e,f,g,dp)
// 0-亮，1-灭（共阳极：高电平不亮，低电平亮）

    parameter [7:0] SEG_0  = 8'b0000_0011;  // 0 - 03
    parameter [7:0] SEG_1  = 8'b1001_1111;  // 1 - 9F
    parameter [7:0] SEG_2  = 8'b0010_0101;  // 2 - 25
    parameter [7:0] SEG_3  = 8'b0000_1101;  // 3 - 0D
    parameter [7:0] SEG_4  = 8'b1001_1001;  // 4 - 99
    parameter [7:0] SEG_5  = 8'b0100_1001;  // 5 - 49
    parameter [7:0] SEG_6  = 8'b0100_0001;  // 6 - 41
    parameter [7:0] SEG_7  = 8'b0001_1111;  // 7 - 1F
    parameter [7:0] SEG_8  = 8'b0000_0001;  // 8 - 01
    parameter [7:0] SEG_9  = 8'b0000_1001;  // 9 - 09
    parameter [7:0] SEG_A  = 8'b0001_0001;  // A - 11
    parameter [7:0] SEG_B  = 8'b1100_0001;  // b - C1
    parameter [7:0] SEG_C  = 8'b0110_0011;  // C - 63
    parameter [7:0] SEG_D  = 8'b1000_0101;  // d - 85
    parameter [7:0] SEG_E  = 8'b0110_0001;  // E - 61
    parameter [7:0] SEG_F  = 8'b0111_0001;  // F - 71

    always @(*) begin
        // if high byte is 0xFF (used as 'blank'), turn off segments
        if (din == 8'hff) begin
            seg0 = 8'b1111_1111; // all off
        end else begin
            case(din[3:0])
                4'h0:   seg0 = SEG_0;
                4'h1:   seg0 = SEG_1;
                4'h2:   seg0 = SEG_2;
                4'h3:   seg0 = SEG_3;
                4'h4:   seg0 = SEG_4;
                4'h5:   seg0 = SEG_5;
                4'h6:   seg0 = SEG_6;
                4'h7:   seg0 = SEG_7;
                4'h8:   seg0 = SEG_8;
                4'h9:   seg0 = SEG_9;
                4'ha:   seg0 = SEG_A;
                4'hb:   seg0 = SEG_B;
                4'hc:   seg0 = SEG_C;
                4'hd:   seg0 = SEG_D;
                4'he:   seg0 = SEG_E;
                4'hf:   seg0 = SEG_F;
            endcase
        end
    end
   
    always @(*) begin
        // if din == 8'hff then blank both digits
        if (din == 8'hff) begin
            seg1 = 8'b1111_1111;
        end else begin
            case(din[7:4])
                4'h0:   seg1 = SEG_0;
                4'h1:   seg1 = SEG_1;
                4'h2:   seg1 = SEG_2;
                4'h3:   seg1 = SEG_3;
                4'h4:   seg1 = SEG_4;
                4'h5:   seg1 = SEG_5;
                4'h6:   seg1 = SEG_6;
                4'h7:   seg1 = SEG_7;
                4'h8:   seg1 = SEG_8;
                4'h9:   seg1 = SEG_9;
                4'ha:   seg1 = SEG_A;
                4'hb:   seg1 = SEG_B;
                4'hc:   seg1 = SEG_C;
                4'hd:   seg1 = SEG_D;
                4'he:   seg1 = SEG_E;
                4'hf:   seg1 = SEG_F;
            endcase
        end
    end

endmodule

