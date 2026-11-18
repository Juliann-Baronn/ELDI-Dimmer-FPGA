
module top_xadc_test (
    input  wire        clk,
    input  wire        CPU_RESETN,
    input  wire        vauxp3,
    input  wire        vauxn3,
    output wire [11:0] led
);

    wire [11:0] pot_sample;
    wire        sample_valid;
    wire        rst;

    // CPU_RESETN es activo en bajo.
    // M1 utiliza reset sincrono activo en alto.
    assign rst = ~CPU_RESETN;

    xadc_interface u_xadc_interface (
        .clk          (clk),
        .rst          (rst),
        .vauxp3       (vauxp3),
        .vauxn3       (vauxn3),
        .pot_sample   (pot_sample),
        .sample_valid (sample_valid)
    );

    assign led = pot_sample;

endmodule
