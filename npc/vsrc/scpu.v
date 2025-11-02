module top
(
    input   wire            clk,
    input   wire            rst,

    output  reg     [7:0]      seg0,
    output  reg     [7:0]      seg1,
    output  wire    [7:0]      dout

);

    reg [7:0] gpr[0:3];

    reg [3:0] pc;

    reg [7:0] imem[0:15];

    wire [7:0] inst = imem[pc];

    wire [1:0] rd  = inst[5:4];
    wire [1:0] rs1 = inst[3:2];
    wire [1:0] rs2 = inst[1:0];
    wire [3:0] imm = inst[3:0];
    wire [5:2] addr = inst[5:2];

    wire [7:0] rs1_data = gpr[rs1];
    wire [7:0] rs2_data = gpr[rs2];

    reg [7:0] display_data;
    always @(posedge clk or posedge rst) begin
        if(rst) display_data <= 0;
        else if(display_en) display_data <= gpr[2];
    end
    
    wire display_en = inst[7:6] == 2'b01;
    assign dout = display_data;

    reg rd_we;
    reg [7:0] rd_data;
    wire jump_flag = (inst[7:6] == 2'b11 && gpr[0] != rs2_data);
    wire [3:0] jump_addr = addr;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            imem[0] = 8'b1000_1010;
            imem[1] = 8'b1001_0000;
            imem[2] = 8'b1010_0000;
            imem[3] = 8'b1011_0001;
            imem[4] = 8'b0001_0111;
            imem[5] = 8'b0010_1001;
            imem[6] = 8'b1101_0001;
            imem[7] = 8'b0100_0000;
            imem[8] = 8'b1110_0011;
        end
    end

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            pc <= 0;
        end else if(jump_flag) begin
            pc <= jump_addr;
        end else begin
            pc <= pc + 1;
        end
    end

    always @(*) begin
        case(inst[7:6])
            2'b00: begin
                rd_data = rs1_data + rs2_data;
                rd_we = 1;
            end
            2'b10: begin
                rd_data = {4'b0, imm};
                rd_we = 1;
            end
            default: begin
                rd_data = 0;
                rd_we = 0;
            end
        endcase
    end
   
   
    integer i;
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            for(i = 0; i < 4; i = i + 1) begin
                gpr[i] <= 0;
            end
        end else if(rd_we) begin
            gpr[rd] <= rd_data;
        end
    end
    
    segs segs_inst
    (
        .din        (display_data   ),
        .seg0       (seg0           ),
        .seg1       (seg1           )
    );

endmodule

