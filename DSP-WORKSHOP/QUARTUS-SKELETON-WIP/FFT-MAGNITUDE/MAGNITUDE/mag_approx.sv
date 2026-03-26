
// formula: M≈α∗max(|I|,|Q|)+β∗min(|I|,|Q|)

module magnitude_approx #(
    parameter WIDTH = 24
)(
    input  logic signed [WIDTH-1:0] i_data, // Real (I)
    input  logic signed [WIDTH-1:0] q_data, // Imag (Q)
    output logic [WIDTH-1:0]        magnitude
);

    logic [WIDTH-1:0] abs_i, abs_q;
    logic [WIDTH-1:0] max_val, min_val;

    always_comb begin
        // get abs Values
        abs_i = (i_data[WIDTH-1]) ? -i_data : i_data;
        abs_q = (q_data[WIDTH-1]) ? -q_data : q_data;

        // determine max and min
        if (abs_i > abs_q) begin
            max_val = abs_i;
            min_val = abs_q;
        end else begin
            max_val = abs_q;
            min_val = abs_i;
        end

        // Alpha-Beta Calculation: Max + (Min >> 2)
        // This approximates Alpha=1, Beta=0.25
        magnitude = max_val + (min_val >> 2);
    end

endmodule