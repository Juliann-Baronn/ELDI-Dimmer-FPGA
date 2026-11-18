`timescale 1ns / 1ps

//======================================================
// TESTBENCH: tb_phase_timer
// PROYECTO: Dimmer digital ELDI
// MODULO PROBADO: M5 phase_timer
// RELOJ: 100 MHz
//======================================================

module tb_phase_timer;

    //==================================================
    // 1. SEÑALES DE PRUEBA
    //==================================================

    reg clk;
    reg rst;

    reg timer_start;
    reg timer_clear;

    reg [19:0] delay_target;

    wire timer_done;


    //==================================================
    // 2. INSTANCIA DEL MODULO M5
    //==================================================

    phase_timer uut (

        .clk(clk),
        .rst(rst),

        .timer_start(timer_start),
        .timer_clear(timer_clear),

        .delay_target(delay_target),

        .timer_done(timer_done)

    );


    //==================================================
    // 3. GENERACION DEL RELOJ
    //==================================================

    initial begin
        clk = 1'b0;
    end

    always begin
        #5 clk = ~clk;
    end


    //==================================================
    // 4. TAREA PARA INICIAR EL TEMPORIZADOR
    //==================================================

    task start_timer;

        begin

            @(negedge clk);
            timer_start = 1'b1;

            @(negedge clk);
            timer_start = 1'b0;

        end

    endtask


    //==================================================
    // 5. TAREA PARA VERIFICAR UN RETARDO
    //==================================================

    task check_delay;

        input [19:0] target;
        input integer expected_cycles;

        integer elapsed;

        begin

            @(negedge clk);

            delay_target = target;

            timer_start = 1'b1;

            @(negedge clk);

            timer_start = 1'b0;

            elapsed = 0;

            // Esperar hasta timer_done
            while (timer_done !== 1'b1 &&
                   elapsed <= expected_cycles) begin

                @(negedge clk);

                elapsed = elapsed + 1;

            end

            // Comprobar resultado
            if (timer_done !== 1'b1) begin

                $display(
                    "ERROR: No finalizo el conteo."
                );

                $fatal;

            end

            if (elapsed != expected_cycles) begin

                $display(
                    "ERROR: Conteo incorrecto. Esperado=%0d, Obtenido=%0d",
                    expected_cycles,
                    elapsed
                );

                $fatal;

            end

            // Comprobar que DONE dura un ciclo
            @(negedge clk);

            if (timer_done !== 1'b0) begin

                $display(
                    "ERROR: timer_done duro mas de un ciclo."
                );

                $fatal;

            end

            $display(
                "PASS: delay_target=%0d, ciclos=%0d",
                target,
                elapsed
            );

        end

    endtask


    //==================================================
    // 6. SECUENCIA PRINCIPAL DE PRUEBAS
    //==================================================

    initial begin

        // Inicializacion
        rst = 1'b1;

        timer_start = 1'b0;
        timer_clear = 1'b0;

        delay_target = 20'd0;


        //==============================================
        // PRUEBA 1: RESET
        //==============================================

        repeat(5) @(negedge clk);

        rst = 1'b0;

        @(negedge clk);

        if (timer_done !== 1'b0) begin

            $display("ERROR: Reset incorrecto.");
            $fatal;

        end

        $display("PASS: Reset inicial");


        //==============================================
        // PRUEBA 2: RETARDO DE 1 CICLO
        //==============================================

        check_delay(20'd1, 1);


        //==============================================
        // PRUEBA 3: RETARDO DE 2 CICLOS
        //==============================================

        check_delay(20'd2, 2);


        //==============================================
        // PRUEBA 4: RETARDO DE 3 CICLOS
        //==============================================

        check_delay(20'd3, 3);


        //==============================================
        // PRUEBA 5: RETARDO DE 5 CICLOS
        //==============================================

        check_delay(20'd5, 5);


        //==============================================
        // PRUEBA 6: RETARDO CERO
        //==============================================

        check_delay(20'd0, 0);


        //==============================================
        // PRUEBA 7: CAMBIO DE DELAY DURANTE CONTEO
        //==============================================

        @(negedge clk);

        delay_target = 20'd5;

        timer_start = 1'b1;

        @(negedge clk);

        timer_start = 1'b0;

        // Esperar dos ciclos
        repeat(2) @(negedge clk);

        // Cambiar el valor proveniente de M3
        delay_target = 20'd2;

        // El contador debe conservar el objetivo original
        if (uut.delay_register !== 20'd5) begin

            $display(
                "ERROR: No se capturo correctamente delay_target."
            );

            $fatal;

        end

        repeat(3) @(negedge clk);

        if (timer_done !== 1'b1) begin

            $display(
                "ERROR: El cambio de delay altero la temporizacion."
            );

            $fatal;

        end

        @(negedge clk);

        $display(
            "PASS: Cambio de delay durante conteo"
        );


        //==============================================
        // PRUEBA 8: CANCELACION DURANTE CONTEO
        //==============================================

        @(negedge clk);

        delay_target = 20'd10;

        timer_start = 1'b1;

        @(negedge clk);

        timer_start = 1'b0;

        repeat(3) @(negedge clk);

        timer_clear = 1'b1;

        @(negedge clk);

        timer_clear = 1'b0;

        repeat(12) @(negedge clk);

        if (timer_done !== 1'b0 || uut.active !== 1'b0) begin

            $display(
                "ERROR: La cancelacion no funciono."
            );

            $fatal;

        end

        $display(
            "PASS: Cancelacion mediante timer_clear"
        );


        //==============================================
        // PRUEBA 9: CLEAR Y START SIMULTANEOS
        //==============================================

        @(negedge clk);

        timer_start = 1'b1;
        timer_clear = 1'b1;

        delay_target = 20'd5;

        @(negedge clk);

        timer_start = 1'b0;
        timer_clear = 1'b0;

        if (uut.active !== 1'b0) begin

            $display(
                "ERROR: CLEAR no tuvo prioridad."
            );

            $fatal;

        end

        $display(
            "PASS: Prioridad de timer_clear"
        );


        //==============================================
        // PRUEBA 10: START MANTENIDO
        //==============================================

        @(negedge clk);

        delay_target = 20'd3;
        timer_start = 1'b1;

        // Mantener START activo durante varios ciclos
        repeat(7) @(negedge clk);

        timer_start = 1'b0;

        if (timer_done !== 1'b0) begin

            $display(
                "ERROR: START mantenido produjo un nuevo disparo."
            );

            $fatal;

        end

        $display(
            "PASS: START mantenido no reinicia el contador"
        );


        //==============================================
        // PRUEBA 11: RETARDO REPRESENTATIVO
        //==============================================

        check_delay(20'd1100, 1100);


        //==============================================
        // FINALIZACION
        //==============================================

        $display("--------------------------------");
        $display("TODAS LAS PRUEBAS FINALIZARON");
        $display("M5 VERIFICADO EN LOS CASOS PROBADOS");
        $display("--------------------------------");

        $finish;

    end

endmodule