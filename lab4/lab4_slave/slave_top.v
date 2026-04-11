module top_slave( 
    input  wire clk,            // 27 MHz
    input  wire reset_n,        // Кнопка сброса (активный низкий)
    input  wire spi_cs,         // Pin 34
    input  wire spi_clk,        // Pin 40
    input  wire spi_mosi,       // Pin 35
    output reg  [6:0] seg,
    output wire dig0,
    output wire dig1,    
    output wire [2:0] leds      // Отладочные светодиоды
); 
    wire reset = ~reset_n; 
    wire [7:0] rx_data; 
    wire data_valid; 

    // 3 светодиода для SPI отладки
    assign leds[0] = ~spi_cs; 
    assign leds[1] = spi_clk; 
    assign leds[2] = spi_mosi; 

    spi_slave_simple#(.DATA_WIDTH(8)) spi_inst( 
        .clk_sys(clk), 
        .reset(reset), 
        .spi_cs_n(spi_cs), 
        .spi_clk(spi_clk), 
        .spi_mosi(spi_mosi), 
        .rx_data(rx_data), 
        .data_valid(data_valid) 
    ); 

    // Регистр хранения принятых данных
    reg [7:0] display_value; 
    always @(posedge clk) begin 
        if (reset) 
            display_value <= 8'h00; 
        else if (data_valid) 
            display_value <= rx_data; 
    end

    // Мультиплексирование индикаторов (~1 кГц)
    reg [15:0] mux_counter; 
    reg current_digit = 0; 
    
    always@(posedge clk) begin 
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
    
    assign hex_nibble = (current_digit == 1'b0) ? 
    display_value[3:0] : display_value[7:4]; 

    hex_to_7seg decoder_inst( 
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