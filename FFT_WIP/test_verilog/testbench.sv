`timescale 1ns/1ps

module fft_512_tb;

    // Parameters
    localparam N = 512;
    localparam CLK_PERIOD = 10; 
    localparam real PI = 3.141592653589;

    // DUT Signals
    reg clk;
    reg reset;
    reg signed [23:0] xr_in, xi_in;
    wire fft_valid;
    wire signed [23:0] fftr, ffti;

    // Testbench internal variables
    integer i;
    real amplitude = 100.0; 
    real cycles = 10.0;      // We want a peak at Index 10

    // Instantiate the FFT Module
    fft_512 dut (
        .clk(clk),
        .reset(reset),
        .xr_in(xr_in),
        .xi_in(xi_in),
        .fft_valid(fft_valid),
        .fftr(fftr),
        .ffti(ffti)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Main Test Sequence
    initial begin
        // Initialize
        reset = 1;
        xr_in = 17'sd0;
        xi_in = 17'sd0;
        
        // Hold reset
        repeat(10) @(posedge clk);
        reset = 0;
        @(posedge clk);

        // --- STEP 1: LOAD PHASE ---
        $display("Status: Loading 10-cycle sine wave into FFT...");
        for (i = 0; i < N; i = i + 1) begin
            // Generate sine wave: A * sin(2 * pi * f * n / N)
            xr_in <= $rtoi(amplitude * $sin(2.0 * PI * cycles * i / N));
            xi_in <= 17'sd0; 
            @(posedge clk);
        end
        
        // Clear inputs after loading
        xr_in <= 17'sd0;
        xi_in <= 17'sd0;
        $display("Status: Load complete. Processing...");

        // --- STEP 2: CALCULATION PHASE ---
        // Wait for the module to finish computing
        wait(fft_valid == 1'b1);
        $display("Status: FFT Valid! Resulting Bins:");
        $display("---------------------------------------");

        // --- STEP 3: OUTPUT PHASE ---
        for (i = 0; i < N; i = i + 1) begin
            // In a 512-point FFT with 10 cycles, 
            // the peaks will be at Bin 10 and Bin 502 (N - 10)
            $display("Bin %4d | Real: %d | Imag: %d", i, fftr, ffti);
            @(posedge clk);
        end

        $display("---------------------------------------");
        $display("Simulation Finished.");
        $finish;
    end

    // Waveform Dump for GTKWave or Vivado
    initial begin
        $dumpfile("fft_512_test.vcd");
        $dumpvars(0, fft_512_tb);
    end

endmodule