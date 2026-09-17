`timescale 1ns / 1ps

module channel(
	input wire clk,
	input wire rst,
	input [15:0] error_mask,
	input [15:0] data_in,
	input wire out_ready, in_valid,
	output reg in_ready, out_valid,
	output reg [15:0] data_out,
	input sender_init,
    input receiver_init
);

	// --- LFSR for dynamic error injection ---
    reg [15:0] lfsr_state;

    // LFSR parameters
    localparam [15:0] TAPS = 16'hB400;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            lfsr_state <= 16'h1; // initial seed (cannot be 0)
        else begin
            // Galois LFSR update
            if (lfsr_state[0])
                lfsr_state <= (lfsr_state >> 1) ^ TAPS;
            else
                lfsr_state <= (lfsr_state >> 1);
        end
    end

	always@(*) begin
		if(in_valid) begin 
			if(out_ready) begin
				data_out = data_in ^ lfsr_state;
				out_valid = 1;
				in_ready = 1;
			end
			else begin 
				data_out = 16'b0;
				out_valid = 0;
				in_ready = 0;
			end
		end
		else begin
			data_out = 16'b0;
			out_valid = 0;
			in_ready = 1;
		end
	end
endmodule 