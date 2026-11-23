
`timescale 1ns / 1ps

// ============================================================
// TOP: top_dimmer
// Proyecto: Dimmer digital ELDI
// FPGA: Digilent Nexys 4 DDR - Artix-7
// Reloj: 100 MHz
//
// Integra los modulos M1 a M7.
//
// M8 es la etapa externa de aislamiento y potencia.
// La salida gate_pulse se entrega a dicha interfaz.
// ============================================================

module top_dimmer #(
    parameter [31:0] PULSE_WIDTH_CYCLES = 32'd1000
)(
    // --------------------------------------------------------
    // Entradas de la placa
    // --------------------------------------------------------
    input  wire clk,
    input  wire CPU_RESETN,

    // Entrada del detector externo de cruce por cero
    input  wire zc_in,

    // Entradas analogicas del XADC (VAUX3)
    input  wire vauxp3,
    input  wire vauxn3,

    // --------------------------------------------------------
    // Salida digital hacia la interfaz externa M8
    // --------------------------------------------------------
    output wire gate_pulse
);

    // ========================================================
    // 1. RESET
    // El boton CPU_RESETN de la Nexys 4 DDR es activo bajo.
    // Los modulos internos utilizan reset sincrono activo alto.
    // ========================================================

    wire rst;
    assign rst = ~CPU_RESETN;

    // ========================================================
    // 2. DECLARACION DE SENALES INTERNAS
    // ========================================================

    // M1 -> M3
    wire [11:0] pot_sample;
    wire sample_valid;

    // M2 -> M4
    wire zc_sync;

    // M4 -> M6
    wire zc_event;

    // M3 -> M5
    wire [19:0] delay_target;

    // M5 <-> M6
    wire timer_start;
    wire timer_clear;
    wire timer_done;

    // M6 <-> M7
    wire triac_pulse_start;
    wire pulse_done;

    // ========================================================
    // 3. M1: INTERFAZ XADC
    // Adquiere la posicion del potenciometro.
    // ========================================================

    xadc_interface M1 (
        .clk          (clk),
        .rst          (rst),
        .vauxp3       (vauxp3),
        .vauxn3       (vauxn3),
        .pot_sample   (pot_sample),
        .sample_valid (sample_valid)
    );

    // ========================================================
    // 4. M2: SINCRONIZADOR DE CRUCE POR CERO
    // Sincroniza la entrada asincrona zc_in con clk.
    // ========================================================

    zero_cross_sync M2 (
        .clk     (clk),
        .rst     (rst),
        .zc_in   (zc_in),
        .zc_sync (zc_sync)
    );

    // ========================================================
    // 5. M3: CONVERSION POTENCIOMETRO A RETARDO
    // Convierte la muestra ADC en un retardo de fase.
    // ========================================================

    pot_to_delay M3 (
        .clk          (clk),
        .rst          (rst),
        .pot_sample   (pot_sample),
        .sample_valid (sample_valid),
        .delay_target (delay_target)
    );

    // ========================================================
    // 6. M4: DETECTOR DE CRUCE POR CERO
    // Genera zc_event al detectar el flanco correspondiente.
    // ========================================================

    zero_cross_detect M4 (
        .clk      (clk),
        .rst      (rst),
        .zc_sync  (zc_sync),
        .zc_event (zc_event)
    );

    // ========================================================
    // 7. M5: TEMPORIZADOR DE FASE
    // Cuenta el retardo capturado al recibir timer_start.
    // ========================================================

    phase_timer M5 (
        .clk          (clk),
        .rst          (rst),
        .timer_start  (timer_start),
        .timer_clear  (timer_clear),
        .delay_target (delay_target),
        .timer_done   (timer_done)
    );

    // ========================================================
    // 8. M6: MAQUINA DE ESTADOS PRINCIPAL
    // Coordina el temporizador y la generacion del pulso.
    // ========================================================

    dimmer_fsm M6 (
        .clk               (clk),
        .rst               (rst),
        .zc_event          (zc_event),
        .timer_done        (timer_done),
        .pulse_done        (pulse_done),
        .timer_start       (timer_start),
        .timer_clear       (timer_clear),
        .triac_pulse_start (triac_pulse_start)
    );

    // ========================================================
    // 9. M7: GENERADOR DEL PULSO DE DISPARO
    // Genera gate_pulse y notifica cuando termina.
    // ========================================================

    triac_pulse #(
        .PULSE_WIDTH_CYCLES (PULSE_WIDTH_CYCLES)
    ) M7 (
        .clk         (clk),
        .rst         (rst),
        .pulse_start (triac_pulse_start),
        .gate_pulse  (gate_pulse),
        .pulse_done  (pulse_done)
    );

endmodule
