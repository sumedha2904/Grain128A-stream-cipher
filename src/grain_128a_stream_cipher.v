`timescale 1ns / 1ps

module grain_128a_stream_cipher(
	input wire clk,
	input wire rst,
	input [127:0] key,
	input [95:0] IV,
	output reg [7:0] keystream_byte,
	input wire init,
	output reg keystream_valid
);
	parameter [95:0] DEFEAULT_IV = 96'hA56B4C3D2E1F12345678;

	reg [127:0] lfsr, nlfsr;
	reg [127:0] lfsr_next, nlfsr_next;
	wire keystream_bit;
	reg [7:0] buffer_byte;
	reg [2:0] bit_count;
	reg lfsr_feedback, nlfsr_feedback;
	
	always@(posedge clk) begin
		if(rst) begin
			lfsr <= 128'b0;
			nlfsr <= 128'b0;
		end 
		else if(init) begin 
			nlfsr <= key ^ 128'hC3D2E1F0123456789ABCDEF001122334;
			lfsr  <= {IV, 32'h00000000} ^ 128'h1F1E1D1C1B1A19181716151413121110;
		end
		else begin
			lfsr <= lfsr_next;
			nlfsr <= nlfsr_next;
		end
	end
	
	always@(*) begin
	
		lfsr_next = lfsr;
		nlfsr_next = nlfsr;
		
		lfsr_feedback = lfsr[0]^lfsr[26]^lfsr[56]^lfsr[91]^lfsr[96];	
		nlfsr_feedback = nlfsr[0]^nlfsr[27]^nlfsr[56]^nlfsr[91]^nlfsr[96]^(nlfsr[3]&nlfsr[67])^(nlfsr[11]&nlfsr[13])^(nlfsr[17]&nlfsr[18])^(nlfsr[27]&nlfsr[59])^(nlfsr[40]&nlfsr[48])^(nlfsr[61]&nlfsr[65])^(nlfsr[68]&nlfsr[84])^(lfsr[12]&nlfsr[8]);	
		
		lfsr_next = {lfsr[126:0], lfsr_feedback};
		nlfsr_next = {nlfsr[126:0], nlfsr_feedback};
	end

	assign keystream_bit = lfsr[12]^lfsr[95]^nlfsr[2]^(lfsr[90]&nlfsr[15])^(lfsr[91]&nlfsr[36])^(lfsr[92]&nlfsr[45])^(lfsr[93]&nlfsr[64])^(lfsr[94]&nlfsr[73])^(lfsr[96]&nlfsr[89]);
	
	always@(posedge clk) begin
		if(rst) begin 
			buffer_byte <= 8'b0;
			bit_count <= 0;
			keystream_byte <= 8'b0;
			keystream_valid <= 0;
		end 
		else begin 
			buffer_byte <= {buffer_byte[6:0], keystream_bit};
			
			if(bit_count == 3'd7) begin
				keystream_byte <= {buffer_byte[6:0], keystream_bit};
				keystream_valid <= 1'b1;
				bit_count <= 0;
			end
			else begin
				keystream_valid <= 0;
				bit_count <= bit_count + 1;
			end
		end
	end
endmodule