
`timescale 1ns / 1ps

module tb_phase_timer;

    // =====================================================
    // 1. SENALES DEL TESTBENCH
    // =====================================================

    reg clk;
    reg rst;

    reg timer_start;
    reg timer_clear;

    reg [19:0] delay_target;

    wire timer_done;

    integer errors;
    integer checks;


    // =====================================================
    // 2. INSTANCIA DEL MODULO BAJO PRUEBA
    // =====================================================

    phase_timer uut (
        .clk(clk),
        .rst(rst),
        .timer_start(timer_start),
        .timer_clear(timer_clear),
        .delay_target(delay_target),
        .timer_done(timer_done)
    );


    // =====================================================
    // 3. GENERADOR DE RELOJ
    // Periodo: 10 ns (100 MHz)
    // =====================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // =====================================================
    // 4. TAREA DE COMPROBACION
    // =====================================================

    task check_done;
        input expected;
        begin
            checks = checks + 1;

            if (timer_done !== expected) begin

                errors = errors + 1;

                $display(
                    "ERROR [%0t]: esperado=%b, obtenido=%b",
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


    // =====================================================
    // 5. ESPERAR CICLOS COMPLETOS
    // =====================================================

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
    // 6. GENERAR SOLICITUD DE INICIO
    // El temporizador acepta el flanco ascendente
    // en el siguiente flanco positivo del reloj.
    // =====================================================

    task start_timer;
        input [19:0] target;

        begin
            @(negedge clk);

            delay_target = target;
            timer_start = 1'b1;

            @(posedge clk);
            #1;

            @(negedge clk);

            timer_start = 1'b0;
        end
    endtask


    // =====================================================
    // 7. SECUENCIA PRINCIPAL DE PRUEBAS
    // =====================================================

    initial begin

        errors = 0;
        checks = 0;

        rst = 1'b1;
        timer_start = 1'b0;
        timer_clear = 1'b0;
        delay_target = 20'd0;


        $display("\n======================================");
        $display(" TESTBENCH M5 - PHASE TIMER");
        $display("======================================");


        // -------------------------------------------------
        // PRUEBA 1: RESET
        // -------------------------------------------------

        $display("\nPRUEBA 1: RESET");

        wait_cycles(2);

        check_done(1'b0);


        // -------------------------------------------------
        // PRUEBA 2: CUENTA REGRESIVA DE CINCO CICLOS
        // -------------------------------------------------

        $display("\nPRUEBA 2: CUENTA REGRESIVA");

        @(negedge clk);
        rst = 1'b0;

        start_timer(20'd5);

        wait_cycles(3);
        check_done(1'b0);

        wait_cycles(1);
        check_done(1'b0);

        wait_cycles(1);
        check_done(1'b1);

        wait_cycles(1);
        check_done(1'b0);


        // -------------------------------------------------
        // PRUEBA 3: RETARDO IGUAL A CERO
        // -------------------------------------------------

        $display("\nPRUEBA 3: RETARDO CERO");

        start_timer(20'd0);

        // timer_done ya debe estar activo
        // al terminar la tarea start_timer.

        check_done(1'b1);

        wait_cycles(1);
        check_done(1'b0);


        // -------------------------------------------------
        // PRUEBA 4: CAPTURA DE DELAY_TARGET
        // -------------------------------------------------

        $display("\nPRUEBA 4: CAPTURA DEL RETARDO");

        start_timer(20'd5);

        // Cambiar delay_target durante la cuenta.
        // El temporizador debe conservar el valor inicial.

        @(negedge clk);
        delay_target = 20'd2;

        wait_cycles(3);
        check_done(1'b0);

        wait_cycles(1);
        check_done(1'b1);

        wait_cycles(1);
        check_done(1'b0);


        // -------------------------------------------------
        // PRUEBA 5: CANCELACION MEDIANTE TIMER_CLEAR
        // -------------------------------------------------

        $display("\nPRUEBA 5: CANCELACION");

        start_timer(20'd10);

        wait_cycles(3);

        @(negedge clk);
        timer_clear = 1'b1;

        @(posedge clk);
        #1;

        check_done(1'b0);

        @(negedge clk);
        timer_clear = 1'b0;

        // Comprobar que el temporizador no finaliza
        // despues de haber sido cancelado.

        wait_cycles(11);
        check_done(1'b0);


        // -------------------------------------------------
        // PRUEBA 6: NUEVO INICIO DURANTE CUENTA
        // -------------------------------------------------

        $display("\nPRUEBA 6: NUEVO INICIO DURANTE CUENTA");

        start_timer(20'd8);

        // Intentar iniciar otro temporizador mientras
        // el primero todavia esta activo.

        start_timer(20'd2);

        // El segundo inicio debe ser ignorado.
        // La cuenta original debe conservar sus 8 ciclos.

        wait_cycles(4);
        check_done(1'b0);

        wait_cycles(1);
        check_done(1'b0);

        wait_cycles(1);
        check_done(1'b1);

        wait_cycles(1);
        check_done(1'b0);


        // -------------------------------------------------
        // PRUEBA 7: RETARDO DE UN CICLO
        // -------------------------------------------------

        $display("\nPRUEBA 7: RETARDO DE UN CICLO");

        start_timer(20'd1);

        wait_cycles(1);
        check_done(1'b1);

        wait_cycles(1);
        check_done(1'b0);


        // -------------------------------------------------
        // PRUEBA 8: RESET DURANTE UNA CUENTA ACTIVA
        // -------------------------------------------------

        $display("\nPRUEBA 8: RESET DURANTE CUENTA");

        start_timer(20'd10);

        wait_cycles(3);

        @(negedge clk);
        rst = 1'b1;

        @(posedge clk);
        #1;

        check_done(1'b0);

        @(negedge clk);
        rst = 1'b0;

        // Comprobar que la cuenta anterior
        // no se reanuda despues del reset.

        wait_cycles(11);
        check_done(1'b0);


        // -------------------------------------------------
        // 8. RESUMEN FINAL
        // -------------------------------------------------

        $display("\n======================================");
        $display(" RESULTADOS DE LA SIMULACION");
        $display("======================================");

        $display("Checks ejecutados : %0d", checks);
        $display("Errores detectados: %0d", errors);

        if (errors == 0) begin
            $display("RESULTADO: TODAS LAS PRUEBAS APROBADAS");
        end
        else begin
            $display("RESULTADO: SE DETECTARON ERRORES");
        end

        $display("======================================");

        $finish;

    end

endmodule
