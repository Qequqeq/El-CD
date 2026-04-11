module uart_tx #(
	parameter DELAY_FRAMES = 234,
	parameter BUF_SIZE = 5
)(
	input clk,
	input [8*BUF_SIZE-1:0] buffer,
	input nEN,
	output uart_tx,
	output reg nReady
);

	reg [3:0] txState = 0;
	reg [24:0] txCounter = 0;
	reg [7:0] dataOut = 0;
	reg txPinRegister = 1;
	reg [2:0] txBitNumber = 0;
	reg [3:0] txByteCounter = 0;

	assign uart_tx = txPinRegister;

	localparam TX_STATE_IDLE = 0;
	localparam TX_STATE_START_BIT = 1;
	localparam TX_STATE_WRITE = 2;
	localparam TX_STATE_STOP_BIT = 3;

	integer i;

	always @(posedge clk ) begin
		case (txState)
			TX_STATE_IDLE: begin
				if (nEN == 0) begin
					txState <= TX_STATE_START_BIT;
					txCounter <= 0;
					txByteCounter <= 0;
				end else begin
					txPinRegister <= 1;
				end
				nReady <= 1;
			end

		TX_STATE_START_BIT: begin
			txPinRegister <= 0; // START bit = LOW
			if ((txCounter + 1) == DELAY_FRAMES) begin
				txState <= TX_STATE_WRITE;
	// Загружаем байт в буфер передачи
				for (i = 0; i < 8; i = i + 1)
				dataOut[i] <= buffer[txByteCounter * 8 + i];
				txBitNumber <= 0;
				txCounter <= 0;
			end else
				txCounter <= txCounter + 1;
			end

		TX_STATE_WRITE: begin
			txPinRegister <= dataOut[txBitNumber];
			if ((txCounter + 1) == DELAY_FRAMES) begin
				if (txBitNumber == 3'd7)
					txState <= TX_STATE_STOP_BIT;
				else begin
					txBitNumber <= txBitNumber + 1;
				end
				txCounter <= 0;
			end else
			txCounter <= txCounter + 1;
		end

		TX_STATE_STOP_BIT: begin
			txPinRegister <= 1; // STOP bit = HIGH

			if ((txCounter + 1) == DELAY_FRAMES) begin
				if (txByteCounter == BUF_SIZE - 1) begin
					txState <= TX_STATE_IDLE;
					nReady <= 0; // сигнал окончания
				end else begin
					txByteCounter <= txByteCounter + 1;
					txState <= TX_STATE_START_BIT;
				end
				txCounter <= 0;
			end else
				txCounter <= txCounter + 1;
			end
		endcase
	end
endmodule