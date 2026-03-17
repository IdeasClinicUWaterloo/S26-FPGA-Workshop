`timescale 1ns/1ps

module tb_modulation_to_fft;

    localparam int N           = 512;
    localparam int LOG2N       = 9;
    localparam int SAMPLE_SIZE = 24;
    localparam int LUT_SIZE    = 1000;   // make modulation carrier exact-bin

    logic clk;
    logic reset;

    // modulation I/O
    logic signed [SAMPLE_SIZE-1:0] data_in;
    logic signed [SAMPLE_SIZE-1:0] data_out;

    // FFT input-side signals
    logic signed [SAMPLE_SIZE-1:0] in_sample_raw;
    logic                          in_valid_raw;
    logic [LOG2N-1:0]              out_index_raw;
    logic signed [SAMPLE_SIZE-1:0] out_fftr_raw;
    logic signed [SAMPLE_SIZE-1:0] out_ffti_raw;
    logic                          out_valid_raw;

    // FFT output-side signals
    logic signed [SAMPLE_SIZE-1:0] in_sample_mod;
    logic                          in_valid_mod;
    logic [LOG2N-1:0]              out_index_mod;
    logic signed [SAMPLE_SIZE-1:0] out_fftr_mod;
    logic signed [SAMPLE_SIZE-1:0] out_ffti_mod;
    logic                          out_valid_mod;

    integer i;
    real fs;
    real bin_hz;
    real t;
    real value;

    // exact-bin input tone
    real fin;
    real fm;

    // -------------------------
    // DUT: modulation
    // -------------------------
    modulation #(
        .SAMPLE_WIDTH(SAMPLE_SIZE)
    ) mod_inst (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .data_valid(1'b1),
        .data_out(data_out)
    );

    // -------------------------
    // Feed raw input directly to FFT #1
    // -------------------------
    assign in_sample_raw = data_in;

    // -------------------------
    // Feed modulated output directly to FFT #2
    // -------------------------
    assign in_sample_mod = data_out;

    // -------------------------
    // FFT of INPUT
    // -------------------------
    fft_512 #(
        .N(N),
        .log2N(LOG2N),
        .SAMPLE_SIZE(SAMPLE_SIZE)
    ) fft_raw (
        .clk(clk),
        .reset(reset),
        .in_sample(in_sample_raw),
        .in_valid(1'b1),
        .out_index(out_index_raw),
        .out_fftr(out_fftr_raw),
        .out_ffti(out_ffti_raw),
        .out_valid(out_valid_raw)
    );

    // -------------------------
    // FFT of MODULATED OUTPUT
    // -------------------------
    fft_512 #(
        .N(N),
        .log2N(LOG2N),
        .SAMPLE_SIZE(SAMPLE_SIZE)
    ) fft_mod (
        .clk(clk),
        .reset(reset),
        .in_sample(in_sample_mod),
        .in_valid(1'b1),
        .out_index(out_index_mod),
        .out_fftr(out_fftr_mod),
        .out_ffti(out_ffti_mod),
        .out_valid(out_valid_mod)
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
        fs        = 48000.0;
        bin_hz    = fs / N;     // 93.75 Hz/bin

        // input tone at exact bin 20
        fin = 20.0 * bin_hz;    // 1875 Hz

        // modulation carrier from LUT stepping
        fm  = fs / LUT_SIZE;    // 187.5 Hz = bin 2

        reset        = 1;
        data_in      = '0;

        repeat (4) @(posedge clk);
        reset = 0;

        for (i = 0; i < N; i = i + 1) begin
            @(posedge clk);
            t = i / fs;

            // single-tone sine input
            value = $sin(2.0 * 3.141592653589793 * fin * t);

            data_in <= $rtoi(value * 12000.0);
        end

        @(posedge clk);
        data_in      <= '0;

        repeat (20000) @(posedge clk);
        $finish;
    end

    // -------------------------
    // Print raw FFT
    // -------------------------
    always @(posedge clk) begin
        if (out_valid_raw) begin
            $display("RAW FFT bin %0d : Re=%0d Im=%0d",
                     out_index_raw, out_fftr_raw, out_ffti_raw);
        end
    end

    // -------------------------
    // Print modulated FFT
    // -------------------------
    always @(posedge clk) begin
        if (out_valid_mod) begin
            $display("MOD FFT bin %0d : Re=%0d Im=%0d",
                     out_index_mod, out_fftr_mod, out_ffti_mod);
        end
    end

endmodule