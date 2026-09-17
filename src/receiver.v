`timescale 1ns / 1ps

module receiver(
    input  wire        clk,
    input  wire        rst,
    input  wire        init,
    input  wire [127:0] key,
    input  wire [95:0]  IV,
    input  wire [7:0]   ciphertext,
    input  wire         ciphertext_valid,
    input  wire         message_done,  // from sender
    output reg  [7:0]   decrypted_data,
    output reg          crc_ok,
    output wire [7:0]   keystream_byte,
    output wire         keystream_valid
);

    grain_128a_stream_cipher u_grain_128a_stream_cipher (
        .clk(clk),
        .rst(rst),
        .init(init),
        .key(key),
        .IV(IV),
        .keystream_byte(keystream_byte),
        .keystream_valid(keystream_valid)
    );

    reg keystream_valid_d;
    always @(posedge clk or posedge rst)
        if (rst)
            keystream_valid_d <= 1'b0;
        else
            keystream_valid_d <= keystream_valid;

    // --- Internal CRC logic
    reg [15:0] crc_calc, next_crc;
    reg [7:0]  data_temp;
    reg [7:0]  crc_low, crc_high;
    reg [1:0]  state;

    localparam WAIT_DATA = 2'b00,
               WAIT_CRC1 = 2'b01,
               WAIT_CRC2 = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= WAIT_DATA;
            decrypted_data <= 8'd0;
            crc_calc <= 16'h0000;
            crc_ok <= 1'b0;
        end
        else if (ciphertext_valid && keystream_valid_d) begin
            case (state)
                WAIT_DATA: begin
                    decrypted_data <= ciphertext ^ keystream_byte;
                    data_temp = ciphertext ^ keystream_byte;
                    next_crc = crc_calc ^ (data_temp << 8);
                    repeat (8) begin
                        next_crc = (next_crc[15]) ? (next_crc << 1) ^ 16'h8005 : (next_crc << 1);
                    end
                    crc_calc <= next_crc;
                    state <= WAIT_CRC1;
                end

                WAIT_CRC1: begin
                    crc_low <= ciphertext ^ keystream_byte;
                    state <= WAIT_CRC2;
                end

                WAIT_CRC2: begin
                    crc_high <= ciphertext ^ keystream_byte;
                    if ({ciphertext ^ keystream_byte, crc_low} == crc_calc) begin
                        crc_ok <= 1'b1;
                        $display("CRC OK: %h", crc_calc);
                    end else begin
                        crc_ok <= 1'b0;
                        $display("CRC ERROR! expected=%h got=%h",
                                 crc_calc, {ciphertext ^ keystream_byte, crc_low});
                        crc_calc <= 16'h0000; // re-sync
                    end
                    state <= WAIT_DATA;
                end
            endcase
        end
        else if (message_done) begin
            crc_calc <= 16'h0000; // reset CRC after each message
        end
    end
endmodule