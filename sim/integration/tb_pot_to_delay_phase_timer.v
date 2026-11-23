
`timescale 1ns / 1ps

module tb_pot_to_delay_phase_timer;

    // =====================================================
    // 1. SENALES
    // =====================================================

    reg clk;
    reg rst;

    reg [11:0] pot_sample;
    reg sample_valid;

    reg timer_start;
    reg timer_clear;

    wire [19:0] delay_target;
    wire timer_done;

    integer errors;
    integer checks;

    // =====================================================
    // 2. INSTANCIA M3
    // =====================================================

    pot_to_delay M3 (
        .clk(clk),
        .rst(rst),
        .pot_sample(pot_sample),
        .sample_valid(sample_valid),
        .delay_target(delay_target)
    );

    // =====================================================
    // 3. INSTANCIA M5
    // =====================================================

    phase_timer M5 (
        .clk(clk),
        .rst(rst),
        .timer_start(timer_start),
        .timer_clear(timer_clear),
        .delay_target(delay_target),
        .timer_done(timer_done)
    );

    // =====================================================
    // 4. RELOJ DE 100 MHz
    // =====================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =====================================================
    // 5. COMPROBACIONES
    // =====================================================

    task check_delay;
        input [19:0] expected;
        begin
            checks = checks + 1;

            if (delay_target !== expected) begin
                errors = errors + 1;
                $display(
                    "ERROR [%0t]: delay_target esperado=%0d, obtenido=%0d",
                    $time, expected, delay_target
                );
            end
            else begin
                $display(
                    "OK [%0t]: delay_target=%0d",
                    $time, delay_target
                );
            end
        end
    endtask

    task check_done;
        input expected;
        begin
            checks = checks + 1;

            if (timer_done !== expected) begin
                errors = errors + 1;
                $display(
                    "ERROR [%0t]: timer_done esperado=%b, obtenido=%b",
                    $time, expected, timer_done
                );
            end
            else begin
                $display(
                    "OK [%0t]: timer_done=%b",
                    $time, timer_done
                );
            end
        end
    endtask

    task wait_cycles;
        input integer cycles;
        integer i;
        begin
            for (i = 0; i < cycles; i = i + 1) begin
                @(posedge clk);
                #1;
            end
        end
    endtask

    // =====================================================
    // 6. ACTUALIZAR MUESTRA DEL POTENCIOMETRO
    // =====================================================

    task update_pot;
        input [11:0] sample;
        begin
            @(negedge clk);
            pot_sample = sample;
            sample_valid = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            sample_valid = 1'b0;
        end
    endtask

    // =====================================================
    // 7. INICIAR TEMPORIZADOR
    // =====================================================

    task start_timer;
        begin
            @(negedge clk);
            timer_start = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);
            timer_start = 1'b0;
        end
    endtask

    // =====================================================
    // 8. SECUENCIA PRINCIPAL
    // =====================================================

    initial begin

        errors = 0;
        checks = 0;

        rst = 1'b1;

        pot_sample = 12'd0;
        sample_valid = 1'b0;

        timer_start = 1'b0;
        timer_clear = 1'b0;

        $display("\n==========================================");
        $display(" TESTBENCH INTEGRACION M3 - M5");
        $display("==========================================");

        // -------------------------------------------------
        // PRUEBA 1: RESET GENERAL
        // -------------------------------------------------

        $display("\nPRUEBA 1: RESET");

        wait_cycles(2);

        check_done(1'b0);
        check_delay(20'd800000);

        @(negedge clk);
        rst = 1'b0;

        // -------------------------------------------------
        // PRUEBA 2: CONVERSION DEL POTENCIOMETRO
        // -------------------------------------------------

        $display("\nPRUEBA 2: CONVERSION M3");

        update_pot(12'd4095);

        check_delay(20'd10000);

        // -------------------------------------------------
        // PRUEBA 3: INICIO DEL TEMPORIZADOR
        // -------------------------------------------------

        $display("\nPRUEBA 3: INICIO M5");

        start_timer();

        check_done(1'b0);

        // -------------------------------------------------
        // PRUEBA 4: CAMBIO DEL POTENCIOMETRO
        // DURANTE LA CUENTA ACTIVA
        // -------------------------------------------------

        $display("\nPRUEBA 4: CAMBIO DE MUESTRA DURANTE CUENTA");

        update_pot(12'd0);

        // M3 debe actualizar su salida.
        check_delay(20'd800000);

        // M5 debe seguir contando con los 10000
        // ciclos capturados al iniciar.
        check_done(1'b0);

       
        // -------------------------------------------------
        // PRUEBA 5: VERIFICAR QUE NO FINALIZA ANTES
        // -------------------------------------------------

        $display("\nPRUEBA 5: CUENTA ACTIVA");

        // Comprobar un ciclo antes de la finalizacion.
        wait_cycles(9997);

        check_done(1'b0);


        // -------------------------------------------------
        // PRUEBA 6: FINALIZACION
        // -------------------------------------------------

        $display("\nPRUEBA 6: FINALIZACION");

        // El siguiente ciclo debe generar timer_done.
        wait_cycles(1);

        check_done(1'b1);

        // Verificar que timer_done vuelve a cero.
        wait_cycles(1);

        check_done(1'b0);

        // -------------------------------------------------
        // 9. RESUMEN
        // -------------------------------------------------

        $display("\n==========================================");
        $display(" RESULTADOS DE INTEGRACION M3 - M5");
        $display("==========================================");

        $display("Checks ejecutados : %0d", checks);
        $display("Errores detectados: %0d", errors);

        if (errors == 0)
            $display("RESULTADO: INTEGRACION APROBADA");
        else
            $display("RESULTADO: SE DETECTARON ERRORES");

        $display("==========================================");

        $finish;

    end

endmodule