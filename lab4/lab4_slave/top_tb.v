`timescale 1ns / 1ns

module tb_top_slave();

    // Параметры
    localparam CLK_PERIOD = 37.037; // 27 МГц
    localparam SPI_PERIOD = 1000;   // 1 МГц (для быстрой симуляции)
    localparam SPI_HALF   = SPI_PERIOD / 2;

    // Сигналы для подключения к top_slave
    reg  clk = 0;
    reg  reset_n;
    reg  spi_cs;
    reg  spi_clk;
    reg  spi_mosi;
    wire [6:0] seg;
    wire dig0;
    wire dig1;
    wire [2:0] leds;

    // Тестовые байты
    reg [7:0] test_byte1 = 8'hAA; // 10101010

    top_slave uut (
        .clk      (clk),
        .reset_n  (reset_n),
        .spi_cs   (spi_cs),
        .spi_clk  (spi_clk),
        .spi_mosi (spi_mosi),
        .seg      (seg),
        .dig0     (dig0),
        .dig1     (dig1),
        .leds     (leds)
    );

    // Генерация тактового сигнала
    initial forever #(CLK_PERIOD/2) clk = ~clk;

    // Задача отправки байта по SPI (режим 0, MSB first)
    task spi_send_byte(input [7:0] data);
        integer i;
        begin
            // Начало: CS активен, такт в 0, выставляем первый бит
            spi_cs = 0;                    // CS низкий
            spi_mosi = data[7];              // старший бит
            #(SPI_HALF);                      // половина периода до первого растущего фронта

            for (i = 6; i >= 0; i = i - 1) begin
                spi_clk = 1;                  // растущий фронт (сэмплирование)
                #(SPI_HALF);
                spi_clk = 0;                  // спадающий фронт (смена данных)
                #(SPI_HALF);
                spi_mosi = data[i];            // следующий бит
            end

            // Завершаем тактирование: последний растущий фронт для бита 0
            spi_clk = 1;
            #(SPI_HALF);
            spi_clk = 0;
            #(SPI_HALF/2);                     // небольшая задержка перед деактивацией CS

            spi_cs = 1;                         // CS высокий (конец передачи)
            #(SPI_PERIOD);                       // пауза между передачами
        end
    endtask

    // Функция преобразования 4-битного hex в 7-сегментный код (активный низкий)
    function [6:0] hex_to_segments;
        input [3:0] hex;
        begin
            case (hex)
                4'h0: hex_to_segments = 7'b0111111;
				4'h1: hex_to_segments = 7'b0000110;
				4'h2: hex_to_segments = 7'b1011011;
				4'h3: hex_to_segments = 7'b1001111;
				4'h4: hex_to_segments = 7'b1100110;
				4'h5: hex_to_segments = 7'b1101101;
				4'h6: hex_to_segments = 7'b1111101;
				4'h7: hex_to_segments = 7'b0000111;
				4'h8: hex_to_segments = 7'b1111111;
				4'h9: hex_to_segments = 7'b1101111;
				4'hA: hex_to_segments = 7'b1110111;
				4'hB: hex_to_segments = 7'b1111100;
				4'hC: hex_to_segments = 7'b0111001;
				4'hD: hex_to_segments = 7'b1011110;
				4'hE: hex_to_segments = 7'b1111001;
				4'hF: hex_to_segments = 7'b1110001;
				default: hex_to_segments = 7'b0000000;
            endcase
        end
    endfunction



    // Проверка отображаемого значения
    task check_display(input [7:0] expected);
        integer timeout;
        reg [6:0] expected_lo, expected_hi;
        begin
            expected_lo = hex_to_segments(expected[3:0]);
            expected_hi = hex_to_segments(expected[7:4]);

            // Ждём переключения дисплеев, чтобы увидеть оба nibble
            timeout = 0;
            // Проверяем младшую цифру (dig0 = 0)
            while (dig0 !== 1'b0 && timeout < 50000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 50000) begin
                $display("Timeout waiting for dig0 active");
            end else begin
                // Сравниваем сегменты на этом же такте (они уже установлены)
                if (seg !== expected_lo) begin
                    $display("FAIL: dig0 active, expected seg %b for 0x%1h, got %b", 
                              expected_lo, expected[3:0], seg);
                end else begin
                    $display("PASS: dig0 shows 0x%1h", expected[3:0]);
                end
            end

            // Ждём переключения на старшую цифру (dig1 = 0)
            timeout = 0;
            while (dig1 !== 1'b0 && timeout < 50000) begin
                @(posedge clk);
                timeout = timeout + 1;
            end
            if (timeout >= 50000) begin
                $display("Timeout waiting for dig1 active");
            end else begin
                if (seg !== expected_hi) begin
                    $display("FAIL: dig1 active, expected seg %b for 0x%1h, got %b", 
                              expected_hi, expected[7:4], seg);
                end else begin
                    $display("PASS: dig1 shows 0x%1h", expected[7:4]);
                end
            end
        end
    endtask

    // Основной тест
    initial begin
        // Инициализация
        reset_n = 0;
        spi_cs = 1;
        spi_clk = 0;
        spi_mosi = 0;

        // Сброс
        #(CLK_PERIOD*10);
        reset_n = 1;
        #(CLK_PERIOD*10);

        // Проверка начального состояния (должно быть 0x00)
        $display("=== Check initial display (should be 0x00) ===");
        check_display(8'h00);

        // === Передача первого байта ===
        $display("=== Sending first byte: 0x%h ===", test_byte1);
        spi_send_byte(test_byte1);

        // Даём время на обработку и обновление индикаторов
        #(CLK_PERIOD*20);

        // Проверка отображения первого байта
        $display("=== Check display after first byte ===");
        check_display(test_byte1);

        // Завершение симуляции
        #(CLK_PERIOD*100);
        $display("=== Simulation finished ===");
        $finish;
    end

    // Мониторинг изменений (для отладки)
    initial begin
        $monitor("Time = %t, reset_n=%b, cs=%b, clk=%b, mosi=%b, seg=%b, dig0=%b, dig1=%b, leds=%b",
                 $time, reset_n, spi_cs, spi_clk, spi_mosi, seg, dig0, dig1, leds);
    end

    initial begin
        $dumpfile("tb_top_slave.vcd");
        $dumpvars(0, tb_top_slave);
    end

endmodule