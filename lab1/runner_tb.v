`timescale 1ns / 1ns

module test();
	reg clk;
	reg reset;
	wire [5:0] leds;

	top r(.clk(clk), .reset(reset), .led(leds));

	initial	begin
		clk = 0;
		reset = 1;
		#20 reset = 0;
		#20 reset = 1;
	end

	initial forever #(5) clk = !clk;
	initial #1000 $finish;

	initial	begin
		$dumpfile("runner_out.vcd");
		$dumpvars(0, test);
	end
endmodule
