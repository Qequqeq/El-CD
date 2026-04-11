`timescale 1ns / 1ns
module test();

	reg clk;
	reg reset;
	reg enable;
	wire [7:0] value;

	lfsr8 #(
		.SEED(8'hCD),
		.POLYNOMIAL(8'hD8)
	) lfsr_inst (
		.clk(clk),
		.reset(reset),
		.enable(enable),
		.random_value(value)
	);

	initial begin
		clk = 0;
		reset = 1;
		enable = 1;
		#10 reset = 0;
				
	end

	initial forever #5 clk = !clk;
	initial #3000 $finish;

	initial begin
		$dumpfile("random_out.vcd");
		$dumpvars(0, test);
	end
endmodule