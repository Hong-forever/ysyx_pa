module shifter
#(
    parameter DATA_WIDTH = 4
)(
    input   wire                  clk,
    input   wire [DATA_WIDTH-1:0] set,
    input   wire [2:0]            op,

    output  reg  [DATA_WIDTH-1:0] Reg
);
    
    always @(posedge clk) begin
        case(op)
            'b000: Reg <= 0;
            'b001: Reg <= set; 
            'b010: Reg <= {1'b0, Reg[DATA_WIDTH-1:1]};
            'b011: Reg <= {Reg[DATA_WIDTH-2:0], 1'b0};
            'b100: Reg <= {Reg[DATA_WIDTH-1], Reg[DATA_WIDTH-1:1]};
            'b101: Reg <= {set[0], Reg[DATA_WIDTH-1:1]};
            'b110: Reg <= {Reg[0], Reg[DATA_WIDTH-1:1]};
            'b111: Reg <= {Reg[DATA_WIDTH-2:0], Reg[DATA_WIDTH-1]};
            default: Reg <= 0;
        endcase
    end

endmodule
