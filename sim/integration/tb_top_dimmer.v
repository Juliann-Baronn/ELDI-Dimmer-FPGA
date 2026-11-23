
`timescale 1ns / 1ps

// ============================================================
// TESTBENCH: tb_top_dimmer
// PROYECTO: DIMMER DIGITAL ELDI
// FPGA: Nexys 4 DDR
//
// Verificacion de integracion:
// M2 -> M4 -> M6 -> M5 -> M6 -> M7
//
// M1 y M3 no se validan en esta simulacion.
// delay_target se fuerza temporalmente para aislar
// la cadena digital de control.
//
// Ancho de pulso de prueba: 8 ciclos.
// ============================================================

module tb_top_dimmer;

    localparam integer CLK_PERIOD = 10;
    localparam integer TEST_PULSE_WIDTH = 8;

    reg clk;
    reg CPU_RESETN;
    reg zc_in;
    reg vauxp3;
    reg vauxn3;

    wire gate_pulse;

    integer pulse_cycles;
    integer errors;
    integer i;

    reg pulse_detected;

    // --------------------------------------------------------
    // INSTANCIA DEL TOP
    // --------------------------------------------------------

    top_dimmer #(
        .PULSE_WIDTH_CYCLES(TEST_PULSE_WIDTH)
    ) dut (
        .clk        (clk),
        .CPU_RESETN (CPU_RESETN),
        .zc_in      (zc_in),
        .vauxp3     (vauxp3),
        .vauxn3     (vauxn3),
        .gate_pulse (gate_pulse)
    );

    // --------------------------------------------------------
    // RELOJ DE 100 MHz
    // --------------------------------------------------------

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // --------------------------------------------------------
    // SECUENCIA PRINCIPAL
    // --------------------------------------------------------

    initial begin

        CPU_RESETN = 1'b0;
        zc_in = 1'b0;

        vauxp3 = 1'b0;
        vauxn3 = 1'b0;

        pulse_cycles = 0;
        errors = 0;
        pulse_detected = 1'b0;

        $display("--------------------------------------");
        $display(" INICIO TB_TOP_DIMMER");
        $display("--------------------------------------");

        // 1. RESET

        repeat (5) @(posedge clk);

        #1;
        CPU_RESETN = 1'b1;

        repeat (5) @(posedge clk);

        $display("[%0t] Reset liberado", $time);

        // 2. RETARDO CONTROLADO PARA SIMULACION

        force dut.delay_target = 20'd10;

        $display("[%0t] delay_target = 10 ciclos",
                 $time);

        // 3. ARMAR DETECTOR DE CRUCE

        repeat (5) @(posedge clk);

        // 4. GENERAR EVENTO DE CRUCE POR CERO

        @(negedge clk);
        zc_in = 1'b1;

        repeat (4) @(negedge clk);

        zc_in = 1'b0;

        $display("[%0t] Cruce por cero aplicado", $time);

        // 5. ESPERAR gate_pulse CON TIMEOUT

        for (i = 0; i < 100; i = i + 1) begin

            @(posedge clk);
            #1;

            if (gate_pulse === 1'b1) begin
                pulse_detected = 1'b1;
                i = 100;
            end

        end

        if (pulse_detected == 1'b0) begin

            $display("[ERROR] No se detecto gate_pulse");
            errors = errors + 1;

        end

        else begin

            $display("[%0t] gate_pulse detectado", $time);

            // 6. MEDIR DURACION DEL PULSO

            pulse_cycles = 1;

            while (gate_pulse === 1'b1) begin

                @(posedge clk);
                #1;

                if (gate_pulse === 1'b1)
                    pulse_cycles = pulse_cycles + 1;

            end

            $display("[%0t] Duracion: %0d ciclos",
                     $time, pulse_cycles);

            if (pulse_cycles == TEST_PULSE_WIDTH) begin

                $display("[OK] Ancho de pulso correcto");

            end

            else begin

                $display("[ERROR] Ancho de pulso incorrecto");
                errors = errors + 1;

            end

        end

        // 7. RESULTADO FINAL

        repeat (5) @(posedge clk);

        $display("--------------------------------------");

        if (errors == 0) begin
            $display(" RESULTADO: SIMULACION COMPLETADA");
            $display(" ERRORES: 0");
        end

        else begin
            $display(" RESULTADO: SIMULACION CON ERRORES");
            $display(" ERRORES: %0d", errors);
        end

        $display("--------------------------------------");

        $finish;

    end

endmodule


