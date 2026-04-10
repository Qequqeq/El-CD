module top (
	input clk,
	input reset,
	output reg [5:0] led
);
	reg [31:0] counter;
	always @(posedge clk) begin
		if (!reset) begin
			counter <= 0;
			led <= 6'b111110;
		end else begin
			counter <= counter + 1;
			if (counter == 4_500_000) begin
				counter <= 0;
				led <= led == 6'b011111 ? 6'b111110 : {led[4:0], 1'b1};
			end
		end
	end
endmodule
