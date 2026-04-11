module top_master( 
    input  wire clk,            
    input  wire reset_n,        
    output wire spi_cs,         
    output wire spi_clk,        
    output wire spi_mosi,      
    output wire [2:0] leds      
); 
    wire reset = ~reset_n;
    wire [7:0] random_value;
    wire dbg_cs, dbg_clk, dbg_mosi; 

    reg [31:0] update_counter; 
    reg lfsr_enable; 
    reg start_pulse_reg; 

    always@(posedge clk) begin 
        if(reset) begin 
            update_counter <= 0; 
            lfsr_enable <= 0; 
            start_pulse_reg <= 0; 
        end else begin 
            lfsr_enable <= 0; 
            start_pulse_reg <= 0; 
            if(update_counter == 32'd26_999_999) begin 
                update_counter <= 0; 
                lfsr_enable <= 1; 
                start_pulse_reg <= 1; 
            end else begin 
                update_counter <= update_counter + 1; 
            end 
        end 
    end

    lfsr8#(.SEED(8'h01), .POLYNOMIAL(8'h69)) lfsr_inst( 
        .clk(clk), 
        .reset(reset), 
        .enable(lfsr_enable), 
        .random_value(random_value) 
    ); 

    spi_master_simple#( 
        .SYS_CLK_FREQ(27_000_000), 
        .SPI_BITRATE(30), 
        .DATA_WIDTH(8) 
    ) spi_inst( 
        .clk_sys(clk), 
        .reset(reset), 
        .start_pulse(start_pulse_reg), 
        .tx_data(random_value), 
        .spi_cs_n(spi_cs), 
        .spi_clk(spi_clk), 
        .spi_mosi(spi_mosi),  
        .dbg_cs(dbg_cs), 
        .dbg_clk(dbg_clk), 
        .dbg_mosi(dbg_mosi) 
    ); 

    assign leds[0] = dbg_cs; 
    assign leds[1] = dbg_clk; 
    assign leds[2] = dbg_mosi; 

endmodule