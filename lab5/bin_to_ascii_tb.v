module ascii_test();
    reg clk;
    reg [7:0] binary_in;
    wire [39:0] buffer;
    reg [39:0] excepted;
    reg [31:0] vectornum;
    reg [31:0] errors;
    reg [47:0] testvectors[255:0];

    // Генератор тактов: начинаем с 1, чтобы первый negedge был через 5 ns
    initial clk = 1;
    always #5 clk = ~clk;

    binary_to_ascii bta(clk, binary_in, buffer);

    initial begin
        $readmemb("C:\\Gowin\\FPGAProj\\lab5\\ASCIItest.tv", testvectors);
        vectornum = 0;
        errors = 0;
        // Принудительно убираем Z
        force ascii_test.buffer = 40'b0;
        #1 release ascii_test.buffer;
        // Загружаем первый вектор
        {binary_in, excepted} = testvectors[0];
        vectornum = 1;
        // Ждём первый negedge, чтобы модуль вычислил значения
        @(negedge clk);
    end

    // Проверка по положительному фронту
    always @(posedge clk) begin
		#2;
        if (buffer !== excepted) begin
            $display("Error with value %b = %d", binary_in, binary_in);
            $display("Out: %b", buffer);
            $display("Exc: %b", excepted);
            errors = errors + 1;
        end
    end

    // Загрузка следующего вектора по negedge
    always @(negedge clk) begin
        if (vectornum < 32'd256) begin
            {binary_in, excepted} = testvectors[vectornum];
            vectornum = vectornum + 1;
        end
        if (vectornum == 32'd256) begin
            @(posedge clk);
            $display("%d tests finished with %d errors", vectornum, errors);
            $finish;
        end
    end
endmodule