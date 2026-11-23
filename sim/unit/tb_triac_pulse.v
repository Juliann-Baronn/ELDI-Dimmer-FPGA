
`timescale 1ns / 1ps

module tb_triac_pulse;

    // ========================================================
    // PARAMETROS DE PRUEBA
    // ========================================================

    localparam [31:0] TEST_PULSE_WIDTH = 32'd5;

    // ========================================================
    // SEÑALES DEL TESTBENCH
    // ========================================================

    reg clk;
    reg rst;
    reg pulse_start;

    wire gate_pulse;
    wire pulse_done;

    integer errors;
    integer checks;
    integer i;

    // ========================================================
    // INSTANTIACION DEL MODULO M7
    // ========================================================

    triac_pulse #(
        .PULSE_WIDTH_CYCLES(TEST_PULSE_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .pulse_start(pulse_start),
        .gate_pulse(gate_pulse),
        .pulse_done(pulse_done)
    );

    // ========================================================
    // GENERADOR DE RELOJ: 100 MHz
    // ========================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ========================================================
    // TAREA PARA AVANZAR UN CICLO
    // ========================================================

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    // ========================================================
    // TAREA PARA VERIFICAR RESULTADOS
    // ========================================================

    task check;
        input condition;
        input [8*100:1] description;

        begin
            checks = checks + 1;

            if (condition !== 1'b1) begin
                errors = errors + 1;
                $display("[ERROR] %0s | Tiempo: %0t",
                         description, $time);
            end
            else begin
                $display("[OK] %0s | Tiempo: %0t",
                         description, $time);
            end
        end
    endtask

    // ========================================================
    // SECUENCIA PRINCIPAL DE PRUEBAS
    // ========================================================

    initial begin

        errors = 0;
        checks = 0;

        rst = 1'b1;
        pulse_start = 1'b0;

        $display("============================================");
        $display(" INICIO DE PRUEBAS DEL MODULO M7");
        $display(" triac_pulse");
        $display(" PULSE_WIDTH_CYCLES = %0d",
                 TEST_PULSE_WIDTH);
        $display("============================================");

        // ----------------------------------------------------
        // PRUEBA 1: RESET INICIAL
        // ----------------------------------------------------

        tick();

        check(gate_pulse == 1'b0,
              "Reset: gate_pulse permanece apagado");

        check(pulse_done == 1'b0,
              "Reset: pulse_done permanece apagado");

        @(negedge clk);
        rst = 1'b0;

        tick();

        check(gate_pulse == 1'b0,
              "IDLE: gate_pulse apagado");

        check(pulse_done == 1'b0,
              "IDLE: pulse_done apagado");

        // ----------------------------------------------------
        // PRUEBA 2: INICIO DEL PULSO
        // ----------------------------------------------------

        @(negedge clk);
        pulse_start = 1'b1;

        tick();

        check(gate_pulse == 1'b1,
              "Inicio: gate_pulse se activa");

        check(pulse_done == 1'b0,
              "Inicio: pulse_done permanece apagado");

        @(negedge clk);
        pulse_start = 1'b0;

        // ----------------------------------------------------
        // PRUEBA 3: DURACION EXACTA DE CINCO CICLOS
        // ----------------------------------------------------

        for (i = 1; i < TEST_PULSE_WIDTH; i = i + 1) begin

            // En el segundo ciclo se introduce otra solicitud.
            if (i == 2)
                pulse_start = 1'b1;
            else
                pulse_start = 1'b0;

            tick();

            check(gate_pulse == 1'b1,
                  "Duracion: gate_pulse continua activo");

            check(pulse_done == 1'b0,
                  "Duracion: pulse_done sigue apagado");

            @(negedge clk);

        end

        pulse_start = 1'b0;

        // ----------------------------------------------------
        // PRUEBA 4: SOLICITUD DURANTE PULSO ACTIVO
        // ----------------------------------------------------

        check(gate_pulse == 1'b1,
              "Solicitud adicional: pulso original sigue activo");

        // El siguiente flanco termina el pulso original.
        tick();

        check(gate_pulse == 1'b0,
              "Finalizacion: gate_pulse se desactiva");

        check(pulse_done == 1'b1,
              "Finalizacion: pulse_done se activa");

        // ----------------------------------------------------
        // PRUEBA 5: pulse_done DE UN SOLO CICLO
        // ----------------------------------------------------

        tick();

        check(pulse_done == 1'b0,
              "pulse_done vuelve a cero despues de un ciclo");

        check(gate_pulse == 1'b0,
              "Modulo vuelve a IDLE");

        // ----------------------------------------------------
        // PRUEBA 6: SEGUNDO PULSO
        // ----------------------------------------------------

        @(negedge clk);
        pulse_start = 1'b1;

        tick();

        check(gate_pulse == 1'b1,
              "Segundo pulso: modulo acepta nueva solicitud");

        @(negedge clk);
        pulse_start = 1'b0;

        // ----------------------------------------------------
        // PRUEBA 7: RESET DURANTE PULSO ACTIVO
        // ----------------------------------------------------

        tick();

        check(gate_pulse == 1'b1,
              "Segundo pulso: permanece activo");

        @(negedge clk);
        rst = 1'b1;

        tick();

        check(gate_pulse == 1'b0,
              "Reset durante pulso: cancela gate_pulse");

        check(pulse_done == 1'b0,
              "Reset durante pulso: pulse_done permanece apagado");

        @(negedge clk);
        rst = 1'b0;

        tick();

        check(gate_pulse == 1'b0,
              "Despues del reset: modulo permanece en IDLE");

        check(pulse_done == 1'b0,
              "Despues del reset: no hay finalizacion pendiente");

        // ----------------------------------------------------
        // RESUMEN
        // ----------------------------------------------------

        $display("");
        $display("============================================");
        $display(" RESUMEN DE SIMULACION M7");
        $display("============================================");
        $display("Checks ejecutados: %0d", checks);
        $display("Errores encontrados: %0d", errors);

        if (errors == 0)
            $display("RESULTADO: TODAS LAS PRUEBAS APROBADAS");
        else
            $display("RESULTADO: SE ENCONTRARON ERRORES");

        $display("============================================");

        $finish;

    end

endmodule
