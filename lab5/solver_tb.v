`timescale 1ns/1ns
module solver_test();
	reg clk = 0;
	reg reset = 0;
	reg enable = 1;
	wire signed [31:0] x, y, z;
	reg signed [31:0] t = 32'd0;
	
	localparam reg signed [31:0] STEP = 32'h000000A3;

	integer out_file;

	ode_solver slv(
		.clk(clk),
		.reset(reset),
		.enable(enable),
		.x(x),
		.y(y),
		.z(z));
	initial 
	begin
		reset = 1; #10; reset = 0;
	end
	
    initial forever #5 clk = ~clk;

	always @(x) begin
		t <= t + STEP;
		$fdisplay(out_file, "%b;%b;%b;%b", x, y, z, t);
	end

	initial begin
		out_file = $fopen("C:\\Gowin\\FPGAProj\\lab5\\output.txt", "w+");
        if (out_file == 0) begin
            $display("Error with open!");
            $finish;
        end
		$fdisplay(out_file, "x;y;z;time");
        #500000;
        $fclose(out_file);
        $finish;
	end
	initial	
		begin
		$dumpfile("solver_test_out.vcd");
		$dumpvars(0, solver_test);
	end	
endmodule