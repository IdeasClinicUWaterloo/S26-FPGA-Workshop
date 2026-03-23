
// main top module for hdmi on the c5g board with adv7513 transmitter
// reset is moved to the cpu_reset_n pushbutton

`timescale 1 ps / 1 ps

module hdmi_top (
    input  wire        clk_50,        // 50 mhz main board clock
    input  wire        cpu_reset_n,   // pushbutton reset, active-low
    input  wire        key1_n,        // pushbutton KEY1, active-low (debounced)

    // --- ADC Pins (LTC2308) for mic input ---
    output wire        adc_convst,
    output wire        adc_sck,
    output wire        adc_sdi,
    input  wire        adc_sdo,

    // --- I2S DAC Pins ---
    output wire        i2s_bclk,
    output wire        i2s_lrck,
    output wire        i2s_din,

    output wire [23:0] hdmi_tx_d,     // rgb pixel data
    output wire        hdmi_tx_de,    // data enable
    output wire        hdmi_tx_hs,    // horizontal sync
    output wire        hdmi_tx_vs,    // vertical sync
    output wire        hdmi_tx_clk,   // pixel clock

    inout  wire        i2c_sda,       // i2c data for adv7513
    output wire        i2c_scl,        // i2c clock for adv7513
	 
	 // --- Filter ---
	 inout wire sw0,
	 output wire ledr0
);

    // turn the active-low button into active-high reset
    wire reset = ~cpu_reset_n;

    // pll to turn the 50 mhz input into 74.25 mhz for 720p video
    wire clk_pixel, pll_locked;
    pll_74mhz pll_inst (
        .refclk   (clk_50),
        .rst      (reset),
        .outclk_0 (clk_pixel),
        .locked   (pll_locked)
    );

    // video timing generator for 1280x720 at 60hz
    wire [11:0] hcount, vcount;
    wire        hsync, vsync, de, frame_start;
	 
	 wire [8:0]  bin_idx;
	 wire [23:0] bin_read;
	 
    video_timing timing_inst (
        .clk         (clk_pixel),
        .reset       (~pll_locked), // hold in reset until pll is locked
        .hcount      (hcount),      // current horizontal pixel position
        .vcount      (vcount),      // current vertical line position
        .hsync       (hsync),       // hsync signal
        .vsync       (vsync),       // vsync signal
        .de          (de),          // data enable signal
        .frame_start (frame_start)  // pulse at start of each frame
    );

    // renderer turns bin magnitude into rgb pixels
    renderer draw (  
		  .clk      (clk_pixel),
        .hcount   (hcount),
        .vcount   (vcount),
        .de       (de),
        .rgb      (hdmi_tx_d), // output rgb pixels
		  .bin_idx  (bin_idx),
		  // ~1/3 of previous height (cheap shift-add): 3/256 * bin_read
		  // Retuned for 512-point FFT so bars reach multiple color bands.
		  .bin_magnitude_raw ((bin_read >> 6) + (bin_read >> 7))
    );

    // connect sync/data signals directly to hdmi outputs
    assign hdmi_tx_de  = de;
    assign hdmi_tx_hs  = hsync;
    assign hdmi_tx_vs  = vsync;
    assign hdmi_tx_clk = clk_pixel;

    // configure the adv7513 transmitter over i2c
    i2c_config config_inst (
        .clk   (clk_pixel),
        .reset (~pll_locked | reset),
        .scl   (i2c_scl),
        .sda   (i2c_sda)
    );
	 
	 fft_mag_controller fft_mag (
		.clk(clk_50),
      .reset(~pll_locked | reset),
		.clk_pixel(clk_pixel),
		.noise_capture_start(noise_capture_start),
	 
		.sample(fft_sample),
		.sample_valid(sample_valid),
	 
		.magnitude_index(bin_idx),
		.magnitude_data(bin_read)

	 );
	 
	 // ------------------------------------------------------------------
	 // Live microphone samples via LTC2308 ADC (clk_50 domain)
	 // ------------------------------------------------------------------
	 wire [11:0] raw_mic_data;
	 wire        mic_data_valid;
	 reg  signed [23:0] fft_sample;
	 reg         sample_valid;
	 reg         adc_measure_start;

	 ltc2308_reader adc_inst (
		.clk          (clk_50),
		.rst_n        (cpu_reset_n),
		.measure_start(adc_measure_start),
		.channel      (3'b000),
		.adc_convst   (adc_convst),
		.adc_sck      (adc_sck),
		.adc_sdi      (adc_sdi),
		.adc_sdo      (adc_sdo),
		.data_out     (raw_mic_data),
		.data_valid   (mic_data_valid)
	 );
	 
	 // ========================================================
	 // AUDIO PROCESSING
	 // 
	 // ========================================================
	 
	 assign ledr0 = sw0;

	 // Convert ADC unsigned 12-bit to signed (remove DC offset, apply gain)
	 // Gain + scaling tuned so signal lives in MSBs of 24-bit sample.
	 wire signed [15:0] formatted_audio16 =
		($signed({4'b0000, raw_mic_data}) - 16'sd1650) <<< 5;
	 reg signed [15:0] processed_audio16; 
	 wire signed [15:0] filtered_audio16;
	 reg processed_valid;
	 wire filtered_valid;
		
	// LPF to remove the very high frequencies 
	 fourth_order_filter #(
		.STAGE1_B0(20'sd8321),
		.STAGE1_B1(20'sd16643),
		.STAGE1_B2(20'sd8321),
		.STAGE1_A1(-20'sd382754),
		.STAGE1_A2(20'sd155866),
		.STAGE2_B0(20'sd262144),
		.STAGE2_B1(-20'sd524288),
		.STAGE2_B2(20'sd262144),
		.STAGE2_A1(-20'sd510157),
		.STAGE2_A2(20'sd248470)
	 ) lpf(
		 .clk(clk_50),
		 .reset(!cpu_reset_n),
		 
		 .x(formatted_audio16),
		 .x_valid(mic_data_valid),
		 
		 .y(filtered_audio16),
		 .y_valid(filtered_valid)
	);
	
	always @(posedge clk_50 or negedge cpu_reset_n) begin
			 if (!cpu_reset_n) begin
				  processed_audio16 <= 16'sd0;
				  processed_valid   <= 1'b0;
			 end else begin
				  if (sw0) begin
						processed_audio16 <= filtered_audio16;
						processed_valid   <= filtered_valid;
				  end else begin
						processed_audio16 <= formatted_audio16;
						processed_valid   <= mic_data_valid;
				  end
			 end
		end

	 
	 // Shift into MSBs so FFT controller (which takes sample[23 -: 16]) sees the signal.
	 wire signed [23:0] formatted_audio24 =
		({{8{processed_audio16[15]}}, processed_audio16}) <<< 8;
	

	 // ========================================================
	 // I2S DAC output (runs in parallel with FFT+HDMI)
	 // 50MHz -> ~3.125MHz BCLK (divide by 16)
	 // ========================================================
	 reg [3:0] clk_div;
	 wire bclk = clk_div[3];
	 assign i2s_bclk = bclk;

	 always @(posedge clk_50 or negedge cpu_reset_n) begin
		if (!cpu_reset_n) begin
			clk_div <= 4'd0;
		end else begin
			clk_div <= clk_div + 4'd1;
		end
	 end

	 i2s_tx i2s_out (
		.rst_n (cpu_reset_n),
		.bclk  (bclk),
		.audio_l(processed_audio16),
		.audio_r(processed_audio16),
		.lrck  (i2s_lrck),
		.sdata (i2s_din)
	 );

	 // Sample rate control:
	 // - Pulse `measure_start` at ~48.1 kHz to make ADC conversions deterministic
	 // - Forward `mic_data_valid` to the FFT as the actual `sample_valid` strobe
	 localparam integer AUDIO_DIV = 1039; // 50e6 / 1039 ≈ 48.1 kHz
	 reg [15:0] audio_cnt;

	 // KEY1 noise profile capture trigger (generated as a 1-cycle pulse)
	 reg        noise_capture_start;
	 reg        key1_n_prev;

	 always @(posedge clk_50 or posedge reset) begin
	    if (reset) begin
			audio_cnt        <= 16'd0;
			adc_measure_start<= 1'b0;
			sample_valid     <= 1'b0;
			fft_sample       <= 24'sd0;
			key1_n_prev      <= 1'b1;
		 noise_capture_start <= 1'b0;
		 end else begin
			// default: 1-cycle pulse
			noise_capture_start <= 1'b0;

			// Detect KEY1 press edge (active-low input)
			key1_n_prev <= key1_n;
			if (key1_n_prev && !key1_n) begin
				noise_capture_start <= 1'b1;
			end

			// default: single-cycle conversion request pulse
			adc_measure_start <= 1'b0;

			// generate ADC conversion request
			if (audio_cnt == AUDIO_DIV-1) begin
				audio_cnt         <= 16'd0;
				adc_measure_start <= 1'b1;
			end else begin
				audio_cnt <= audio_cnt + 16'd1;
			end

			// when ADC reports a sample is ready, send it to FFT
			if (processed_valid) begin
				fft_sample <= formatted_audio24;

				sample_valid <= 1'b1;
			end else begin
				sample_valid <= 1'b0;
			end
		 end
	 end
endmodule
