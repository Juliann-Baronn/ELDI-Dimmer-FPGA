module phase_timer (
    input wire clk,
    input wire rst,

    input wire timer_start,
    input wire timer_clear,

    input wire [19:0] delay_target,

    output reg timer_done
);

    // Registro de cuenta regresiva
    reg [19:0] counter;

    // Control interno del temporizador
    reg active;

    // Registro para detectar el flanco ascendente de timer_start
    reg timer_start_prev;

    // Evento de inicio
    wire start_event;

    assign start_event = timer_start && !timer_start_prev;


    always @(posedge clk) begin

        // Reset síncrono activo en alto
        if (rst) begin

            counter          <= 20'd0;
            active           <= 1'b0;
            timer_done       <= 1'b0;
            timer_start_prev <= 1'b0;

        end

        else begin

            // Actualizar referencia para detectar el siguiente flanco
            timer_start_prev <= timer_start;

            // timer_done es un pulso de un ciclo de reloj
            timer_done <= 1'b0;


            // 1. Limpiar o cancelar el temporizador
            if (timer_clear) begin

                counter <= 20'd0;
                active  <= 1'b0;

            end


            // 2. Aceptar una nueva solicitud de temporización
            else if (start_event && !active) begin

                // Capturar el valor de referencia al iniciar
                counter <= delay_target;

                // Si el retardo es cero, finalizar inmediatamente
                if (delay_target == 20'd0) begin

                    active     <= 1'b0;
                    timer_done <= 1'b1;

                end

                else begin

                    active <= 1'b1;

                end

            end


            // 3. Ejecutar la cuenta regresiva
            else if (active) begin

                // Finalizar cuando se alcanza el último ciclo
                if (counter == 20'd1) begin

                    counter    <= 20'd0;
                    active     <= 1'b0;
                    timer_done <= 1'b1;

                end

                else begin

                    counter <= counter - 20'd1;

                end

            end

        end

    end

endmodule