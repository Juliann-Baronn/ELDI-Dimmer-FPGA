`timescale 1ns/1ps

module tb_zero_cross_sync;

    reg clk;
    reg rst;
    reg zc_in;

    wire zc_sync;

    integer errors = 0;
    integer checks = 0;

    // Instancia del modulo M2
    zero_cross_sync uut (
        .clk(clk),
        .rst(rst),
        .zc_in(zc_in),
        .zc_sync(zc_sync)
    );

    // Reloj de 100 MHz: periodo de 10 ns
    always #5 clk = ~clk;

    // Esperar un flanco positivo y dejar estabilizar las señales
    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // Comprobar el valor de salida
    task check;
        input expected;
        input [8*100-1:0] label;

        begin
            checks = checks + 1;

            if (zc_sync !== expected) begin
                $display("ERROR M2: %0s | Esperado=%b | Obtenido=%b | Tiempo=%0t",
                         label, expected, zc_sync, $time);

                errors = errors + 1;
            end else begin
                $display("OK M2: %0s | zc_sync=%b | Tiempo=%0t",
                         label, zc_sync, $time);
            end
        end
    endtask

    initial begin

        // Valores iniciales
        clk = 0;
        rst = 1;
        zc_in = 0;

        // --------------------------------
        // 1. PRUEBA DE RESET
        // --------------------------------

        repeat (2) tick();

        check(1'b0, "Reset limpia las dos etapas");

        @(negedge clk);
        rst = 0;

        // --------------------------------
        // 2. FLANCO ASCENDENTE
        // --------------------------------

        #2 zc_in = 1;

        tick();
        check(1'b0, "Flanco ascendente capturado por FF1");

        tick();
        check(1'b1, "Flanco ascendente llega a FF2");

        // --------------------------------
        // 3. NIVEL ALTO SOSTENIDO
        // --------------------------------

        repeat (3) begin
            tick();
            check(1'b1, "Nivel alto sostenido");
        end

        // --------------------------------
        // 4. FLANCO DESCENDENTE
        // --------------------------------

        @(negedge clk);
        zc_in = 0;

        tick();
        check(1'b1, "Flanco descendente capturado por FF1");

        tick();
        check(1'b0, "Flanco descendente llega a FF2");

        // --------------------------------
        // 5. PULSO CORTO
        // --------------------------------

        @(negedge clk);
        zc_in = 1;

        tick();
        check(1'b0, "Pulso corto llega a FF1");

        @(negedge clk);
        zc_in = 0;

        tick();
        check(1'b1, "Pulso corto llega a FF2");

        tick();
        check(1'b0, "Pulso corto desaparece de la salida");

        // --------------------------------
        // 6. RESET DURANTE FUNCIONAMIENTO
        // --------------------------------

        @(negedge clk);
        zc_in = 1;

        tick();

        @(negedge clk);
        rst = 1;

        tick();
        check(1'b0, "Reset durante funcionamiento");

        @(negedge clk);
        rst = 0;
        zc_in = 0;

        tick();
        check(1'b0, "Salida permanece baja despues del reset");

        // --------------------------------
        // RESULTADO FINAL
        // --------------------------------

        if (errors == 0) begin
            $display("----------------------------------");
            $display("TESTBENCH M2: TODAS LAS PRUEBAS OK");
            $display("Comprobaciones: %0d", checks);
            $display("----------------------------------");
        end else begin
            $display("----------------------------------");
            $display("TESTBENCH M2: ERROR");
            $display("Errores encontrados: %0d", errors);
            $display("----------------------------------");
        end

        $finish;

    end

endmodule