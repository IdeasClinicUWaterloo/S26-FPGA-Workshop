module second_order_bpf #(
    parameter int WIDTH = 16,

    // coefficients scaled by 2^14
    parameter logic signed [15:0] B0 = 16'sd16384,
    parameter logic signed [15:0] B1 = 16'sd0,
    parameter logic signed [15:0] B2 = -16'sd16384,
    parameter logic signed [15:0] A1 = 16'sd0,
    parameter logic signed [15:0] A2 = 16'sd0
)(
    input  logic clk,
    input  logic reset,
    input  logic signed [WIDTH-1:0] x,
    output logic signed [WIDTH-1:0] y
);

    logic signed [WIDTH-1:0] x1, x2;
    logic signed [WIDTH-1:0] y1, y2;

    logic signed [WIDTH + 16-1:0] prod_b0, prod_b1, prod_b2;
    logic signed [WIDTH + 16-1:0] prod_a1, prod_a2;
    logic signed [WIDTH + 19-1:0]  y_raw;
    logic signed [WIDTH-1:0]  y_next;

    // direct form I: y[n] = (b0 * x[0]) + (b1 * x[1]) + (b2 * x[2]) - (a1 * x[1])- (a2 * x[2])
    always_comb begin
        prod_b0 = x  * B0;
        prod_b1 = x1 * B1;
        prod_b2 = x2 * B2;
        prod_a1 = y1 * A1;
        prod_a2 = y2 * A2;

        y_raw = prod_b0 + prod_b1 + prod_b2 - prod_a1 - prod_a2;
        y_next = y_raw >>> 14;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            x1 <= '0;
            x2 <= '0;
            y1 <= '0;
            y2 <= '0;
            y  <= '0;
        end else begin
            y <= y_next;
            x2 <= x1;
            x1 <= x;
            y2 <= y1;
            y1 <= y_next;
        end
    end

endmodule