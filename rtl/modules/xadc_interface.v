
module xadc_interface (

    input wire clk,       // Reloj del sistema de 100 MHz
    input wire rst,       // Reinicio de la logica interna de M1

    input wire vauxp3,    // Entrada analogica positiva del potenciometro
    input wire vauxn3,    // Entrada analogica negativa del potenciometro

    output reg [11:0] pot_sample, // Muestra digital de 12 bits
    output reg sample_valid       // Indica que se capturo una nueva muestra

);

    // =========================================
    // Declaracion de estados de la FSM
    // =========================================

    localparam IDLE  = 2'b00;
    localparam REQ   = 2'b01;
    localparam WAIT  = 2'b10;
    localparam REARM = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;


    // =========================================
    // Senales de comunicacion con el XADC
    // =========================================

    wire [15:0] do_out;
    wire drdy_out;

    wire [6:0] daddr;
    wire den;
    wire dwe;

    wire [15:0] di;


    // =========================================
    // Senal de control para captura de datos
    // =========================================

    wire capture_sample;


    // =========================================
    // Registro del temporizador
    // =========================================

    reg [16:0] timer_count;
    wire tick_1ms;


    // =========================================
    // Temporizador de 1 ms
    // =========================================

    assign tick_1ms = (timer_count == 17'd99999);

    always @(posedge clk) begin

        if (rst) begin
            timer_count <= 17'd0;
        end

        else if (state == IDLE && !drdy_out) begin

            if (tick_1ms) begin
                timer_count <= 17'd0;
            end

            else begin
                timer_count <= timer_count + 1'b1;
            end

        end

        else begin
            timer_count <= 17'd0;
        end

    end


    // =========================================
    // Logica combinacional de la FSM
    // =========================================

    always @(*) begin

        next_state = state;

        case (state)

            IDLE: begin

                if (tick_1ms && !drdy_out) begin
                    next_state = REQ;
                end

            end

            REQ: begin

                next_state = WAIT;

            end

            WAIT: begin

                if (drdy_out) begin
                    next_state = REARM;
                end

                else begin
                    next_state = WAIT;
                end

            end

            REARM: begin

                if (!drdy_out) begin
                    next_state = IDLE;
                end

                else begin
                    next_state = REARM;
                end

            end

            default: begin
                next_state = IDLE;
            end

        endcase

    end


    // =========================================
    // Registro de estado de la FSM
    // =========================================

    always @(posedge clk) begin

        if (rst) begin
            state <= IDLE;
        end

        else begin
            state <= next_state;
        end

    end


    // =========================================
    // Senales de control de la interfaz DRP
    // =========================================

    assign den   = (state == REQ);
    assign dwe   = 1'b0;
    assign daddr = 7'h13;
    assign di    = 16'h0000;


    // =========================================
    // Instancia del XADC Wizard
    // =========================================

    xadc_wiz_1 xadc_inst (

        .dclk_in(clk),

        .den_in(den),
        .dwe_in(dwe),
        .daddr_in(daddr),
        .di_in(di),

        .do_out(do_out),
        .drdy_out(drdy_out),

        .reset_in(rst),

        .vauxp3(vauxp3),
        .vauxn3(vauxn3),

        .vp_in(1'b0),
        .vn_in(1'b0)

    );


    // =========================================
    // Condicion de captura de datos
    // =========================================

    assign capture_sample = (state == WAIT) && drdy_out;


    // =========================================
    // Captura de datos y generacion de sample_valid
    // =========================================

    always @(posedge clk) begin

        if (rst) begin
            pot_sample <= 12'd0;
            sample_valid <= 1'b0;
        end

        else begin

            sample_valid <= 1'b0;

            if (capture_sample) begin

                pot_sample <= do_out[15:4];
                sample_valid <= 1'b1;

            end

        end

    end


endmodule
