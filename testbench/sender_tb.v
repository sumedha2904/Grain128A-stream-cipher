`timescale 1ns / 1ps
//-------------------------------------------------------------
// TESTBENCH for sender
//-------------------------------------------------------------

module sender_tb();


reg clk;
reg rst;
reg init;
reg [127:0] key;
reg [95:0] IV;


wire [7:0] keystream_byte;
wire keystream_valid;


wire [7:0] ciphertext_out;
wire ciphertext_valid;
// instantiate sender
sender uut (
.clk(clk),
.rst(rst),
.init(init),
.key(key),
.IV(IV),
.plaintext_in(8'h00),
.data_valid(1'b0),
.ciphertext_out(ciphertext_out),
.ciphertext_valid(ciphertext_valid),
.keystream_byte(keystream_byte),
.keystream_valid(keystream_valid),
.crc_out() // unused here
);


always #5 clk = ~clk;


initial begin
clk = 0;
rst = 1;
init = 0;
#20;
rst = 0;


// exercise keystream only
init = 1; #40; init = 0;


// drive one plaintext to observe encryption
#200;


$finish;
end


always @(posedge clk) begin
if (ciphertext_valid)
$display("Time=%0t ns | Ciphertext Byte = %02h", $time, ciphertext_out);
end


endmodule