module clock_divider (
    input  wire        clk_in,
    input  wire [8:0]  divisor,
    output reg         clk_out
);

    reg [8:0] counter;

    always @(posedge clk_in) begin
        if (counter == divisor - 1) begin
            counter <= 9'd0;
        end else begin
            counter <= counter + 9'd1;
        end

        // 50% duty-cycle clock
        clk_out <= (counter < (divisor >> 1));
    end

endmodule
