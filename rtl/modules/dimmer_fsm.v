
`timescale 1ns / 1ps

// ============================================================
// MODULO: dimmer_fsm
// PROYECTO: Dimmer digital ELDI
// FPGA: Nexys 4 DDR - Artix 7
// RELOJ: 100 MHz
//
// FUNCION:
// Coordinar la deteccion de cruces por cero, la temporizacion
// de fase y la generacion del pulso de activacion del TRIAC.
//
// INTERFACES:
//
// M4 -> M6:
//   zc_event
//
// M5 -> M6:
//   timer_done
//
// M6 -> M5:
//   timer_start
//   timer_clear
//
// M6 -> M7:
//   triac_pulse_start
//
// M7 -> M6:
//   pulse_done
//
// CONVENCIONES:
// - Reset sincrono activo alto.
// - Prioridad de nuevo zc_event sobre timer_done.
// - Un nuevo cruce durante la cuenta cancela y reinicia M5.
// - Un nuevo cruce durante el pulso de M7 se guarda.
// - M7 termina siempre el pulso que ya comenzo.
// ============================================================

module dimmer_fsm (

    input wire clk,
    input wire rst,

    // --------------------------------------------------------
    // Entradas de control
    // --------------------------------------------------------

    input wire zc_event,
    input wire timer_done,
    input wire pulse_done,

    // --------------------------------------------------------
    // Control del temporizador M5
    // --------------------------------------------------------

    output reg timer_start,
    output reg timer_clear,

    // --------------------------------------------------------
    // Solicitud de disparo para M7
    // --------------------------------------------------------

    output reg triac_pulse_start

);

    // ========================================================
    // 1. DEFINICION DE ESTADOS
    // ========================================================

    localparam WAIT_ZC     = 3'd0;
    localparam START_TIMER = 3'd1;
    localparam WAIT_TIMER  = 3'd2;
    localparam CLEAR_TIMER = 3'd3;
    localparam FIRE_TRIAC  = 3'd4;
    localparam WAIT_PULSE  = 3'd5;

    reg [2:0] state;
    reg [2:0] next_state;

    // ========================================================
    // 2. REGISTRO DE EVENTO PENDIENTE
    // ========================================================

    reg pending_zc;

    // ========================================================
    // 3. REGISTRO DE ESTADO
    // Reset sincrono activo en alto
    // ========================================================

    always @(posedge clk) begin

        if (rst)
            state <= WAIT_ZC;

        else
            state <= next_state;

    end

    // ========================================================
    // 4. REGISTRO DE NUEVO CRUCE PENDIENTE
    // ========================================================

    always @(posedge clk) begin

        if (rst) begin

            pending_zc <= 1'b0;

        end

        else begin

            // Durante la solicitud de disparo y mientras
            // M7 genera el pulso, guardar nuevos cruces.

            if ((state == FIRE_TRIAC) ||
                (state == WAIT_PULSE)) begin

                // Cuando M7 termina, consumir el evento
                // pendiente. Un zc_event simultaneo tambien
                // sera considerado por la FSM.

                if (pulse_done)
                    pending_zc <= 1'b0;

                else if (zc_event)
                    pending_zc <= 1'b1;

            end

            // Fuera de esta secuencia no se necesita
            // conservar eventos anteriores.

            else begin

                pending_zc <= 1'b0;

            end

        end

    end

    // ========================================================
    // 5. LOGICA DE TRANSICION DE ESTADOS
    // ========================================================

    always @(*) begin

        next_state = state;

        case (state)

            // ------------------------------------------------
            // ESPERAR CRUCE POR CERO
            // ------------------------------------------------

            WAIT_ZC: begin

                if (zc_event)
                    next_state = START_TIMER;

            end

            // ------------------------------------------------
            // SOLICITAR INICIO DE M5
            // ------------------------------------------------

            START_TIMER: begin

                next_state = WAIT_TIMER;

            end

            // ------------------------------------------------
            // ESPERAR FINALIZACION O NUEVO CRUCE
            // ------------------------------------------------

            WAIT_TIMER: begin

                // Prioridad al nuevo cruce por cero.
                // Se cancela la cuenta anterior.

                if (zc_event)
                    next_state = CLEAR_TIMER;

                else if (timer_done)
                    next_state = FIRE_TRIAC;

            end

            // ------------------------------------------------
            // CANCELAR CUENTA ANTERIOR
            // ------------------------------------------------

            CLEAR_TIMER: begin

                next_state = START_TIMER;

            end

            // ------------------------------------------------
            // SOLICITAR PULSO A M7
            // ------------------------------------------------

            FIRE_TRIAC: begin

                // M7 recibe la solicitud y comienza
                // la generacion del pulso.

                next_state = WAIT_PULSE;

            end

            // ------------------------------------------------
            // ESPERAR FINALIZACION DEL PULSO DE M7
            // ------------------------------------------------

            WAIT_PULSE: begin

                if (pulse_done) begin

                    // Si aparecio un nuevo cruce mientras
                    // M7 estaba ocupado, iniciar otra cuenta.

                    if (pending_zc || zc_event)
                        next_state = START_TIMER;

                    else
                        next_state = WAIT_ZC;

                end

            end

            // ------------------------------------------------
            // RECUPERACION ANTE ESTADO NO VALIDO
            // ------------------------------------------------

            default: begin

                next_state = WAIT_ZC;

            end

        endcase

    end

    // ========================================================
    // 6. LOGICA DE SALIDAS
    // ========================================================

    always @(*) begin

        timer_start       = 1'b0;
        timer_clear       = 1'b0;
        triac_pulse_start = 1'b0;

        case (state)

            // ------------------------------------------------
            // INICIO DE TEMPORIZACION
            // ------------------------------------------------

            START_TIMER: begin

                timer_start = 1'b1;

            end

            // ------------------------------------------------
            // CANCELACION DE TEMPORIZACION
            // ------------------------------------------------

            CLEAR_TIMER: begin

                timer_clear = 1'b1;

            end

            // ------------------------------------------------
            // SOLICITUD DE DISPARO
            // ------------------------------------------------

            FIRE_TRIAC: begin

                triac_pulse_start = 1'b1;

            end

            default: begin

                // Salidas en cero.

            end

        endcase

    end

endmodule
