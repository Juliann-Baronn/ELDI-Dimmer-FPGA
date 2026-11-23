
`timescale 1ns / 1ps

module tb_dimmer_fsm;

    reg clk;
    reg rst;

    reg zc_event;
    reg timer_done;
    reg pulse_done;

    wire timer_start;
    wire timer_clear;
    wire triac_pulse_start;

    integer checks;
    integer errors;

    // =====================================================
    // INSTANCIA M6
    // =====================================================

    dimmer_fsm uut (
        .clk(clk),
        .rst(rst),
        .zc_event(zc_event),
        .timer_done(timer_done),
        .pulse_done(pulse_done),
        .timer_start(timer_start),
        .timer_clear(timer_clear),
        .triac_pulse_start(triac_pulse_start)
    );

    // =====================================================
    // RELOJ 100 MHz
    // =====================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =====================================================
    // COMPROBACION DE SALIDAS
    // =====================================================

    task check_outputs;
        input expected_start;
        input expected_clear;
        input expected_pulse;

        begin
            checks = checks + 1;

            if (
                timer_start !== expected_start ||
                timer_clear !== expected_clear ||
                triac_pulse_start !== expected_pulse
            ) begin

                errors = errors + 1;

                $display(
                    "ERROR [%0t]: start=%b clear=%b pulse=%b | esperado=%b %b %b",
                    $time,
                    timer_start,
                    timer_clear,
                    triac_pulse_start,
                    expected_start,
                    expected_clear,
                    expected_pulse
                );

            end
            else begin

                $display(
                    "OK [%0t]: start=%b clear=%b pulse=%b",
                    $time,
                    timer_start,
                    timer_clear,
                    triac_pulse_start
                );

            end
        end
    endtask

    // =====================================================
    // ESPERAR UN FLANCO POSITIVO
    // =====================================================

    task next_cycle;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // =====================================================
    // PRUEBAS
    // =====================================================

    initial begin

        checks = 0;
        errors = 0;

        rst = 1'b1;
        zc_event = 1'b0;
        timer_done = 1'b0;
        pulse_done = 1'b0;

        $display("\n======================================");
        $display(" TESTBENCH M6 - DIMMER_FSM ACTUALIZADO");
        $display("======================================");

        // ---------------------------------------------
        // PRUEBA 1: RESET
        // ---------------------------------------------

        $display("\nPRUEBA 1: RESET");

        next_cycle();
        next_cycle();

        check_outputs(0, 0, 0);

        @(negedge clk);
        rst = 1'b0;

        // ---------------------------------------------
        // PRUEBA 2: ESPERA DE CRUCE
        // ---------------------------------------------

        $display("\nPRUEBA 2: ESPERA DE ZC_EVENT");

        next_cycle();
        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 3: INICIO DE M5
        // ---------------------------------------------

        $display("\nPRUEBA 3: INICIO DE M5");

        @(negedge clk);
        zc_event = 1'b1;

        next_cycle();

        check_outputs(1, 0, 0);

        @(negedge clk);
        zc_event = 1'b0;

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 4: ESPERA DE TIMER_DONE
        // ---------------------------------------------

        $display("\nPRUEBA 4: ESPERA DE TIMER_DONE");

        next_cycle();
        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 5: FINALIZACION DE M5
        // ---------------------------------------------

        $display("\nPRUEBA 5: FINALIZACION DE M5");

        @(negedge clk);
        timer_done = 1'b1;

        next_cycle();

        check_outputs(0, 0, 1);

        @(negedge clk);
        timer_done = 1'b0;

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 6: ESPERA DE PULSE_DONE
        // ---------------------------------------------

        $display("\nPRUEBA 6: ESPERA DE PULSE_DONE");

        next_cycle();

        check_outputs(0, 0, 0);

        // M6 debe permanecer esperando mientras pulse_done=0.

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 7: FINALIZACION DEL PULSO
        // ---------------------------------------------

        $display("\nPRUEBA 7: FINALIZACION DEL PULSO M7");

        @(negedge clk);
        pulse_done = 1'b1;

        next_cycle();

        check_outputs(0, 0, 0);

        @(negedge clk);
        pulse_done = 1'b0;

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 8: NUEVO CRUCE DURANTE TEMPORIZACION
        // ---------------------------------------------

        $display("\nPRUEBA 8: REINICIO POR NUEVO CRUCE");

        @(negedge clk);
        zc_event = 1'b1;

        next_cycle();

        check_outputs(1, 0, 0);

        @(negedge clk);
        zc_event = 1'b0;

        next_cycle();

        check_outputs(0, 0, 0);

        // Nuevo cruce durante WAIT_TIMER.

        @(negedge clk);
        zc_event = 1'b1;

        next_cycle();

        check_outputs(0, 1, 0);

        @(negedge clk);
        zc_event = 1'b0;

        next_cycle();

        check_outputs(1, 0, 0);

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 9: PRIORIDAD DE ZC_EVENT
        // ---------------------------------------------

        $display("\nPRUEBA 9: PRIORIDAD DE ZC_EVENT");

        @(negedge clk);
        zc_event = 1'b1;
        timer_done = 1'b1;

        next_cycle();

        check_outputs(0, 1, 0);

        @(negedge clk);
        zc_event = 1'b0;
        timer_done = 1'b0;

        next_cycle();

        check_outputs(1, 0, 0);

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 10: NUEVO CRUCE DURANTE PULSO ACTIVO
        // ---------------------------------------------

        $display("\nPRUEBA 10: CRUCE DURANTE PULSO ACTIVO");

        // Finalizar la temporizacion para solicitar M7.

        @(negedge clk);
        timer_done = 1'b1;

        next_cycle();

        check_outputs(0, 0, 1);

        @(negedge clk);
        timer_done = 1'b0;

        next_cycle();

        check_outputs(0, 0, 0);

        // Aparece un nuevo cruce mientras M7 esta activo.

        @(negedge clk);
        zc_event = 1'b1;

        next_cycle();

        check_outputs(0, 0, 0);

        @(negedge clk);
        zc_event = 1'b0;

        // M6 debe seguir esperando a M7.

        next_cycle();

        check_outputs(0, 0, 0);

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 11: CONSUMIR EVENTO PENDIENTE
        // ---------------------------------------------

        $display("\nPRUEBA 11: EVENTO PENDIENTE");

        @(negedge clk);
        pulse_done = 1'b1;

        next_cycle();

        check_outputs(1, 0, 0);

        @(negedge clk);
        pulse_done = 1'b0;

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 12: CRUCE SIMULTANEO CON PULSE_DONE
        // ---------------------------------------------

        $display("\nPRUEBA 12: CRUCE SIMULTANEO CON PULSE_DONE");

        // Finalizar la temporizacion.

        @(negedge clk);
        timer_done = 1'b1;

        next_cycle();

        check_outputs(0, 0, 1);

        @(negedge clk);
        timer_done = 1'b0;

        next_cycle();

        // Cruce y finalizacion simultaneos.

        @(negedge clk);
        zc_event = 1'b1;
        pulse_done = 1'b1;

        next_cycle();

        check_outputs(1, 0, 0);

        @(negedge clk);
        zc_event = 1'b0;
        pulse_done = 1'b0;

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // PRUEBA 13: RESET DURANTE ESPERA DE PULSO
        // ---------------------------------------------

        $display("\nPRUEBA 13: RESET");

        // Llevar M6 a WAIT_PULSE.

        @(negedge clk);
        timer_done = 1'b1;

        next_cycle();

        check_outputs(0, 0, 1);

        @(negedge clk);
        timer_done = 1'b0;

        next_cycle();

        // Reset mientras espera pulse_done.

        @(negedge clk);
        rst = 1'b1;

        next_cycle();

        check_outputs(0, 0, 0);

        @(negedge clk);
        rst = 1'b0;

        next_cycle();

        check_outputs(0, 0, 0);

        // ---------------------------------------------
        // RESUMEN
        // ---------------------------------------------

        $display("\n======================================");
        $display(" RESULTADOS DE LA SIMULACION");
        $display("======================================");

        $display("Checks ejecutados : %0d", checks);
        $display("Errores detectados: %0d", errors);

        if (errors == 0)
            $display("RESULTADO: TODAS LAS PRUEBAS APROBADAS");
        else
            $display("RESULTADO: SE DETECTARON ERRORES");

        $display("======================================");

        $finish;

    end

endmodule
