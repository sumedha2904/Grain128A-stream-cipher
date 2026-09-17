`timescale 1ns / 1ps

module tb_channel;

    reg clk;
    reg rst;
    reg [15:0] data_in;
    reg in_valid;
    reg out_ready;
    
    wire in_ready;
    wire out_valid;
    wire [15:0] data_out;

	reg sender_init, receiver_init;
    // Instantiate channel
    channel uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .out_ready(out_ready),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .out_valid(out_valid),
        .data_out(data_out),
		.sender_init(sender_init),
		.receiver_init(receiver_init)
    );
	
	// add somewhere in the testbench (after uut instances exist)
	/*always @(posedge clk) begin
		// print sender's internal keystream (if sender inst name u_sender etc.)
		// adjust hierarchical path to match your instance names
		$display("HIER: Sender keystream_byte = %h | valid = %b",uut_sender.keystream_byte,uut_sender.keystream_valid);

		$display("HIER: Receiver keystream_byte = %h | valid = %b",uut_receiver.keystream_byte,uut_receiver.keystream_valid);
	end
	*/

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock period = 10ns

    // Test sequence
    initial begin
        // Initialize signals
        rst = 0;
        data_in = 16'h0000;
        in_valid = 0;
        out_ready = 0;

        // Apply reset
        #12 rst = 1;
		
		#10 receiver_init = 1;
		#20 sender_init = 1;


        // Send first data
        #10;
        data_in = 16'hAAAA;
        in_valid = 1;
        out_ready = 1;

        #10;
        data_in = 16'h5555;

        #10;
        in_valid = 0; // no new data
        out_ready = 1;

        #20;
        // Send second data
        in_valid = 1;
        data_in = 16'h1234;

        #10;
        out_ready = 0; // receiver not ready

        #10;
        out_ready = 1; // receiver ready again

        #20;
        in_valid = 0;

        #20;
        $finish;
    end

    // Monitor signals
    initial begin
        $monitor("Time=%0t | data_in=%h | data_out=%h | in_valid=%b | out_ready=%b | in_ready=%b | out_valid=%b", 
                  $time, data_in, data_out, in_valid, out_ready, in_ready, out_valid);
    end

endmodule
