module rom
#(
    parameter DATA_WIDTH = 32,                  //数据总线宽度
    parameter ADDR_WIDTH = 32,                  //地址总线宽度
    parameter ROM_DEPTH  = 4096                 //ROM深度
)(
    input   wire                        clk,        //时钟输入
    input   wire                        rst,      //复位输入

    input   wire                        ce_i,
    input   wire  [ADDR_WIDTH-1:0   ]   addr_i,
    output  wire  [DATA_WIDTH-1:0   ]   data_o
);

    //计算地址位宽
    localparam ADDR_BITS = $clog2(ROM_DEPTH-1);
    
    //ROM存储阵列
    reg [DATA_WIDTH-1:0] mem [0:ROM_DEPTH-1];
    
    //内部信号
    wire [ADDR_BITS-1:0] rom_addr = addr_i[ADDR_BITS+1:2]; //字节地址转字地址
        
    assign data_o = ce_i ? mem[rom_addr] : 'b0;

endmodule