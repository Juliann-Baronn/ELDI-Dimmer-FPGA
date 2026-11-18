module tb_xadc_interface;

    // =========================================
    // Senales de prueba
    // =========================================

    reg clk;
    reg rst;

    reg vauxp3;
    reg vauxn3;

    wire [11:0] pot_sample;
    wire sample_valid;

    // =========================================
    // Generacion del reloj de 100 MHz
    // =========================================

    initial begin
        clk = 1'b0;
    end

    always begin
        #5 clk = ~clk;
    end
    // =========================================
    // Generacion del reset
    // =========================================

    initial begin

        rst = 1'b1;

        vauxp3 = 1'b0;
        vauxn3 = 1'b0;

        #100;

        rst = 1'b0;

    end

    // =========================================
    // Instancia del modulo M1
    // =========================================

    xadc_interface uut (

        .clk(clk),
        .rst(rst),

        .vauxp3(vauxp3),
        .vauxn3(vauxn3),

        .pot_sample(pot_sample),
        .sample_valid(sample_valid)

    );

endmodule