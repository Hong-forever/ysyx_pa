module top
#(
    parameter DATA_WIDTH = 8
)(
    input   wire                  clk,
    input   wire [DATA_WIDTH-1:0] din,
    input   wire [2:0]            shamt,
    input   wire                  LR,
    input   wire                  AL,

    output  reg  [DATA_WIDTH-1:0] dout
);
    
    always @(posedge clk) begin
        case(shamt)
            'b000: dout <= LR? {din[DATA_WIDTH-2:0], 1'b0} : (AL? {din[DATA_WIDTH-1], din[DATA_WIDTH-1:1]} : {1'b0, din[DATA_WIDTH-1:1]});
            'b001: dout <= LR? {din[DATA_WIDTH-3:0], 2'b0} : (AL? {{2{din[DATA_WIDTH-1]}}, din[DATA_WIDTH-1:2]} : {2'b0, din[DATA_WIDTH-1:2]});
            'b010: dout <= LR? {din[DATA_WIDTH-4:0], 3'b0} : (AL? {{3{din[DATA_WIDTH-1]}}, din[DATA_WIDTH-1:3]} : {3'b0, din[DATA_WIDTH-1:3]});
            'b011: dout <= LR? {din[DATA_WIDTH-5:0], 4'b0} : (AL? {{4{din[DATA_WIDTH-1]}}, din[DATA_WIDTH-1:4]} : {4'b0, din[DATA_WIDTH-1:4]});
            'b100: dout <= LR? {din[DATA_WIDTH-6:0], 5'b0} : (AL? {{5{din[DATA_WIDTH-1]}}, din[DATA_WIDTH-1:5]} : {5'b0, din[DATA_WIDTH-1:5]});
            'b101: dout <= LR? {din[DATA_WIDTH-7:0], 6'b0} : (AL? {{6{din[DATA_WIDTH-1]}}, din[DATA_WIDTH-1:6]} : {6'b0, din[DATA_WIDTH-1:6]});
            'b110: dout <= LR? {din[DATA_WIDTH-8:0], 7'b0} : (AL? {{7{din[DATA_WIDTH-1]}}, din[DATA_WIDTH-1:7]} : {7'b0, din[DATA_WIDTH-1:7]});
            default: dout <= 0;
        endcase
    end

endmodule
