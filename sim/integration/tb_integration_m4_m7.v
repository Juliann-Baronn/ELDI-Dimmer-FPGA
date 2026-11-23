
`timescale 1ns / 1ps

module tb_integration_m4_m7;

    // =====================================================
    // PARAMETROS DE PRUEBA
    // =====================================================

    localparam [19:0] TEST_DELAY = 20'd12;
    localparam [31:0] TEST_PULSE_WIDTH = 32'd8;

    // =====================================================
    // ENTRADAS GENERALES
    // =====================================================

    reg clk;
    reg rst;

    // Estimulo hacia M4 (salida simulada de M2)
    reg zc_sync;

    // Valor de retardo (salida simulada de M3)
    reg [19:0] delay_target;

    // =====================================================
    // INTERCONEXIONES
    // =====================================================

    wire zc_event;

    wire timer_start;
    wire timer_clear;
    wire timer_done;

    wire triac_pulse_start;
    wire pulse_done;
    wire gate_pulse;

    integer checks;
    integer errors;
    integer pulse_cycles;

    // =====================================================
    // RELOJ DE 100 MHz
    // =====================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // =====================================================
    // M4: ZERO CROSS DETECT
    // =====================================================

    zero_cross_detect u_m4 (
        .clk(clk),
        .rst(rst),
        .zc_sync(zc_sync),
        .zc_event(zc_event)
    );

    // =====================================================
    // M5: PHASE TIMER
    // =====================================================

    phase_timer u_m5 (
        .clk(clk),
        .rst(rst),
        .timer_start(timer_start),
        .timer_clear(timer_clear),
        .delay_target(delay_target),
        .timer_done(timer_done)
    );

    // =====================================================
    // M6: DIMMER FSM
    // Version actualizada con entrada pulse_done
    // =====================================================

    dimmer_fsm u_m6 (
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
    // M7: TRIAC PULSE
    // =====================================================

    triac_pulse #(
        .PULSE_WIDTH_CYCLES(TEST_PULSE_WIDTH)
    ) u_m7 (
        .clk(clk),
        .rst(rst),
        .pulse_start(triac_pulse_start),
        .gate_pulse(gate_pulse),
        .pulse_done(pulse_done)
    );

    // =====================================================
    // TAREA DE COMPROBACION
    // =====================================================

    task check;
        input condition;
        input [8*100:1] description;

        begin
            checks = checks + 1;

            if (condition !== 1'b1) begin

                errors = errors + 1;

                $display(
                    "[ERROR] %0s | Tiempo: %0t",
                    description,
                    $time
                );

            end
            else begin

                $display(
                    "[OK] %0s | Tiempo: %0t",
                    description,
                    $time
                );

            end
        end
    endtask

    // =====================================================
    // TAREA: AVANZAR UN CICLO
    // =====================================================

    task next_cycle;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // =====================================================
    // TAREA: GENERAR CRUCE POR CERO
    //
    // M4 necesita observar primero nivel bajo
    // y posteriormente un flanco ascendente.
    // =====================================================

    task generate_zc;
        begin

            @(negedge clk);
            zc_sync = 1'b0;

            next_cycle();
            next_cycle();

            @(negedge clk);
            zc_sync = 1'b1;

            next_cycle();
            next_cycle();

            @(negedge clk);
            zc_sync = 1'b0;

        end
    endtask

    // =====================================================
    // TAREA: ESPERAR Y MEDIR PULSO DE M7
    // =====================================================

    task measure_gate_pulse;
        input integer expected_cycles;

        begin

            pulse_cycles = 0;

            // Esperar el inicio del pulso.
            wait (gate_pulse === 1'b1);

            // Medir desde el pulso activo.
            // Se cuentan los ciclos completos en nivel alto.

            while (gate_pulse === 1'b1) begin

                @(negedge clk);

                if (gate_pulse === 1'b1)
                    pulse_cycles = pulse_cycles + 1;

            end

            $display(
                "Duracion observada de gate_pulse: %0d ciclos",
                pulse_cycles
            );

            check(
                pulse_cycles == expected_cycles,
                "Duracion del pulso M7 correcta"
            );

        end
    endtask

    // =====================================================
    // TAREA: ESPERAR PULSO CON LIMITE DE TIEMPO
    // =====================================================

    task wait_for_gate;
        integer timeout;

        begin

            timeout = 0;

            while ((gate_pulse !== 1'b1) &&
                   (timeout < 100)) begin

                next_cycle();
                timeout = timeout + 1;

            end

            check(
                gate_pulse === 1'b1,
                "Se recibio gate_pulse dentro del tiempo esperado"
            );

        end
    endtask

    // =====================================================
    // SECUENCIA PRINCIPAL
    // =====================================================

    initial begin

        checks = 0;
        errors = 0;
        pulse_cycles = 0;

        rst = 1'b1;
        zc_sync = 1'b0;
        delay_target = TEST_DELAY;

        $display("\n==========================================");
        $display(" INTEGRACION REAL M4 - M5 - M6 - M7");
        $display("==========================================");

        // ---------------------------------------------
        // PRUEBA 1: RESET GENERAL
        // ---------------------------------------------

        $display("\nPRUEBA 1: RESET GENERAL");

        next_cycle();
        next_cycle();

        check(
            gate_pulse == 1'b0,
            "Reset: gate_pulse apagado"
        );

        check(
            timer_done == 1'b0,
            "Reset: timer_done apagado"
        );

        check(
            pulse_done == 1'b0,
            "Reset: pulse_done apagado"
        );

        @(negedge clk);
        rst = 1'b0;

        // ---------------------------------------------
        // PRUEBA 2: SECUENCIA NORMAL
        // ---------------------------------------------

        $display("\nPRUEBA 2: SECUENCIA NORMAL");

        generate_zc();

        wait_for_gate();

        measure_gate_pulse(TEST_PULSE_WIDTH);

        next_cycle();

        check(
            pulse_done == 1'b0,
            "M7 finaliza y pulse_done vuelve a cero"
        );

        // ---------------------------------------------
        // PRUEBA 3: NUEVO CRUCE DURANTE TEMPORIZACION
        // ---------------------------------------------

        $display("\nPRUEBA 3: NUEVO CRUCE DURANTE TEMPORIZACION");

        generate_zc();

        // Dar tiempo a que M6 inicie M5.
        repeat (4) next_cycle();

        // Generar otro cruce antes de que termine
        // la cuenta de M5.
        generate_zc();

        // Debe producirse un pulso correspondiente
        // a la nueva temporizacion.
        wait_for_gate();

        measure_gate_pulse(TEST_PULSE_WIDTH);

        next_cycle();

        check(
            timer_done == 1'b0,
            "Temporizador no mantiene timer_done activo"
        );

        // ---------------------------------------------
        // PRUEBA 4: NUEVO CRUCE DURANTE PULSO ACTIVO
        // ---------------------------------------------

        $display("\nPRUEBA 4: NUEVO CRUCE DURANTE PULSO ACTIVO");

        // Generar el cruce que inicia la siguiente operacion.
        generate_zc();

        // Esperar el inicio del pulso.
        wait_for_gate();

        check(
            gate_pulse == 1'b1,
            "M7 esta generando el pulso"
        );

        // Medir el pulso y generar otro cruce
        // simultaneamente.
        //
        // Esto evita que generate_zc consuma varios ciclos
        // antes de comenzar a medir gate_pulse.

        fork

            begin

                measure_gate_pulse(TEST_PULSE_WIDTH);

            end

            begin

                generate_zc();

            end

        join

        // M7 debe haber terminado el pulso completo.

        check(
            gate_pulse == 1'b0,
            "M7 termina el pulso sin interrupciones"
        );

        // M6 debe conservar el cruce pendiente e iniciar
        // una nueva temporizacion despues de pulse_done.

        wait_for_gate();

        check(
            gate_pulse == 1'b1,
            "M6 inicia una nueva operacion por evento pendiente"
        );

        measure_gate_pulse(TEST_PULSE_WIDTH);

        // ---------------------------------------------
        // RESUMEN
        // ---------------------------------------------

        $display("\n==========================================");
        $display(" RESULTADOS DE INTEGRACION");
        $display("==========================================");

        $display("Checks ejecutados : %0d", checks);
        $display("Errores detectados: %0d", errors);

        if (errors == 0)
            $display("RESULTADO: TODAS LAS PRUEBAS APROBADAS");
        else
            $display("RESULTADO: SE DETECTARON ERRORES");

        $display("==========================================");

        $finish;

    end

    // =====================================================
    // PROTECCION CONTRA SIMULACION INFINITA
    // =====================================================

    initial begin

        #20000;

        $display("[ERROR] Timeout general de simulacion");

        $finish;

    end

endmodule
