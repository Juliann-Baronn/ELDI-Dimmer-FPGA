
`timescale 1ns/1ps

module tb_zero_cross_chain;

    reg clk;
    reg rst;
    reg zc_in;

    wire zc_sync;
    wire zc_event;

    integer errors = 0;
    integer checks = 0;

    // ==========================================
    // INSTANCIA M2: SINCRONIZADOR
    // ==========================================

    zero_cross_sync M2 (
        .clk(clk),
        .rst(rst),
        .zc_in(zc_in),
        .zc_sync(zc_sync)
    );

    // ==========================================
    // INSTANCIA M4: DETECTOR DE CRUCE POR CERO
    // ==========================================

    zero_cross_detect M4 (
        .clk(clk),
        .rst(rst),
        .zc_sync(zc_sync),
        .zc_event(zc_event)
    );

    // ==========================================
    // RELOJ DE 100 MHz
    // Periodo = 10 ns
    // ==========================================

    always #5 clk = ~clk;

    // ==========================================
    // ESPERAR UN CICLO DE RELOJ
    // ==========================================

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // ==========================================
    // COMPROBACION DE LAS SALIDAS
    // ==========================================

    task check_signals;
        input expected_sync;
        input expected_event;
        input [8*100-1:0] label;

        begin
            checks = checks + 1;

            if ((zc_sync !== expected_sync) ||
                (zc_event !== expected_event)) begin

                $display(
                    "ERROR CADENA M2-M4: %0s | zc_sync esperado=%b obtenido=%b | zc_event esperado=%b obtenido=%b | Tiempo=%0t",
                    label,
                    expected_sync,
                    zc_sync,
                    expected_event,
                    zc_event,
                    $time
                );

                errors = errors + 1;

            end else begin

                $display(
                    "OK CADENA M2-M4: %0s | zc_sync=%b | zc_event=%b | Tiempo=%0t",
                    label,
                    zc_sync,
                    zc_event,
                    $time
                );

            end
        end
    endtask

    // ==========================================
    // ESTIMULO: FLANCO ASCENDENTE
    // ==========================================

    task rising_cross;
        begin

            @(negedge clk);
            zc_in = 1'b1;

            tick();
            check_signals(1'b0, 1'b0,
                          "Ascenso: primera etapa M2");

            tick();
            check_signals(1'b1, 1'b0,
                          "Ascenso: segunda etapa M2");

            tick();
            check_signals(1'b1, 1'b1,
                          "Ascenso: M4 genera zc_event");

            tick();
            check_signals(1'b1, 1'b0,
                          "Ascenso: zc_event vuelve a cero");

        end
    endtask

    // ==========================================
    // ESTIMULO: FLANCO DESCENDENTE
    // ==========================================

    task falling_cross;
        begin

            @(negedge clk);
            zc_in = 1'b0;

            tick();
            check_signals(1'b1, 1'b0,
                          "Descenso: primera etapa M2");

            tick();
            check_signals(1'b0, 1'b0,
                          "Descenso: segunda etapa M2");

            tick();
            check_signals(1'b0, 1'b0,
                          "Descenso: M4 queda armado");

        end
    endtask

    // ==========================================
    // INICIO DE SIMULACION
    // ==========================================

    initial begin

        clk = 1'b0;
        rst = 1'b1;
        zc_in = 1'b0;

        // --------------------------------------
        // 1. RESET INICIAL
        // --------------------------------------

        repeat (2) tick();

        check_signals(1'b0, 1'b0,
                      "Reset inicial de M2 y M4");

        // Liberar reset
        @(negedge clk);
        rst = 1'b0;

        // Esperar estabilizacion de la cadena
        repeat (3) tick();

        check_signals(1'b0, 1'b0,
                      "Cadena estabilizada despues del reset");

        // --------------------------------------
        // 2. PRIMER CRUCE POR CERO
        // --------------------------------------

        rising_cross();

        // --------------------------------------
        // 3. NIVEL ALTO SOSTENIDO
        // --------------------------------------

        repeat (3) begin

            tick();

            check_signals(1'b1, 1'b0,
                          "Nivel alto sostenido sin eventos repetidos");

        end

        // --------------------------------------
        // 4. FLANCO DESCENDENTE
        // --------------------------------------

        falling_cross();

        // --------------------------------------
        // 5. SEGUNDO CRUCE POR CERO
        // --------------------------------------

        rising_cross();

        // --------------------------------------
        // 6. TERCER CRUCE POR CERO
        // --------------------------------------

        falling_cross();
        rising_cross();

        // --------------------------------------
        // 7. RESET DURANTE FUNCIONAMIENTO
        // --------------------------------------

        falling_cross();

        @(negedge clk);
        rst = 1'b1;

        tick();

        check_signals(1'b0, 1'b0,
                      "Reset durante funcionamiento");

        // --------------------------------------
        // 8. LIBERAR RESET Y VOLVER A DETECTAR
        // --------------------------------------

        @(negedge clk);
        rst = 1'b0;

        repeat (3) tick();

        check_signals(1'b0, 1'b0,
                      "Cadena estabilizada despues del segundo reset");

        rising_cross();

        // --------------------------------------
        // RESULTADO FINAL
        // --------------------------------------

        $display("------------------------------------------");

        if (errors == 0) begin

            $display("TESTBENCH CADENA M2-M4: TODAS LAS PRUEBAS OK");
            $display("Comprobaciones: %0d", checks);
            $display("Errores: %0d", errors);

        end else begin

            $display("TESTBENCH CADENA M2-M4: ERROR");
            $display("Comprobaciones: %0d", checks);
            $display("Errores: %0d", errors);

        end

        $display("------------------------------------------");

        $finish;

    end

endmodule
