module top (
    input CLOCK_50_B5B,
    input CPU_RESET_N, // Assuming this is active low
    output [9:0] LEDR
);

    // Internal Registers
    reg [25:0] ticks;
    reg [10:0] sample_count;
    reg [15:0] sample_arr [0:1023];
    reg [15:0] analog_sample; 
        reg send_data;
    
    // Load values
    initial begin
        $readmemh("cosine_samples.txt", sample_arr);
        send_data = 1'b1; // Initialize to start the process
    end

    always @(posedge CLOCK_50_B5B or negedge CPU_RESET_N) begin
        if (!CPU_RESET_N) begin
            ticks <= 26'd0;
            sample_count <= 11'd0;
            analog_sample <= 16'd0;
        end else if (send_data) begin
            if (ticks >= 26'd50000000) begin
                ticks <= 26'd0;
                if (sample_count < 11'd1024) begin
                    analog_sample <= sample_arr[sample_count];
                    sample_count <= sample_count + 11'd1;
                end
            end else begin
                ticks <= ticks + 26'd1;
            end
        end
    end 

    /*****************************************************************************
    * 										FFT Test                                    *
    *****************************************************************************/
    wire fft_valid;
    wire signed [23:0] fftr, ffti;

    fft_512 u_fft_512 (
        .clk(CLOCK_50_B5B),
        .reset(!CPU_RESET_N),
        .xr_in(analog_sample),
        .xi_in(16'd0), 
        .fft_valid(fft_valid),
        .fftr(fftr),
        .ffti(ffti)
    );
          
    assign LEDR = fftr[23:14];

endmodule