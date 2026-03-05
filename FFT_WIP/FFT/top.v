module top (
    input  wire        CLOCK_50_B5B,
    input  wire        CPU_RESET_N,   // active-low
    output wire [9:0]  LEDR
);

    /*****************************************************************************
    *                             Sample playback
    *****************************************************************************/
    reg [10:0] sample_count;
    (* ramstyle = "M10K" *) reg [15:0] sample_arr [0:1023];
    reg [15:0] analog_sample;

    initial begin
        $readmemh("test_samples_sine.txt", sample_arr);
    end

    always @(posedge CLOCK_50_B5B or negedge CPU_RESET_N) begin
        if (!CPU_RESET_N) begin
            sample_count  <= 11'd0;
            analog_sample <= 16'd0;
        end else begin
            analog_sample <= sample_arr[sample_count];

            if (sample_count == 11'd1023)
                sample_count <= 11'd0;
            else
                sample_count <= sample_count + 11'd1;
        end
    end

    /*****************************************************************************
    *                                 FFT
    *****************************************************************************/
    wire              fft_valid;
    wire signed [23:0] fftr, ffti;

    fft_512 u_fft_512 (
        .clk       (CLOCK_50_B5B),
        .reset     (!CPU_RESET_N),
        .xr_in     (analog_sample),
        .fft_valid (fft_valid),
        .fftr      (fftr),
        .ffti      (ffti)
    );

    /*****************************************************************************
    *                          LED debug / display
    *  - LED9 turns on once we ever see fft_valid (proves FFT is running)
    *  - LED[8:0] show a scaled |fftr| when fft_valid is high
    *****************************************************************************/
    reg        seen_valid;
    reg [9:0]  led_disp;

    wire [23:0] abs_fftr = fftr[23] ? (~fftr + 24'd1) : fftr;

    always @(posedge CLOCK_50_B5B or negedge CPU_RESET_N) begin
        if (!CPU_RESET_N) begin
            seen_valid <= 1'b0;
            led_disp   <= 10'd0;
        end else begin
            if (fft_valid)
                seen_valid <= 1'b1;

            if (fft_valid) begin
                // Take upper bits so small values still show changes on LEDs
                led_disp[8:0] <= abs_fftr[23:15]; // 9 bits
                led_disp[9]   <= seen_valid;      // keep LED9 as "seen fft_valid"
            end else begin
                // Keep LED9 latched even when fft_valid is low
                led_disp[9] <= seen_valid;
            end
        end
    end

    assign LEDR = led_disp;

endmodule