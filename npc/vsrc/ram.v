module ram 
#(
    parameter DATA_WIDTH = 32,      //数据总线宽度
    parameter ADDR_WIDTH = 32,      //地址总线宽度
    parameter RAM_DEPTH  = 4096     //RAM深度
)(
    input   wire                        clk,        //时钟输入
    input   wire                        rst,      //复位输入 (高电平有效)
    
    input   wire                        ce_i,
    input   wire                        we_i,       //写使能
    input   wire  [ADDR_WIDTH-1:0   ]   addr_i,     //地址总线
    input   wire  [DATA_WIDTH-1:0   ]   data_i,     //输入数据
    output  wire  [DATA_WIDTH-1:0   ]   data_o,     //输出数据
    input   wire  [DATA_WIDTH/8-1:0 ]   sel_i       //字节选择
);

    //计算地址位宽
    localparam ADDR_BITS = $clog2(RAM_DEPTH-1);
    
    reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];
    
    //内部信号
    wire [ADDR_BITS-1:0] ram_addr = addr_i[ADDR_BITS+1:2]; //字节地址转字地址
        
    //写操作 - 字节使能写
    integer j;
    always @(posedge clk) begin
        if(rst) begin
            //复位时不初始化RAM以节省资源
        end else if(ce_i & we_i) begin
            for(j = 0; j < DATA_WIDTH/8; j = j + 1) begin
                if(sel_i[j]) begin
                    mem[ram_addr][j*8 +: 8] <= data_i[j*8 +: 8];
                end
            end
        end
    end

    //读操作
    reg [DATA_WIDTH-1:0] data;
    always @(*) begin
        if(!ce_i) begin
            data = 'b0;
        end else if(!we_i) begin
            data = mem[ram_addr];
        end
    end
    assign data_o = data;


endmodule