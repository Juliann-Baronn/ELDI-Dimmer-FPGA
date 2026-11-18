`timescale 1ns / 1ps

// M3: conversion de pot_sample (12 bits) a delay_target (20 bits).
// Parametros acordados: D_MIN=10000, D_MAX=800000, SPAN=790000.
// Reloj: 100 MHz. Mapeo inverso: P=0 -> D_MAX; P=4095 -> D_MIN.
// Reset sincrono activo alto. La salida solo cambia con sample_valid.

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

    localparam [19:0] SPAN = D_MAX - D_MIN;
    localparam [31:0] ROUND_OFFSET = 32'd2047;
    localparam [31:0] POT_MAX = 32'd4095;

    wire [31:0] pot_extended  = {20'd0, pot_sample};
    wire [31:0] span_extended = {12'd0, SPAN};

    // Maximo: 4095*790000+2047 = 3235052047 < 2^32.
    wire [31:0] product         = pot_extended * span_extended;
    wire [31:0] rounded_product = product + ROUND_OFFSET;
    wire [31:0] quotient        = rounded_product / POT_MAX;

    wire [19:0] delay_calculated = D_MAX - quotient[19:0];

`ifndef SYNTHESIS
    initial begin
        if (D_MAX < D_MIN) begin
            $display("ERROR pot_to_delay: D_MAX debe ser >= D_MIN");
            $finish;
        end
        if ((64'd4095 * (D_MAX - D_MIN) + 64'd2047) > 64'hFFFFFFFF) begin
            $display("ERROR pot_to_delay: producto mas redondeo excede 32 bits");
            $finish;
        end
    end
`endif

    always @(posedge clk) begin
        if (rst)
            delay_target <= D_MAX;
        else if (sample_valid)
            delay_target <= delay_calculated;
    end

endmodule
