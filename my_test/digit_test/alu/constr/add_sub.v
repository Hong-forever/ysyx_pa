module add_sub
#(
    parameter DATA_WIDTH = 4
)(
    input   wire [DATA_WIDTH-1:0] Ai,
    input   wire [DATA_WIDTH-1:0] Bi,
    input   wire                  Cin,

    output  wire                  Overflow,
    output  wire                  Cout,
    output  wire                  Zero,
    output  wire [DATA_WIDTH-1:0] Result
);
    
    wire [DATA_WIDTH-1:0] t_add_cin = ({DATA_WIDTH{Cin}} ^ Bi) + {{DATA_WIDTH-1{1'b0}}, Cin};
    
    assign {Cout, Result} = Ai + t_add_cin;
    assign Overflow = (Ai[DATA_WIDTH-1] == t_add_cin[DATA_WIDTH-1]) && (Result[DATA_WIDTH-1] != Ai[DATA_WIDTH-1]);
    assign Zero = ~(|Result); 

endmodule
