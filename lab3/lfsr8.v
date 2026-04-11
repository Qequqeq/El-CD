module lfsr8 #(
parameter SEED = 8'h01,
parameter POLYNOMIAL = 8'h69 //нужно отзеркалить
)(
	input wire clk,
	input wire reset,
	input wire enable,
	output wire [7:0] random_value
);
	reg [7:0] lfsr_reg;
	wire feedback;
	assign feedback = ^(lfsr_reg & POLYNOMIAL);
	assign random_value = lfsr_reg;

	always @(posedge clk) begin
		if (reset)
			lfsr_reg <= SEED;
		else if (enable)
		lfsr_reg <= {feedback, lfsr_reg[7:1]};
	end
endmodule