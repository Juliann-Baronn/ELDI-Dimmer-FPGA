
`timescale 1ns / 1ps

// ============================================================
// PROYECTO: DIMMER DIGITAL ELDI
// MODULO: M3 - pot_to_delay
// FPGA: Nexys 4 DDR - Artix-7
// RELOJ: 100 MHz
//
// CONVERSION:
// pot_sample[11:0] -> delay_target[19:0]
//
// PARAMETROS:
// D_MIN = 10000
// D_MAX = 800000
// SPAN  = 790000
//
// MAPEO INVERSO:
// P = 0    -> D_MAX
// P = 4095 -> D_MIN
//
// RESET:
// Sincrono activo alto
//
// ARQUITECTURA PIPELINE:
// Etapa 1: Multiplicacion P * SPAN
// Etapa 2: Redondeo
// Etapa 3: Sumas parciales del reciproco
// Etapa 4: Suma final y extraccion del cociente
// Etapa 5: Resta y actualizacion de salida
//
// DIVISION EXACTA POR 4095:
//
// floor(X / 4095) =
// floor((X * 4296016129) / 2^44)
//
// Esta equivalencia es exacta para el rango de X
// utilizado en este proyecto.
//
// 4296016129 = 1 + 2^8 + 2^20 + 2^32
//
// ============================================================

module pot_to_delay #(
    parameter [19:0] D_MIN = 20'd10000,
    parameter [19:0] D_MAX = 20'd800000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [11:0] pot_sample,
    input  wire        sample_valid,
    output reg  [19:0] delay_target
);

    // ========================================================
    // 1. PARAMETROS
    // ========================================================

    localparam [19:0] SPAN = D_MAX - D_MIN;

    localparam [31:0] ROUND_OFFSET = 32'd2047;

    // Constante reciproca:
    // ceil(2^44 / 4095) = 4296016129

    localparam [32:0] RECIPROCAL = 33'd4296016129;

    // ========================================================
    // 2. ETAPA 1: MULTIPLICACION
    // ========================================================

    wire [31:0] pot_extended;
    wire [31:0] span_extended;
    wire [31:0] product_next;

    assign pot_extended  = {20'd0, pot_sample};
    assign span_extended = {12'd0, SPAN};

    assign product_next = pot_extended * span_extended;

    reg [31:0] product_reg;
    reg valid_stage1;

    // ========================================================
    // 3. ETAPA 2: REDONDEO
    // ========================================================

    wire [31:0] rounded_product_next;

    assign rounded_product_next =
        product_reg + ROUND_OFFSET;

    reg [31:0] rounded_product_reg;
    reg valid_stage2;

    // ========================================================
    // 4. ETAPA 3: SUMAS PARCIALES
    // ========================================================

    // Descomposicion de la constante:
    //
    // 4296016129 =
    // 1 + 256 + 1048576 + 4294967296
    //
    // X * RECIPROCAL =
    // X + (X << 8) + (X << 20) + (X << 32)

    wire [63:0] partial_a_next;
    wire [63:0] partial_b_next;

    assign partial_a_next =
        {32'd0, rounded_product_reg} +
        {24'd0, rounded_product_reg, 8'd0};

    assign partial_b_next =
        {12'd0, rounded_product_reg, 20'd0} +
        {rounded_product_reg, 32'd0};

    reg [63:0] partial_a_reg;
    reg [63:0] partial_b_reg;

    reg valid_stage3;

    // ========================================================
    // 5. ETAPA 4: SUMA FINAL Y COCIENTE
    // ========================================================

    wire [63:0] reciprocal_product;

    assign reciprocal_product =
        partial_a_reg + partial_b_reg;

    wire [19:0] quotient_next;

    // Division por 2^44 mediante desplazamiento.
    // El cociente queda en los bits [63:44].

    assign quotient_next = reciprocal_product[63:44];

    reg [19:0] quotient_reg;
    reg valid_stage4;

    // ========================================================
    // 6. ETAPA 5: RESTA Y SALIDA
    // ========================================================

    wire [19:0] delay_calculated;

    assign delay_calculated = D_MAX - quotient_reg;

    // ========================================================
    // 7. VALIDACION DE PARAMETROS
    // ========================================================

`ifndef SYNTHESIS

    initial begin

        if (D_MAX < D_MIN) begin

            $display("ERROR M3: D_MAX debe ser >= D_MIN");
            $finish;

        end

        if ((64'd4095 * (D_MAX - D_MIN) + 64'd2047)
             > 64'hFFFFFFFF) begin

            $display("ERROR M3: producto y redondeo exceden 32 bits");
            $finish;

        end

        // Condicion para garantizar la division reciproca exacta
        // en todo el rango de entradas del modulo.

        if ((64'd3839 *
             (64'd4095 * (D_MAX - D_MIN) + 64'd2047))
             >= 64'd17592186044416) begin

            $display("ERROR M3: rango fuera de la condicion del reciproco");
            $finish;

        end

    end

`endif

    // ========================================================
    // 8. REGISTROS PIPELINE
    // ========================================================

    always @(posedge clk) begin

        if (rst) begin

            // ETAPA 1
            product_reg <= 32'd0;
            valid_stage1 <= 1'b0;

            // ETAPA 2
            rounded_product_reg <= 32'd0;
            valid_stage2 <= 1'b0;

            // ETAPA 3
            partial_a_reg <= 64'd0;
            partial_b_reg <= 64'd0;
            valid_stage3 <= 1'b0;

            // ETAPA 4
            quotient_reg <= 20'd0;
            valid_stage4 <= 1'b0;

            // SALIDA
            delay_target <= D_MAX;

        end

        else begin

            // ------------------------------------------------
            // ETAPA 1: MULTIPLICACION
            // ------------------------------------------------

            valid_stage1 <= sample_valid;

            if (sample_valid)
                product_reg <= product_next;


            // ------------------------------------------------
            // ETAPA 2: REDONDEO
            // ------------------------------------------------

            valid_stage2 <= valid_stage1;

            if (valid_stage1)
                rounded_product_reg <= rounded_product_next;


            // ------------------------------------------------
            // ETAPA 3: SUMAS PARCIALES
            // ------------------------------------------------

            valid_stage3 <= valid_stage2;

            if (valid_stage2) begin

                partial_a_reg <= partial_a_next;
                partial_b_reg <= partial_b_next;

            end


            // ------------------------------------------------
            // ETAPA 4: SUMA FINAL Y COCIENTE
            // ------------------------------------------------

            valid_stage4 <= valid_stage3;

            if (valid_stage3)
                quotient_reg <= quotient_next;


            // ------------------------------------------------
            // ETAPA 5: RESULTADO FINAL
            // ------------------------------------------------

            if (valid_stage4)
                delay_target <= delay_calculated;

        end

    end

endmodule
