`timescale 1ns / 1ns
module top_test();

	reg clk, reset;
	wire spi_cs, spi_clk, spi_mosi;
	wire [2:0] leds;

	master_top master (
		.clk(clk),
		.reset(reset),
		.spi_cs(spi_cs),         
    	.spi_clk(spi_clk),
		.spi_mosi(spi_mosi),
		.leds(leds)
	);

	initial clk = 0;
    initial forever #18.5185 clk = ~clk;

    initial 
	begin
        reset = 1;
        #100;
        reset = 0;
    end

    initial 
	begin
        $monitor("Time = %t, reset = %b, spi_cs = %b, spi_clk = %b, spi_mosi = %b, leds = %b",
                 $time, reset, spi_cs, spi_clk, spi_mosi, leds);
    end

    initial #3_000_000 $finish;

    initial 
	begin
        $dumpfile("master_top.vcd");
        $dumpvars(0, top_test);
    end

endmodule