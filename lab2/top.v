module top(
	input clk,
	input key1,
	input key2,
	output [5:0]  led
);
	reg [5:0] count;
	reg key1_d1, key1_d2;
	reg key2_d1, key2_d2;

	initial begin
		count = 6'd0;
	end

	always @(posedge clk) begin
		key1_d1 <= ~key1;
		key1_d2 <= key1_d1;
		key2_d1 <= ~key2;
		key2_d2 <= key2_d1;
	end

	wire key1_edge = key1_d1 & ~key1_d2;
	wire key2_edge = key2_d1 & ~key2_d2;
 
	always @(posedge clk) begin
		if (~key1 && ~key2) begin
		    count <= 6'd0;
		end
		else if (key1_edge) begin
			if (count < 6'd63) begin
				count <= count + 1'b1;
	    		end
		end
		else if (key2_edge) begin
			if (count > 6'h00) begin
				count <= count - 1'b1;
	    		end
		end
	end
endmodule
