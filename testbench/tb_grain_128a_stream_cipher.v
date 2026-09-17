`timescale 1ns / 1ps

module tb_grain_128a_stream_cipher();

    reg clk;
    reg rst;
    reg init;
    reg [127:0] key;
    reg [95:0] IV;

    wire [7:0] keystream_byte;
    wire keystream_valid;

    grain_128a_stream_cipher uut (
        .clk(clk),
        .rst(rst),
        .key(key),
        .IV(IV),
        .keystream_byte(keystream_byte),
        .init(init),
        .keystream_valid(keystream_valid)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        init = 0;
        key = 128'h00112233445566778899AABBCCDDEEFF;
        IV  = 96'h112233445566778899AABB;

        
        #20;
        rst = 0;

        // Load key and IV
        init = 1;
        #40;
        init = 0;

        // Let it run to generate keystream bytes
        #500;

        $finish;
    end

   
    always @(posedge clk) begin
        if (keystream_valid)
            $display("Time=%0t ns | Keystream Byte = %02h", $time, keystream_byte);
    end

endmodule