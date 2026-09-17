`timescale 1ns / 1ps

module top (
    input  wire        clk,
    input  wire        rst,
    input  wire        init,

    input  wire [127:0] key,
    input  wire [95:0]  IV,

    input  wire [7:0]   plaintext_in,
    input  wire         data_valid,

    output wire [7:0]   decrypted_data,
    output wire         crc_ok
);

    // -------------------------------------------------------
    // Grain keystream generator
    // -------------------------------------------------------
    wire [7:0] keystream_byte;
    wire       keystream_valid;

    grain_128a_stream_cipher grain_inst (
        .clk(clk),
        .rst(rst),
        .key(key),
        .IV(IV),
        .keystream_byte(keystream_byte),
        .init(init),
        .keystream_valid(keystream_valid)
    );

    // -------------------------------------------------------
    // Sender output → channel → receiver input
    // -------------------------------------------------------
    wire [7:0]  ciphertext;
    wire        ciphertext_valid;
    wire [15:0] crc_line;
    wire        message_done;

    wire [15:0] ch_data_in;
    wire        ch_in_valid;
    wire        ch_in_ready;

    wire [15:0] ch_data_out;
    wire        ch_out_valid;
    wire        ch_out_ready;

    // -------------------------------------------------------
    // Sender
    // -------------------------------------------------------
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

        .keystream_byte(keystream_byte),
        .keystream_valid(keystream_valid),

        .crc_out(crc_line),
        .message_done(message_done)
    );

    // Pack ciphertext (8 bits) to 16 bits for channel
    assign ch_data_in  = {8'b0, ciphertext};
    assign ch_in_valid = ciphertext_valid;
    assign ch_out_ready = 1'b1; // receiver always ready

    // -------------------------------------------------------
    // Channel
    // -------------------------------------------------------
    channel channel_inst (
        .clk(clk),
        .rst(rst),

        .error_mask(16'h0000),

        .data_in(ch_data_in),
        .out_ready(ch_out_ready),
        .in_valid(ch_in_valid),

        .in_ready(ch_in_ready),
        .out_valid(ch_out_valid),
        .data_out(ch_data_out),

        .sender_init(init),
        .receiver_init(init)
    );

    wire [7:0] ch_cipher_out = ch_data_out[7:0];

    // -------------------------------------------------------
    // Receiver
    // -------------------------------------------------------
    receiver receiver_inst (
        .clk(clk),
        .rst(rst),
        .init(init),
        .key(key),
        .IV(IV),

        .ciphertext(ch_cipher_out),
        .ciphertext_valid(ch_out_valid),
        .message_done(message_done),

        .decrypted_data(decrypted_data),
        .crc_ok(crc_ok),

        .keystream_byte(keystream_byte),
        .keystream_valid(keystream_valid)
    );

endmodule