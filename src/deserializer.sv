module deserializer(
    input  wire        reset,
    input  wire        lrclk,      // 0 = left, 1 = right
    input  wire        bclk,
    input  wire        dat,

    output wire [15:0] l_data,
    output wire [15:0] r_data,
    output wire        data_valid
);

    // Gate signals (level)
    wire l_gate = ~lrclk;
    wire r_gate =  lrclk;

    // Synchronize LRCLK into BCLK domain
    reg lrclk_d;
    always @(negedge bclk or posedge reset) begin
        if (reset)
            lrclk_d <= 1'b0;
        else
            lrclk_d <= lrclk;
    end

    wire l_valid, r_valid;

    bit_counter_deserial l_bit_counter(
        .reset       (reset),
        .bclk        (bclk),
        .dat         (dat),
        .start_read  (l_gate),
        .data        (l_data),
        .data_valid  (l_valid)
    );

    bit_counter_deserial r_bit_counter(
        .reset       (reset),
        .bclk        (bclk),
        .dat         (dat),
        .start_read  (r_gate),
        .data        (r_data),
        .data_valid  (r_valid)
    );

    assign data_valid = l_valid & r_valid;

endmodule
