`timescale 1ns/1ns
module uart_test();

	reg clk;
	reg [39:0] data;
	reg nEnable;
	wire uart_tx;
	wire nReady;
	reg [5:0] counter = 6'd0;

	uart_tx #(
		.DELAY_FRAMES(1),
		.BUF_SIZE(5)
		) uartik (
		.clk(clk),
		.buffer(data),
		.nEN(nEnable),
		.uart_tx(uart_tx),
		.nReady(nReady));
	
	initial begin 
		data = 40'b1011001110100011010111100010010101101011;
		clk = 0;
		nEnable = 1;
		#10;
		nEnable = 0;
	end

	initial forever #5 clk = ~clk;

	initial begin
		$dumpfile("uart_test_out.vcd");
		$dumpvars(0, uart_test);
	end

	always @(uartik.txBitNumber) begin
		if (counter != 6'd0 && counter != 6'd40) begin
			$display("Sent %d bit: %b (%b)", counter, uart_tx, data[counter - 1]);
		end 
		else begin
			if (counter == 0) begin
				$display("Sent start bit: %b (1)", uart_tx);
			end
			if (counter == 6'd40) begin
				$display("Sent stop bit: %b (0)", uart_tx);
			end
		end
		counter <= counter + 1;

		if (counter == 6'd40) begin
			$display("Sending was finished");
			$finish;
		end
	end
endmodule