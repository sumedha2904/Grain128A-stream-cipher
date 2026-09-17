`timescale 1ns / 1ps
//-------------------------------------------------------------
// FINAL PRESENTATION TESTBENCH — tb_top.v
//-------------------------------------------------------------
module tb_top();

    //---------------------------------------------------------
    // Clock and reset
    //---------------------------------------------------------
    reg clk;
    reg rst;
    reg init;

    //---------------------------------------------------------
    // Common key/IV
    //---------------------------------------------------------
    reg [127:0] key;
    reg [95:0]  IV;

    //---------------------------------------------------------
    // Sender inputs
    //---------------------------------------------------------
    reg [7:0] plaintext_in;
    reg       data_valid;

    //---------------------------------------------------------
    // Interconnects
    //---------------------------------------------------------
    wire [7:0] ciphertext;
    wire       ciphertext_valid;
    wire [15:0] crc_line;
    wire        message_done;

    //---------------------------------------------------------
    // Receiver outputs
    //---------------------------------------------------------
    wire [7:0] decrypted_data;
    wire       crc_ok;

    //---------------------------------------------------------
    // Clock generation: 10ns period (100MHz)
    //---------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    //---------------------------------------------------------
    // Instantiate Sender
    //---------------------------------------------------------
    sender sender_inst (
        .clk(clk),
        .rst(rst),
        .init(init),
        .key(key),
        .IV(IV),
        .plaintext_in(plaintext_in),
        .data_valid(data_valid),
        .ciphertext_out(ciphertext),
        .ciphertext_valid(ciphertext_valid),
        .keystream_byte(),
        .keystream_valid(),
        .crc_out(crc_line),
        .message_done(message_done)
    );

    //---------------------------------------------------------
    // Instantiate Receiver
    //---------------------------------------------------------
    receiver receiver_inst (
        .clk(clk),
        .rst(rst),
        .init(init),
        .key(key),
        .IV(IV),
        .ciphertext(ciphertext),
        .ciphertext_valid(ciphertext_valid),
        .message_done(message_done),
        .decrypted_data(decrypted_data),
        .crc_ok(crc_ok),
        .keystream_byte(),
        .keystream_valid()
    );

    //---------------------------------------------------------
    // Simulation control
    //---------------------------------------------------------
    initial begin
        $display("\n==============================================");
        $display("   GRAIN-128A STREAM CIPHER: ENCRYPTION-DECRYPTION DEMO ");
        $display("==============================================");

        rst = 1; init = 0;
        key  = 128'h00112233445566778899AABBCCDDEEFF;
        IV   = 96'hAABBCCDDEEFF112233445566;
        plaintext_in = 8'h00;
        data_valid = 0;

        #20;  rst = 0;
        $display("\n[INFO] Reset released at %0t ns", $time);

        // initialize cipher
        init = 1;
        #40; init = 0;
        $display("[INFO] Key and IV loaded at %0t ns", $time);

        // wait for first valid keystream byte
        wait(sender_inst.u_grain_128a_stream_cipher.keystream_valid &&
             receiver_inst.u_grain_128a_stream_cipher.keystream_valid);
        $display("[SYNC] Keystream generation synchronized at %0t ns", $time);

        #10;
        //-----------------------------------------------------
        // TRANSMIT BYTE: 'H' (0x48)
        //-----------------------------------------------------
        $display("\n---------------------------------------------------");
        $display(" TRANSMISSION STARTED: Sending character 'H' ");
        $display("---------------------------------------------------");

        @(posedge clk);
        plaintext_in = 8'h48; // 'H'
        data_valid = 1;
        @(posedge clk);
        data_valid = 0;

        wait(message_done);
        #100;

        //-----------------------------------------------------
        // RESULTS
        //-----------------------------------------------------
        $display("\n---------------------------------------------------");
        $display(" RESULT SUMMARY ");
        $display("---------------------------------------------------");
        $display(" Time (ns):           %0t", $time);
        $display(" Plaintext Sent:      0x%02h ('H')", 8'h48);
        $display(" Ciphertext Received: 0x%02h", ciphertext);
        $display(" Decrypted Output:    0x%02h", decrypted_data);
        $display(" CRC Status:          %s", crc_ok ? "PASS" : "FAIL");
        $display("---------------------------------------------------\n");

        #50;
        $display(" Simulation completed successfully\n");
        $display("==============================================\n");
        $finish;
    end

    //---------------------------------------------------------
    // Show keystream sync (once per valid)
    //---------------------------------------------------------
    reg ks_valid_d;
    always @(posedge clk) begin
        ks_valid_d <= sender_inst.u_grain_128a_stream_cipher.keystream_valid;
        if (sender_inst.u_grain_128a_stream_cipher.keystream_valid &&
            !ks_valid_d &&
            receiver_inst.u_grain_128a_stream_cipher.keystream_valid)
            $display("[KSYNC] Time=%0t | Sender=%02h | Receiver=%02h",
                     $time,
                     sender_inst.u_grain_128a_stream_cipher.keystream_byte,
                     receiver_inst.u_grain_128a_stream_cipher.keystream_byte);
    end

    //---------------------------------------------------------
    // Print data only on rising edge of ciphertext_valid
    //---------------------------------------------------------
    reg ciphertext_valid_d;
    always @(posedge clk) begin
        ciphertext_valid_d <= ciphertext_valid;
        if (ciphertext_valid && !ciphertext_valid_d && !sender_inst.message_done)
            $display("[DATA] %0t ns | Keystream=%02h | Plaintext=%02h | Ciphertext=%02h",
                     $time,
                     sender_inst.u_grain_128a_stream_cipher.keystream_byte,
                     plaintext_in,
                     ciphertext);
    end

endmodule