module top (
    input  wire       clk,
    input  wire       reset,
    output wire       uart_tx
);
    localparam CLK_FREQ_HZ = 27_000_000;
    localparam BAUD_RATE = 115_200;
    localparam DELAY_FRAMES = CLK_FREQ_HZ / BAUD_RATE;
    localparam SEND_INTERVAL = 20_000; // 50_000
    localparam BUF_SIZE = 5;
    localparam DIVIDER_VALUE = 1000;

    wire enable_solver;
    wire signed [31:0] x, y, z;
    wire [7:0] x_scaled;
    wire [23:0] ascii_htu;
    wire nReady_uart;

    reg  nEN_b2a = 1;
    reg  [7:0]  current_binary = 0;
    reg  [8*BUF_SIZE-1:0] uart_buffer = 0;
    reg  nEN_uart = 1;

    divider #(
        .DIV(DIVIDER_VALUE)
    ) freq_div (
        .clk(clk),
        .enable(enable_solver)
    );

    ode_solver solver (
        .clk(clk),
        .reset(reset),
        .enable(enable_solver),
        .x(x),
        .y(y),
        .z(z)
    );

    assign x_scaled = (z[31:16] + 8'd128) & 8'hFF;

    binary_to_ascii b2a (
        .nEnable(nEN_b2a),
        .binary_in(current_binary),
        .ascii_htu(ascii_htu)
    );

    uart_tx #(
        .DELAY_FRAMES(DELAY_FRAMES),
        .BUF_SIZE(BUF_SIZE)
    ) uart (
        .clk(clk),
        .buffer(uart_buffer),
        .nEN(nEN_uart),
        .uart_tx(uart_tx),
        .nReady(nReady_uart)
    );

    localparam S_IDLE        = 0;
    localparam S_CONVERT_X   = 1;
    localparam S_LATCH_ASCII = 2;   // новое состояние
    localparam S_WAIT_ASCII  = 3;
    localparam S_SEND        = 4;
    localparam S_SEND_WAIT   = 5;

    reg [2:0] state = S_IDLE;
    reg [31:0] wait_cnt = 0;
    
    

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S_IDLE;
            wait_cnt <= 0;
            nEN_b2a <= 1;
            nEN_uart <= 1;
            current_binary <= 0;
            uart_buffer <= 0;
        end else begin
        case (state)
            S_IDLE: begin
                if (wait_cnt >= SEND_INTERVAL) begin
                    wait_cnt <= 0;
                    state <= S_CONVERT_X;
                end else begin
                    wait_cnt <= wait_cnt + 1;
                end
            end

            S_CONVERT_X: begin
                current_binary <= x_scaled;
                nEN_b2a <= 1'b0;
                state <= S_LATCH_ASCII;      // переходим в захват
            end

            S_LATCH_ASCII: begin
                // в этом такте nEN_b2a всё ещё 0, ascii_htu стабилен
                uart_buffer[7:0]   <= ascii_htu[23:16];
                uart_buffer[15:8]  <= ascii_htu[15:8];
                uart_buffer[23:16] <= ascii_htu[7:0];
                uart_buffer[31:24] <= 8'h0D;
                uart_buffer[39:32] <= 8'h0A;
                state <= S_WAIT_ASCII;
            end

            S_WAIT_ASCII: begin
                nEN_b2a <= 1'b1;            // теперь можно деактивировать
                state <= S_SEND;
            end

            S_SEND: begin
                nEN_uart <= 1'b0;
                state <= S_SEND_WAIT;
            end

            S_SEND_WAIT: begin
                // Ждём, пока UART не сообщит о готовности (nReady == 0)
                if (nReady_uart == 1'b0) begin
                    nEN_uart <= 1'b1;       // поднимаем nEN только после завершения
                    state <= S_IDLE;
                end
            end

            default: state <= S_IDLE;
        endcase
    end
end
    
endmodule