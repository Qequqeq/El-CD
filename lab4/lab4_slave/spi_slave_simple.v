module spi_slave_simple #(
    parameter DATA_WIDTH = 8
)(
    input wire clk_sys,
    input wire reset,
    input wire spi_cs_n,
    input wire spi_clk,
    input wire spi_mosi,
    output wire [DATA_WIDTH-1:0] rx_data,
    output wire data_valid
);
    // Синхронизация
    reg cs_sync1, cs_sync2, cs_n;
    reg clk_sync1, clk_sync2, sclk;
    reg mosi_sync1, mosi_sync2, mosi;
    always @(posedge clk_sys) begin
        cs_sync1   <= spi_cs_n;
        cs_sync2   <= cs_sync1;
        cs_n       <= cs_sync2;
        clk_sync1  <= spi_clk;
        clk_sync2  <= clk_sync1;
        sclk       <= clk_sync2;
        mosi_sync1 <= spi_mosi;
        mosi_sync2 <= mosi_sync1;
        mosi       <= mosi_sync2;
    end

    reg cs_prev, sclk_prev;
    wire cs_falling, cs_rising, sclk_rising;
    always @(posedge clk_sys) begin
        cs_prev   <= cs_n;
        sclk_prev <= sclk;
    end
    assign cs_falling = cs_prev & ~cs_n;
    assign cs_rising  = ~cs_prev & cs_n;
    assign sclk_rising = ~sclk_prev & sclk;

    reg [DATA_WIDTH-1:0] shift_reg;
    reg [3:0] bit_counter;
    reg [DATA_WIDTH-1:0] data_reg;
    reg data_valid_reg;

    always @(posedge clk_sys or posedge reset) begin
        if (reset) begin
            shift_reg      <= 0;
            bit_counter    <= 0;
            data_reg       <= 0;
            data_valid_reg <= 0;
        end else begin
            data_valid_reg <= 1'b0;
            if (cs_falling) begin
                bit_counter <= 0;
                shift_reg   <= 0;
            end
            if (~cs_n) begin
                if (sclk_rising && (bit_counter < DATA_WIDTH)) begin
                    shift_reg[DATA_WIDTH-1 - bit_counter] <= mosi;
                    bit_counter <= bit_counter + 1'b1;
                end
                if (bit_counter == DATA_WIDTH && sclk_rising) begin
                    data_reg       <= shift_reg;
                    data_valid_reg <= 1'b1;
                end
            end
            if (cs_rising) begin
                bit_counter <= 0;
            end
        end
    end
    assign rx_data    = data_reg;
    assign data_valid = data_valid_reg;
endmodule