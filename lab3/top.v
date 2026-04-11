module top(
	input wire clk,
	input wire reset_n,
	output reg [6:0] seg,
	output reg dig0,
	output reg dig1
);
	wire reset;
	assign reset = ~reset_n;
	reg [31:0] update_counter;
	reg [15:0] mux_counter;
	reg current_digit;
	reg lfsr_tick;
	wire [7:0] random_value;

	lfsr8 #(
		.SEED(8'h01),
		.POLYNOMIAL(8'h69)
	) lfsr_inst (
		.clk(clk),
		.reset(reset),
		.enable(lfsr_tick),
		.random_value(random_value)
	);

	reg [7:0] display_value;
	always @(posedge clk) begin
		if (reset) begin
			update_counter <= 0;
			lfsr_tick <= 0;
			display_value <= 8'h00;
		end
		else begin
		if (update_counter == 32'd26_999_999) begin
			update_counter <= 0;
			lfsr_tick <= 1;
		end
		else begin
			update_counter <= update_counter + 1;
			lfsr_tick <= 0;
		end
		if (lfsr_tick)
			display_value <= random_value;
		end
	end
	always @(posedge clk) begin
		if (reset) begin
			mux_counter <= 0;
			current_digit <= 0;
		end
		else begin
			if (mux_counter == 16'd13_499) begin
				mux_counter <= 0;
				current_digit <= ~current_digit;
			end
			else begin
				mux_counter <= mux_counter + 1;
			end
		end
	end

	wire [3:0] hex_nibble;
	wire [6:0] seg_decoded;

	assign hex_nibble = (current_digit == 1'b0)?display_value[3:0]:display_value[7:4];

	hex_to_7seg decoder_inst (
		.hex_digit(hex_nibble),
		.segments(seg_decoded)
	);

	always @(posedge clk) begin
		if (reset) begin
			seg <= 7'b1111111;
			dig0 <= 1'b1;
			dig1 <= 1'b1;
		end
		else begin
			seg <= seg_decoded;
			dig0 <= (current_digit == 1'b0) ? 1'b0 : 1'b1;
			dig1 <= (current_digit == 1'b1) ? 1'b0 : 1'b1;
		end
	end
endmodule