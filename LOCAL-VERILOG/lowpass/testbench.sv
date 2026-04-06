`timescale 1ns/1ps

module tb_filter_to_fft;

    localparam int N           = 512;
    localparam int LOG2N       = 9;
    localparam int SAMPLE_SIZE = 24;

    logic clk;
    logic reset;

    // filter I/O
    logic signed [SAMPLE_SIZE-1:0] data_in;
    logic signed [SAMPLE_SIZE-1:0] data_out;
    logic sample_valid;

    // FFT input-side signals
    logic signed [SAMPLE_SIZE-1:0] in_sample_raw;
    logic                          in_valid_raw;
    logic [LOG2N-1:0]              out_index_raw;
    logic signed [SAMPLE_SIZE-1:0] out_fftr_raw;
    logic signed [SAMPLE_SIZE-1:0] out_ffti_raw;
    logic                          out_valid_raw;

    // FFT output-side signals
    logic signed [SAMPLE_SIZE-1:0] in_sample_filt;
    logic                          in_valid_filt;
    logic [LOG2N-1:0]              out_index_filt;
    logic signed [SAMPLE_SIZE-1:0] out_fftr_filt;
    logic signed [SAMPLE_SIZE-1:0] out_ffti_filt;
    logic                          out_valid_filt;

    integer i;
    real fs;
    real bin_hz;
    real t;
    real value;

    // exact-bin test tones
    real f1, f2, f3;

    // -------------------------
    // DUT: 4th-order lpf
    // -------------------------
    fourth_order_lpf #(
        .SAMPLE_WIDTH(SAMPLE_SIZE)
    ) lpf (
        .clk(clk),
        .reset(reset),
        .data_valid(1'b1),
        .data_in(data_in),
        .data_out(data_out)
    );

    // -------------------------
    // Feed raw input directly to FFT #1
    // -------------------------
    assign in_sample_raw = data_in;
    assign in_valid_raw  = sample_valid;

    // -------------------------
    // Feed filtered output directly to FFT #2
    // -------------------------
    assign in_sample_filt = data_out;
    assign in_valid_filt  = sample_valid;

    // -------------------------
    // FFT of FILTER INPUT
    // -------------------------
    fft_512 #(
        .N(N),
        .log2N(LOG2N),
        .SAMPLE_SIZE(SAMPLE_SIZE)
    ) fft_raw (
        .clk(clk),
        .reset(reset),
        .in_sample(in_sample_raw),
        .in_valid(in_valid_raw),
        .out_index(out_index_raw),
        .out_fftr(out_fftr_raw),
        .out_ffti(out_ffti_raw),
        .out_valid(out_valid_raw)
    );

    // -------------------------
    // FFT of FILTER OUTPUT
    // -------------------------
    fft_512 #(
        .N(N),
        .log2N(LOG2N),
        .SAMPLE_SIZE(SAMPLE_SIZE)
    ) fft_filt (
        .clk(clk),
        .reset(reset),
        .in_sample(in_sample_filt),
        .in_valid(in_valid_filt),
        .out_index(out_index_filt),
        .out_fftr(out_fftr_filt),
        .out_ffti(out_ffti_filt),
        .out_valid(out_valid_filt)
    );

    // -------------------------
    // Clock
    // -------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // -------------------------
    // Stimulus
    // -------------------------
    initial begin
        fs        = 44000.0;
        bin_hz    = fs / N;     // 85.9375 Hz/bin

        // choose exact FFT bins:
        // bin 2  = 171.875 Hz   (inside passband)
        // bin 12 = 1031.25 Hz   (close to cutoff)
        // bin 46 = 3953.125 Hz  (above passband)
        f1 = 2.0  * bin_hz;
        f2 = 9.0 * bin_hz;
        f3 = 24.0 * bin_hz;

        reset        = 1;
        data_in      = '0;
        sample_valid = 0;

        repeat (4) @(posedge clk);
        reset = 0;

        @(posedge clk);
        sample_valid = 1;

        for (i = 0; i < N; i = i + 1) begin
            @(posedge clk);
            t = i / fs;

            // equal-amplitude 3-tone signal
            value =
                $sin(2.0 * 3.141592653589793 * f1 * t) +
                $sin(2.0 * 3.141592653589793 * f2 * t) +
                $sin(2.0 * 3.141592653589793 * f3 * t);

            data_in <= $rtoi(value * 8000.0);
        end

        @(posedge clk);
        sample_valid <= 0;
        data_in      <= '0;

        // give FFTs time to finish
        repeat (20000) @(posedge clk);
        $finish;
    end

    // -------------------------
    // Print raw FFT
    // -------------------------
    always @(posedge clk) begin
        if (out_valid_raw) begin
            $display("RAW  FFT bin %0d : Re=%0d Im=%0d",
                     out_index_raw, out_fftr_raw, out_ffti_raw);
        end
    end

    // -------------------------
    // Print filtered FFT
    // -------------------------
    always @(posedge clk) begin
        if (out_valid_filt) begin
            $display("FILT FFT bin %0d : Re=%0d Im=%0d",
                     out_index_filt, out_fftr_filt, out_ffti_filt);
        end
    end

endmodule