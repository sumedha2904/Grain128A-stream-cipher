`timescale 1ns / 1ps

module sender (
    input wire clk,
    input wire rst,
    input wire init,
    input [127:0] key,
    input [95:0]  IV,
    input [7:0]   plaintext_in,
    input wire    data_valid,
    output reg [7:0]  ciphertext_out,
    output reg        ciphertext_valid,
    output wire [7:0] keystream_byte,
    output wire       keystream_valid,
    output reg [15:0] crc_out,
    output reg        message_done   
);

    reg [7:0] plaintext_reg;
    reg [1:0] send_state;
    reg keystream_valid_d;
    reg crc_phase;

    grain_128a_stream_cipher u_grain_128a_stream_cipher(
        .clk(clk),
        .rst(rst),
        .key(key),
        .IV(IV),
        .keystream_byte(keystream_byte),
        .init(init),
        .keystream_valid(keystream_valid)
    );

    always @(posedge clk or posedge rst) begin
        if (rst)
            keystream_valid_d <= 1'b0;
        else
            keystream_valid_d <= keystream_valid;
    end

    // --- CRC (bitwise, unrolled)
    reg [15:0] crc_calc, next_crc;
    reg [7:0] data_temp;

    always @(posedge clk or posedge rst) begin
        if (rst)
            crc_calc <= 16'h0000;
        else if (data_valid) begin
            data_temp = plaintext_in;
            next_crc = crc_calc ^ (data_temp << 8);
            repeat (8) begin
                next_crc = (next_crc[15]) ? (next_crc << 1) ^ 16'h8005 : (next_crc << 1);
            end
            crc_calc <= next_crc;
        end
    end

    always @(*) crc_out = crc_calc;

    // --- FSM
    localparam IDLE = 2'b00, SEND_DATA = 2'b01, SEND_CRC = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            send_state <= IDLE;
            ciphertext_out <= 8'b0;
            ciphertext_valid <= 1'b0;
            crc_phase <= 1'b0;
            message_done <= 1'b0;
        end else begin
            message_done <= 1'b0;
            case (send_state)
                IDLE: begin
                    ciphertext_valid <= 1'b0;
                    if (data_valid) begin
                        plaintext_reg <= plaintext_in;
                        send_state <= SEND_DATA;
                    end
                end

                SEND_DATA: begin
                    if (keystream_valid_d) begin
                        ciphertext_out <= plaintext_reg ^ keystream_byte;
                        ciphertext_valid <= 1'b1;
                        send_state <= SEND_CRC;
                        $display("Time=%0t | keystream=%h | plaintext=%h | ciphertext=%h",
                                 $time, keystream_byte, plaintext_reg, plaintext_reg ^ keystream_byte);
                    end
                end

                SEND_CRC: begin
                    if (keystream_valid_d) begin
                        ciphertext_valid <= 1'b1;
                        if (!crc_phase) begin
                            ciphertext_out <= crc_out[7:0] ^ keystream_byte;
                            crc_phase <= 1'b1;
                        end else begin
                            ciphertext_out <= crc_out[15:8] ^ keystream_byte;
                            crc_phase <= 1'b0;
                            send_state <= IDLE;
                            message_done <= 1'b1; // signal end of transmission
                        end
                    end
                end
            endcase
        end
    end
endmodule