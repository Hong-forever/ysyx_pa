module top
#(
    parameter DATA_WIDTH = 4
)(
    input   wire [DATA_WIDTH-1:0] Ai,
    input   wire [DATA_WIDTH-1:0] Bi,
    input   wire [2:0]            op,

    output  wire                  Overflow,
    output  wire                  Cout,
    output  wire                  Zero,
    output  reg  [DATA_WIDTH-1:0] Result
);
    wire [DATA_WIDTH-1:0] Result_add_sub;

    add_sub 
    #(
        .DATA_WIDTH     (DATA_WIDTH )
    ) add_sub_inst (
        .Ai             (Ai         ),
        .Bi             (Bi         ),
        .Cin            (op == 'b001),
        .Overflow       (Overflow   ),
        .Cout           (Cout       ),
        .Zero           (Zero       ),
        .Result         (Result_add_sub)
    );
    
    always @(*) begin
        case(op)
            'b000: Result = Result_add_sub;
            'b001: Result = Result_add_sub;
            'b010: Result = ~Ai;
            'b011: Result = Ai & Bi;
            'b100: Result = Ai | Bi;
            'b101: Result = Ai ^ Bi;
            'b110: Result = {{DATA_WIDTH-1{1'b0}}, Ai<Bi};
            'b111: Result = {{DATA_WIDTH-1{1'b0}}, Ai==Bi};
            default: Result = 0;
        endcase
    end

endmodule
