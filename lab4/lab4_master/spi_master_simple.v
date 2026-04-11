module spi_master_simple #(
    parameter SYS_CLK_FREQ = 27_000_000, // Системная частота: 27 МГц
    parameter SPI_BITRATE = 10, // Скорость SPI: 10 бит/с
    parameter DATA_WIDTH = 8 // Ширина данных: 8 бит
)(
// Входы
    input wire clk_sys, // Системный тактовый сигнал
    input wire reset, // Сброс
    input wire start_pulse, // Импульс запуска передачи
    input wire [DATA_WIDTH-1:0]tx_data, // Данные для передачи
// Выходы (интерфейсные сигналы SPI)
    output reg spi_cs_n, // Chip Select (активный низкий)
    output reg spi_clk, // Тактовый сигнал
    output reg spi_mosi, // Данные от мастера

// Выходы (отладочные)
    output wire dbg_cs, // Отладка CS
    output wire dbg_clk, // Отладка тактового сигнала
    output wire dbg_mosi // Отладка данных
);

// Делитель тактовой частоты: 27МГц / 10 Гц = 2,700,000 тактов на бит
// Для 50% скважности переключаем уровень каждые 1,350,000 тактов
    localparam CLK_DIV_MAX = (SYS_CLK_FREQ / SPI_BITRATE / 2) - 1;
    reg [21:0] clk_div_cnt; // Счётчик делителя (22 бита достаточно для 1.35 млн)
    reg spi_clk_toggle; // Флаг переключения тактового сигнала
    reg [3:0] bit_cnt; // Счётчик переданных бит (0-8)
    reg [7:0] shift_reg; // Регистр сдвига для передачи данных
    // Состояния конечного автомата
    localparam S_IDLE = 2'd0, // Простой (ожидание запуска)
        S_START = 2'd1, // Начало передачи (активация CS)
        S_SHIFT = 2'd2, // Передача битов
        S_STOP = 2'd3; // Завершение передачи (деактивация CS)
    reg [1:0] state; // Текущее состояние автомата (2 бита для 4 состояний)
    reg busy; // Флаг занятости (не используется в данной реализации)
    always @(posedge clk_sys) begin
        if (reset) begin
            clk_div_cnt <= 0;
        spi_clk_toggle <= 0;
        end 
        else if (state != S_IDLE) begin // Генерируем такт только во время передачи
            if (clk_div_cnt >= CLK_DIV_MAX) begin
                clk_div_cnt <= 0;
                spi_clk_toggle <= ~spi_clk_toggle; // Переключаем уровень
            end
            else begin
                clk_div_cnt <= clk_div_cnt + 1;
            end
        end
    end
    always @(posedge clk_sys) begin
        if (reset) begin
            state <= S_IDLE;
            busy <= 0;
            spi_cs_n <= 1'b1; // CS неактивен (высокий)
            spi_clk <= 1'b0; // CLK покоится на 0
            spi_mosi <= 1'b0;
            bit_cnt <= 0;
            shift_reg <= 0;
        end
        else begin
            case (state)
                S_IDLE: begin
                    if (start_pulse) begin
                        shift_reg <= tx_data; // Загружаем данные в регистр сдвига
                        bit_cnt <= 0; // Сбрасываем счётчик битов
                        state <= S_START; // Переходим к началу передачи
                        busy <= 1;
                    end
                end
                S_START: begin
                    spi_cs_n <= 1'b0; // Активируем CS (низкий уровень)
                    state <= S_SHIFT; // Переходим к передаче данных
                end
                S_SHIFT: begin
                    spi_clk <= spi_clk_toggle; // Выводим тактовый сигнал на пин
                    // В режиме 0 (CPHA=0) данные выставляются на спадающем фронте
                    if (spi_clk_toggle == 1'b0 && clk_div_cnt == 0) begin
                        spi_mosi <= shift_reg[7]; // MSB first - старший бит первым
                        shift_reg <= {shift_reg[6:0], 1'b0}; // Сдвиг влево
                        bit_cnt <= bit_cnt + 1'b1; // Инкремент счётчика
                    end
                    // Передали 8 бит?
                    if (bit_cnt == 8 && spi_clk_toggle == 1'b1) begin
                        state <= S_STOP;
                    end
                end
                S_STOP: begin
                    spi_cs_n <= 1'b1; // Деактивируем CS
                    spi_clk <= 1'b0; // Возвращаем такт в 0
                    busy <= 0;
                    state <= S_IDLE; // Возвращаемся в ожидание
                end
            endcase
        end
    end 
    // Выходы для отладки (прямое подключение к светодиодам)
    assign dbg_cs = ~spi_cs_n; // Инвертируем, чтобы 1 = активен
    assign dbg_clk = spi_clk;
    assign dbg_mosi = spi_mosi; // Выводим вход MISO на светодиод
endmodule