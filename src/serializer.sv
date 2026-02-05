// -----------------------------------------------------------------------------
// 16-bit I2S SERIALIZER (SSM2603-style I2S)
//
// Drives 'dat' with MSB-first, I2S 1-bit delay after LRCLK edge.
// You MUST provide:
//   - left_start / right_start : 1-cycle pulses at LRCLK edges (in BCLK domain)
//   - l_gate / r_gate          : level gates (true during that channel time)
//
// -----------------------------------------------------------------------------
module serializer(
    input  wire        reset,
    input  wire        lrclk,      // 0=left, 1=right
    input  wire        bclk,
    input  wire [15:0] l_data_in,
    input  wire [15:0] r_data_in,

    output reg         dat,
    output wire        data_sent   // pulses when both L and R words have been sent
);

    // Channel gates (level)
    wire l_gate = ~lrclk;
    wire r_gate =  lrclk;

    // --- Synchronize LRCLK into BCLK domain + edge detect ---
    reg lrclk_d;
    always @(negedge bclk or posedge reset) begin
        if (reset) lrclk_d <= 1'b0;
        else       lrclk_d <= lrclk;
    end

    wire lrclk_edge  = lrclk ^ lrclk_d;
    wire left_start  = lrclk_edge & ~lrclk; // entering left word (lrclk became 0)
    wire right_start = lrclk_edge &  lrclk; // entering right word (lrclk became 1)

    // --- One serializer per channel ---
    wire l_dat, r_dat;
    wire l_done, r_done;

    bit_serializer_16 u_l_ser (
        .reset      (reset),
        .bclk       (bclk),
        .gate       (l_gate),
        .start_word (left_start),
        .data_in    (l_data_in),
        .dat_out    (l_dat),
        .word_done  (l_done)
    );

    bit_serializer_16 u_r_ser (
        .reset      (reset),
        .bclk       (bclk),
        .gate       (r_gate),
        .start_word (right_start),
        .data_in    (r_data_in),
        .dat_out    (r_dat),
        .word_done  (r_done)
    );

    // Select which channel drives DAT based on LRCLK
    always @(*) begin
        dat = (lrclk) ? r_dat : l_dat;
    end

    assign data_sent = l_done & r_done; // once per stereo frame (pulse)

endmodule


// -----------------------------------------------------------------------------
// bit_serializer_16
// - Loads new word at start_word
// - Skips 1 BCLK (I2S requirement)
// - Shifts out 16 bits MSB-first while gate=1
// - Pulses word_done for 1 BCLK edge at completion
// -----------------------------------------------------------------------------
module bit_serializer_16(
    input  wire        reset,
    input  wire        bclk,
    input  wire        gate,        // high during this channel slot (lrclk match)
    input  wire        start_word,   // 1-cycle pulse at channel boundary (BCLK domain)
    input  wire [15:0] data_in,

    output reg         dat_out,
    output reg         word_done
);

    reg [15:0] shreg;
    reg [4:0]  cnt;
    reg        skip;

    always @(negedge bclk or posedge reset) begin
        if (reset) begin
            dat_out  <= 1'b0;
            word_done<= 1'b0;
            shreg    <= 16'd0;
            cnt      <= 5'd0;
            skip     <= 1'b0;
        end else begin
            word_done <= 1'b0; // default pulse low

            // New word boundary for this channel
            if (start_word) begin
                shreg   <= data_in;
                cnt     <= 5'd0;
                skip    <= 1'b1;   // I2S 1-bit delay
                dat_out <= 1'b0;
            end else if (!gate) begin
                // outside this channel: hold safe
                dat_out <= 1'b0;
                cnt     <= 5'd0;
                skip    <= 1'b0;
            end else begin
                // gate=1: send bits
                if (skip) begin
                    skip    <= 1'b0; // consume delay bit
                    dat_out <= 1'b0;
                end else begin
                    dat_out <= shreg[15];            // MSB first
                    shreg   <= {shreg[14:0], 1'b0};  // shift left
                    cnt     <= cnt + 5'd1;

                    if (cnt == 5'd15) begin
                        word_done <= 1'b1;           // 16 bits sent
                    end
                end
            end
        end
    end

endmodule
