module binary_to_ascii (
	input wire nEnable,
	input wire [7:0] binary_in,
	output wire [23:0] ascii_htu
);	
	reg [3:0] hundreds;
	reg [3:0] tens;
	reg [3:0] units;

	assign ascii_htu[7: 0] = {4'b0011, hundreds};
	assign ascii_htu[15: 8] = {4'b0011, tens};
	assign ascii_htu[23:16] = {4'b0011, units};

	always @(negedge nEnable) begin
		hundreds <= binary_in / 8'd100;
		tens <= (binary_in % 8'd100) / 8'd10;
		units <= binary_in % 8'd10;
	end
endmodule