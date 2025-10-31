module top
#(
    parameter DATA_WIDTH = 8
)(
    input   wire                  clk,

    input   wire [DATA_WIDTH-1:0] din,
    input   wire                  en,

    output  wire [7:0]            seg0,
    output  wire [7:0]            seg1
);
    
    wire [DATA_WIDTH-1:0] reg_data, data_in;

    shifter
    #(
        .DATA_WIDTH         (DATA_WIDTH)
    ) shifter_inst (
        .clk                (clk        ),
        .set                (data_in    ),
        .op                 (en ? 3'b001 : 3'b101),
        .Reg                (reg_data   )
    );
    
    assign data_in = en ? din : {{DATA_WIDTH-1{1'b0}}, reg_data[4]^reg_data[3]^reg_data[2]^reg_data[0]};

    segs segs_inst
    (
        .din                (reg_data   ),

        .seg0               (seg0       ),
        .seg1               (seg1       )

    );
endmodule
