
`timescale 1ns / 1ps

// ============================================================
// MODULO: triac_pulse
// PROYECTO: Dimmer digital ELDI
// FPGA: Nexys 4 DDR - Artix 7
// RELOJ: 100 MHz
//
// FUNCION:
// Generar un pulso digital de duracion parametrizable
// cuando recibe pulse_start.
//
// INTERFAZ:
// Entradas:
//   clk
//   rst
//   pulse_start
//
// Salidas:
//   gate_pulse
//   pulse_done
//
// FSM:
//   IDLE
//   PULSE_ACTIVE
//   PULSE_DONE
//
// CONVENCIONES:
// - Reset sincrono activo alto.
// - pulse_start es una solicitud de un ciclo.
// - Solicitudes durante PULSE_ACTIVE se ignoran.
// - gate_pulse permanece activo durante N ciclos.
// - pulse_done dura exactamente un ciclo.
// - El reset cancela cualquier pulso en curso.
// ============================================================

module triac_pulse #(
    parameter [31:0] PULSE_WIDTH_CYCLES = 32'd1000
)(
    input  wire clk,
    input  wire rst,
    input  wire pulse_start,

    output wire gate_pulse,
    output wire pulse_done
);

    // --------------------------------------------------------
    // Estados de la FSM
    // --------------------------------------------------------

    localparam [1:0]
        IDLE         = 2'b00,
        PULSE_ACTIVE = 2'b01,
        PULSE_DONE   = 2'b10;

    reg [1:0] state;
    reg [1:0] next_state;

    // --------------------------------------------------------
    // Contador ascendente
    // --------------------------------------------------------

    reg [31:0] counter;

    // --------------------------------------------------------
    // Registro de estado
    // --------------------------------------------------------

    always @(posedge clk) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // --------------------------------------------------------
    // Logica de siguiente estado
    // --------------------------------------------------------

    always @(*) begin

        next_state = state;

        case (state)

            IDLE: begin
                if (pulse_start)
                    next_state = PULSE_ACTIVE;
            end

            PULSE_ACTIVE: begin
                if (counter == PULSE_WIDTH_CYCLES - 1'b1)
                    next_state = PULSE_DONE;
            end

            PULSE_DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase

    end

    // --------------------------------------------------------
    // Control del contador
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (rst) begin
            counter <= 32'd0;
        end

        else begin

            case (state)

                IDLE: begin
                    counter <= 32'd0;
                end

                PULSE_ACTIVE: begin

                    if (counter < PULSE_WIDTH_CYCLES - 1'b1)
                        counter <= counter + 1'b1;
                    else
                        counter <= 32'd0;

                end

                PULSE_DONE: begin
                    counter <= 32'd0;
                end

                default: begin
                    counter <= 32'd0;
                end

            endcase

        end

    end

    // --------------------------------------------------------
    // Salidas
    // --------------------------------------------------------

    assign gate_pulse = (state == PULSE_ACTIVE);

    assign pulse_done = (state == PULSE_DONE);

endmodule
