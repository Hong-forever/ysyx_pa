module ps2_key
(   clk,clrn,ps2_clk,ps2_data,data,
    ready,nextdata_n,overflow
);
    input clk,clrn,ps2_clk,ps2_data;
    input nextdata_n;
    // data[8] = break flag (1 = release), data[7:0] = scan code
    output [8:0] data;
    output reg ready;
    output reg overflow;

    reg [9:0] buffer;
    // fifo now stores 9-bit events: {break, scan}
    reg [8:0] fifo[7:0];
    reg [2:0] w_ptr,r_ptr;   
    reg [3:0] count;  
    reg [2:0] ps2_clk_sync;
    reg break_pending;
    reg ext_pending;

    always @(posedge clk) begin
        ps2_clk_sync <=  {ps2_clk_sync[1:0],ps2_clk};
    end

    wire sampling = ps2_clk_sync[2] & ~ps2_clk_sync[1];

    always @(posedge clk) begin
        if (clrn == 0) begin // reset
            count <= 0; w_ptr <= 0; r_ptr <= 0; overflow <= 0; ready<= 0;
            break_pending <= 1'b0;
            ext_pending <= 1'b0;
        end
        else begin
            if ( ready ) begin // read to output next data
                if(nextdata_n == 1'b0) //read next data
                begin
                    r_ptr <= r_ptr + 3'b1;
                    if(w_ptr==(r_ptr+1'b1)) //empty
                        ready <= 1'b0;
                end
            end
            if (sampling) begin
              if (count == 4'd10) begin
                if ((buffer[0] == 0) &&  // start bit
                    (ps2_data)       &&  // stop bit
                    (^buffer[9:1])) begin      // odd  parity
                    // received one byte
                    if (buffer[8:1] == 8'hF0) begin
                        // break prefix: next byte is release
                        break_pending <= 1'b1;
                    end else if (buffer[8:1] == 8'hE0) begin
                        // extended prefix: mark and wait for next
                        ext_pending <= 1'b1;
                    end else begin
                        // normal scan code: push event with break flag if pending
                        fifo[w_ptr] <= {break_pending, buffer[8:1]};
                        w_ptr <= w_ptr+3'b1;
                        ready <= 1'b1;
                        overflow <= overflow | (r_ptr == (w_ptr + 3'b1));
                        // clear pending flags after consuming
                        break_pending <= 1'b0;
                        ext_pending <= 1'b0;
                    end
                end
                count <= 0;     // for next
              end else begin
                buffer[count] <= ps2_data;  // store ps2_data
                count <= count + 3'b1;
              end
            end
        end
    end
    assign data = fifo[r_ptr]; //always set output event {break, scan}

endmodule

