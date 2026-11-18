
module zero_cross_sync (
    input  wire clk,
    input  wire rst,
    input  wire zc_in,
    output wire zc_sync
);

    // Registros de sincronizacion
    (* ASYNC_REG = "TRUE" *) reg sync_ff1;
    (* ASYNC_REG = "TRUE" *) reg sync_ff2;

    always @(posedge clk) begin
        if (rst) begin
            sync_ff1 <= 1'b0;
            sync_ff2 <= 1'b0;
        end else begin
            sync_ff1 <= zc_in;
            sync_ff2 <= sync_ff1;
        end
    end

    assign zc_sync = sync_ff2;

endmodule
