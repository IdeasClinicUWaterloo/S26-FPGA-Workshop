
// main top module for hdmi on the c5g board with adv7513 transmitter
// reset is moved to the cpu_reset_n pushbutton

`timescale 1 ps / 1 ps

module vocal_effect_top (
    input  wire        clk_50,        // 50 mhz main board clock
    input  wire        cpu_reset_n,   // pushbutton reset, active-low

    // --- ADC Pins (LTC2308) for mic input ---
    output wire        adc_convst,
    output wire        adc_sck,
    output wire        adc_sdi,
    input  wire        adc_sdo,

    // --- I2S DAC Pins ---
    output wire        i2s_bclk,
    output wire        i2s_lrck,
    output wire        i2s_din,
	 
	 inout wire sw0,
	 output wire ledr0
);

    // turn the active-low button into active-high reset
    wire reset = ~cpu_reset_n;
	 assign ledr0 = sw0;
	 
	 // ------------------------------------------------------------------
	 // Live microphone samples via LTC2308 ADC (clk_50 domain)
	 // ------------------------------------------------------------------
	 wire [11:0] raw_mic_data;
	 wire        mic_data_valid;

	 ltc2308_reader adc_inst (
		.clk          (clk_50),
		.rst_n        (cpu_reset_n),
		.measure_start(1'b1),
		.channel      (3'b000),
		.adc_convst   (adc_convst),
		.adc_sck      (adc_sck),
		.adc_sdi      (adc_sdi),
		.adc_sdo      (adc_sdo),
		.data_out     (raw_mic_data),
		.data_valid   (mic_data_valid)
	 );

	 // Convert ADC unsigned 12-bit to signed (remove DC offset, apply gain)
	 // Gain + scaling tuned so signal lives in MSBs of 24-bit sample.
	 wire signed [15:0] formatted_audio16 =
		($signed({4'b0000, raw_mic_data}) - 16'sd1650) <<< 5;
	 // Shift into MSBs so FFT controller (which takes sample[23 -: 16]) sees the signal.
	 wire signed [23:0] formatted_audio24 =
		({{8{formatted_audio16[15]}}, formatted_audio16}) <<< 8;
		
	 // ========================================================
	 // audio processing
	 // ========================================================
	 reg signed [15:0] processed_audio16, filtered_audio16;
	 reg processed_valid, filtered_valid;
	 
	 // LPF to remove the very high frequencies 
	 fourth_order_filter #(
	   .STAGE1_B0(20'sd65536),
      .STAGE1_B1(20'sd131072),
      .STAGE1_B2(20'sd65536),
      .STAGE1_A1(20'sd0),
      .STAGE1_A2(20'sd0),

		.STAGE2_B0(20'sd65536),
		.STAGE2_B1(20'sd131072),
		.STAGE2_B2(20'sd65536),
		.STAGE2_A1(20'sd0),
		.STAGE2_A2(20'sd0)
	 ) lpf(
		 .clk(clk_50),
		 .reset(!cpu_reset_n),
		 
		 .x(formatted_audio16),
		 .x_valid(mic_data_valid),
		 
		 .y(filtered_audio16),
		 .y_valid(filtered_valid)
	);
	
	always_ff @(posedge clk_50 or negedge cpu_reset_n) begin
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
	
	reg signed [15:0] echo_audio16;
	echo u_echo (
		 .clk(bclk),
		 .reset(!cpu_reset_n),
		 .data_in(formatted_audio16),
		 .data_valid(mic_data_valid),
		 .data_out(echo_audio16)
	);
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
		.audio_l(echo_audio16),
		.audio_r(echo_audio16),
		.lrck  (i2s_lrck),
		.sdata (i2s_din)
	 );
endmodule
