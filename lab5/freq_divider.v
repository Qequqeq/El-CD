module divider #(
	parameter integer DIV = 1000 // делитель частоты
)(
	input wire clk,
	output reg enable = 0
);
	reg [15:0] counter = 0;
	always @(posedge clk) begin
		if (counter >= DIV - 1) begin
			counter <= 0;
			enable <= 1;
		end else begin
			counter <= counter + 1;
			enable <= 0;
		end
	end
endmodule