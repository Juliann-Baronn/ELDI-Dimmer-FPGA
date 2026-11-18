`timescale 1ns / 1ps

module tb_pot_to_delay;

    localparam [19:0] D_MIN = 20'd10000;
    localparam [19:0] D_MAX = 20'd800000;

    reg clk, rst, sample_valid;
    reg [11:0] pot_sample;
    wire [19:0] delay_target;
    integer errors, checks;

    pot_to_delay #(.D_MIN(D_MIN), .D_MAX(D_MAX)) DUT (
        .clk(clk), .rst(rst), .pot_sample(pot_sample),
        .sample_valid(sample_valid), .delay_target(delay_target)
    );

    initial begin clk = 1'b0; forever #5 clk = ~clk; end

    task check_result;
        input [19:0] expected;
        input [255:0] test_name;
        begin
            checks = checks + 1;
            if (delay_target !== expected) begin
                $display("ERROR %0s: esperado=%0d obtenido=%0d",
                         test_name, expected, delay_target);
                errors = errors + 1;
            end else $display("OK %0s: %0d", test_name, delay_target);

            if ((delay_target < D_MIN) || (delay_target > D_MAX)) begin
                $display("ERROR %0s: salida fuera de rango", test_name);
                errors = errors + 1;
            end
        end
    endtask

    task apply_sample;
        input [11:0] value;
        input [19:0] expected;
        input [255:0] test_name;
        begin
            @(negedge clk);
            pot_sample = value;
            sample_valid = 1'b1;
            @(posedge clk);
            #1;
            check_result(expected, test_name);
            @(negedge clk);
            sample_valid = 1'b0;
        end
    endtask

    initial begin
        errors = 0;
        checks = 0;
        rst = 1'b0;
        pot_sample = 12'd0;
        sample_valid = 1'b0;

        // T01: reset sincrono tiene prioridad sobre sample_valid.
        @(negedge clk);
        rst = 1'b1;
        sample_valid = 1'b1;
        pot_sample = 12'd4095;
        @(posedge clk); #1;
        check_result(D_MAX, "T01 RESET PRIORITARIO");

        @(negedge clk);
        rst = 1'b0;
        sample_valid = 1'b0;

        // Extremos, cercanias y puntos intermedios.
        apply_sample(12'd0,    20'd800000, "T02 POT=0");
        apply_sample(12'd1,    20'd799807, "T03 POT=1");
        apply_sample(12'd1024, 20'd602452, "T04 POT=1024");
        apply_sample(12'd2048, 20'd404904, "T05 POT=2048");
        apply_sample(12'd3072, 20'd207355, "T06 POT=3072");
        apply_sample(12'd4094, 20'd10193,  "T07 POT=4094");
        apply_sample(12'd4095, 20'd10000,  "T08 POT=4095");

        // T09: sin sample_valid, la salida debe conservarse.
        @(negedge clk);
        pot_sample = 12'd0;
        sample_valid = 1'b0;
        @(posedge clk); #1;
        check_result(20'd10000, "T09 HOLD");

        // T10-T11: muestras validas en ciclos consecutivos.
        @(negedge clk);
        pot_sample = 12'd0; sample_valid = 1'b1;
        @(posedge clk); #1;
        check_result(20'd800000, "T10 CONSECUTIVA A");
        @(negedge clk);
        pot_sample = 12'd4095; sample_valid = 1'b1;
        @(posedge clk); #1;
        check_result(20'd10000, "T11 CONSECUTIVA B");

        apply_sample(12'd2048, 20'd404904, "T12A REPETIDA");
        apply_sample(12'd2048, 20'd404904, "T12B REPETIDA");

        // T13: reset vuelve a tener prioridad.
        @(negedge clk);
        rst = 1'b1; sample_valid = 1'b1; pot_sample = 12'd4095;
        @(posedge clk); #1;
        check_result(D_MAX, "T13 RESET Y SAMPLE_VALID");

        @(negedge clk);
        rst = 1'b0; sample_valid = 1'b0;
        apply_sample(12'd4095, 20'd10000, "T14 POST-RESET");

        $display("----------------------------------------------");
        $display("M3 - RESUMEN DE VERIFICACION");
        $display("Comprobaciones: %0d", checks);
        $display("Errores: %0d", errors);
        if (errors == 0)
            $display("RESULTADO: TODAS LAS PRUEBAS APROBADAS");
        else
            $display("RESULTADO: EXISTEN ERRORES");
        $display("----------------------------------------------");
        $finish;
    end
endmodule
