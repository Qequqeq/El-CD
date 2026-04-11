`timescale 1ns/1ns
module freq_test();

	reg clk = 0;
	wire enable;

	divider div(
		.clk(clk),
		.enable(enable)
	);

	initial begin
		clk = 0;
		#15000 $finish;
	end

	initial forever #5 clk = ~clk;
	
	initial begin
		$dumpfile("divider_out.vcd");
		$dumpvars(0, freq_test);
	end
endmodule