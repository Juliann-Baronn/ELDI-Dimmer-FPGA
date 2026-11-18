`timescale 1ns/1ps

module tb_zero_cross_detect;

    reg clk;
    reg rst;
    reg zc_sync;

    wire zc_event;

    integer errors = 0;
    integer checks = 0;

    // Instancia del modulo M4
    zero_cross_detect uut (
        .clk(clk),
        .rst(rst),
        .zc_sync(zc_sync),
        .zc_event(zc_event)
    );

    // Reloj de 100 MHz
    always #5 clk = ~clk;

    // Esperar un flanco positivo
    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // Comprobar salida
    task check_event;
        input expected;
        input [8*100-1:0] label;

        begin
            checks = checks + 1;

            if (zc_event !== expected) begin
                $display("ERROR M4: %0s | Esperado=%b | Obtenido=%b | Tiempo=%0t",
                         label, expected, zc_event, $time);

                errors = errors + 1;
            end else begin
                $display("OK M4: %0s | zc_event=%b | Tiempo=%0t",
                         label, zc_event, $time);
            end
        end
    endtask

    initial begin

        // Valores iniciales
        clk = 0;
        rst = 1;
        zc_sync = 1;

        // --------------------------------
        // 1. RESET
        // --------------------------------

        tick();

        check_event(1'b0, "Reset mantiene zc_event en cero");

        // --------------------------------
        // 2. LIBERAR RESET CON ENTRADA ALTA
        // --------------------------------

        @(negedge clk);
        rst = 0;

        tick();

        check_event(1'b0, "No genera evento al liberar reset con entrada alta");

        tick();

        check_event(1'b0, "Nivel alto sostenido no genera evento artificial");

        // --------------------------------
        // 3. OBSERVAR NIVEL BAJO
        // --------------------------------

        @(negedge clk);
        zc_sync = 0;

        tick();

        check_event(1'b0, "Nivel bajo arma el detector");

        // --------------------------------
        // 4. FLANCO ASCENDENTE
        // --------------------------------

        @(negedge clk);
        zc_sync = 1;

        tick();

        check_event(1'b1, "Flanco ascendente genera zc_event");

        // --------------------------------
        // 5. DURACION DEL EVENTO
        // --------------------------------

        tick();

        check_event(1'b0, "zc_event dura solamente un ciclo");

        // --------------------------------
        // 6. NIVEL ALTO SOSTENIDO
        // --------------------------------

        repeat (3) begin
            tick();

            check_event(1'b0, "Nivel alto sostenido no genera eventos repetidos");
        end

        // --------------------------------
        // 7. FLANCO DESCENDENTE
        // --------------------------------

        @(negedge clk);
        zc_sync = 0;

        tick();

        check_event(1'b0, "Flanco descendente no genera evento");

        // --------------------------------
        // 8. SEGUNDO FLANCO ASCENDENTE
        // --------------------------------

        @(negedge clk);
        zc_sync = 1;

        tick();

        check_event(1'b1, "Segundo flanco ascendente genera evento");

        tick();

        check_event(1'b0, "Segundo evento dura un ciclo");

        // --------------------------------
        // 9. RESET DURANTE FUNCIONAMIENTO
        // --------------------------------

        @(negedge clk);
        rst = 1;

        tick();

        check_event(1'b0, "Reset durante funcionamiento");

        // Liberar reset manteniendo entrada alta
        @(negedge clk);
        rst = 0;

        tick();

        check_event(1'b0, "Entrada alta despues del reset no genera evento");

        // --------------------------------
        // 10. VOLVER A ARMAR EL DETECTOR
        // --------------------------------

        @(negedge clk);
        zc_sync = 0;

        tick();

        check_event(1'b0, "Detector vuelve a armarse con nivel bajo");

        // Nuevo flanco ascendente
        @(negedge clk);
        zc_sync = 1;

        tick();

        check_event(1'b1, "Nuevo flanco ascendente genera evento");

        // --------------------------------
        // RESULTADO FINAL
        // --------------------------------

        if (errors == 0) begin
            $display("----------------------------------");
            $display("TESTBENCH M4: TODAS LAS PRUEBAS OK");
            $display("Comprobaciones: %0d", checks);
            $display("----------------------------------");
        end else begin
            $display("----------------------------------");
            $display("TESTBENCH M4: ERROR");
            $display("Errores encontrados: %0d", errors);
            $display("----------------------------------");
        end

        $finish;

    end

endmodule