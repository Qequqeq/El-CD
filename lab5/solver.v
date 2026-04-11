//  dx/dt = 0.9 - y, dy/dt = 0.4 + z, dz/dt = xy - z
// dx/dt = A - y, dy/dt = B + z, dz/dt = xy - z
module ode_solver #(
	parameter [31:0] STEP = 32'h000000A3, //Шаг интегрирования
	parameter [31:0] A = 32'h0000E666, //Первый коэффициент 0.9
	parameter [31:0] B = 32'h00006666  //Второй коэффициент 0.4
)(
	input clk, // тактовый сигнал
	input reset, // сброс в начальное состояние
	input enable, // разрешение итерации
	output reg signed [31:0] x,y,z // выходная переменная
);
	reg signed [31:0] dx, dy, dz; // производные
	reg signed [63:0] temp; // для промежуточных

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			x = 32'hFFFF8DD6; //-0.444
			y = 32'h00011C4B; //1.111
			z = 32'hFFFF999A; //-0.4
		end
		else if (enable) begin
			dx = A - y;
			dy = B + z;
			temp = $signed(x) * $signed(y);
			dz = (temp >>> 16) - z;
			
			temp = $signed(STEP) * $signed(dx);
			x = x + (temp >>> 16);
			temp = $signed(STEP) * $signed(dy);
			y = y + (temp >>> 16);
			temp = $signed(STEP) * $signed(dz);
			z = z + (temp >>> 16);
		end
	end
endmodule