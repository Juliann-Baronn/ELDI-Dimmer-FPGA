
module zero_cross_detect (
    input  wire clk,
    input  wire rst,
    input  wire zc_sync,
    output reg  zc_event
);

    reg zc_prev;
    reg armed;

    always @(posedge clk) begin
        if (rst) begin
            zc_prev  <= 1'b0;
            armed    <= 1'b0;
            zc_event <= 1'b0;
        end else begin
            zc_event <= 1'b0;

            if (!zc_sync) begin
                zc_prev <= 1'b0;
                armed   <= 1'b1;
            end else begin
                if (armed && !zc_prev)
                    zc_event <= 1'b1;

                zc_prev <= 1'b1;
            end
        end
    end

endmodule
