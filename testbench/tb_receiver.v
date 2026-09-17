`timescale 1ns / 1ps

module tb_receiver();

    // --- Testbench Signals ---
    reg clk;
    reg rst;
    reg init;
    reg [127:0] key;
    reg [95:0]  IV;
    reg [7:0]   ciphertext;
    reg [15:0]  crc_in;

    wire [7:0]  decrypted_data;
    wire        crc_ok;

    // --- Instantiate Receiver ---
    receiver uut(
        .clk(clk),
        .rst(rst),
        .init(init),
        .key(key),
        .ciphertext(ciphertext),
        .crc_in(crc_in),
        .decrypted_data(decrypted_data),
        .crc_ok(crc_ok)
    );

    // --- Clock Generation ---
    always #5 clk = ~clk;  // 100 MHz clock (10 ns period)

    // --- Test Sequence ---
    initial begin
        $display("---- Receiver Testbench Start ----");
        clk = 0;
        rst = 1;
        init = 0;
        key = 128'h00112233445566778899AABBCCDDEEFF; // Example key
        IV  = 96'hA1B2C3D4E5F60718293A4B5C;          // Example IV
        ciphertext = 8'h00;
        crc_in = 16'h0000;

        // --- Reset Phase ---
        #20;
        rst = 0;
        init = 1;

        // --- Wait a few cycles for Grain init ---
        #40;
        init = 0;

        // --- Apply test ciphertext and CRC ---
        ciphertext = 8'hB3;   // Example encrypted byte
        crc_in = 16'hABCD;    // Example received CRC

        #20;
        $display("Ciphertext = %h | Decrypted = %h | CRC_OK = %b",
                 ciphertext, decrypted_data, crc_ok);

        // --- Second data test ---
        ciphertext = 8'h5A;
        crc_in = 16'h1234;
        #20;
        $display("Ciphertext = %h | Decrypted = %h | CRC_OK = %b",
                 ciphertext, decrypted_data, crc_ok);

        // --- End simulation ---
        #20;
        $display("---- Simulation Complete ----");
		
       
    end

endmodule
