module top_audio_passthrough (
    input  logic clk_50m,      // 50 MHz Cyclone V Master Clock
    input  logic rst_n,        // Active-low reset button

    // --- ADC Pins (LTC2308) ---
    output logic adc_convst,
    output logic adc_sck,
    output logic adc_sdi,
    input  logic adc_sdo,

    // --- I2S DAC Pins ---
    output logic i2s_bclk,     // Bit Clock
    output logic i2s_lrck,     // Word Select (Left/Right)
    output logic i2s_din,       // Serial Data In
	 
	 // --- SWITCHES ---
	 input logic [9:0] sw
);

    // ========================================================
    // 1. CLOCK GENERATION (50MHz -> 3.125MHz BCLK)
    // ========================================================
    logic [3:0] clk_div;
    logic bclk;
    
    always_ff @(posedge clk_50m or negedge rst_n) begin
        if (!rst_n) begin
            clk_div <= 4'd0;
        end else begin
            clk_div <= clk_div + 1'b1;
        end
    end
    
    // The 4th bit of the counter divides the clock by 16
    assign bclk = clk_div[3]; 
    assign i2s_bclk = bclk;

    // ========================================================
    // 2. ADC CONTROLLER INSTANTIATION
    // ========================================================
    logic [11:0] raw_mic_data;
    logic        mic_data_valid;

    // Pulling the raw 0-4095 unsigned data from the hardware
    ltc2308_reader adc_inst (
        .clk(clk_50m),
        .rst_n(rst_n),
        .measure_start(1'b1),
        .channel(3'b000),          // Assuming Mic is on ADC0
        .adc_sdo(adc_sdo),
        .adc_convst(adc_convst),
        .adc_sck(adc_sck),
        .adc_sdi(adc_sdi),
        .data_out(raw_mic_data),
        .data_valid(mic_data_valid)
    );

    // ========================================================
    // 3. DSP: TRUE DC OFFSET REMOVAL & DIGITAL GAIN
    // ========================================================
    logic signed [15:0] formatted_audio;
    
    // 1. Cast the unsigned 12-bit data to a 16-bit signed space using $signed().
    // 2. Subtract the 1.65V resting baseline (~1650) to perfectly center silence at 0V.
    // 3. Shift left by 5 (<<< 5) to pad the 16-bit frame for the I2S DAC AND 
    //    multiply the volume to boost your 400mV peak-to-peak signal.
    
    assign formatted_audio = ($signed({4'b0000, raw_mic_data}) - 16'sd1650) <<< 5;
	 
	 // ========================================================
    // 4. AUDIO EFFECTS
    // ========================================================

    logic signed [15:0] echo_audio;
    logic signed [15:0] filter_audio;
    logic signed [15:0] mod_audio;
    logic signed [15:0] processed_audio;

    echo u_echo (
        .clk(clk_50m),
        .reset(!rst_n),
        .sample(formatted_audio),
        .sample_valid(mic_data_valid),
        .sample_out(echo_audio)
    );

    fourth_order_lpf u_filter (
        .clk(clk_50m),
        .reset(!rst_n),
        .data_in(formatted_audio),
        .data_valid(mic_data_valid),
        .data_out(filter_audio)
    );

    modulation amp_mod (
        .clk(clk_50m),
        .reset(!rst_n),
        .data_in(formatted_audio),
        .data_valid(mic_data_valid),
        .data_out(mod_audio)
    );
	 
	 
	assign processed_audio = echo_audio;


    // ========================================================
    // 5. I2S TRANSMITTER INSTANTIATION
    // ========================================================
    i2s_tx i2s_out (
        .rst_n(rst_n),
        .bclk(bclk),
        .audio_l(processed_audio),  // Send DSP audio to Left Ear
        .audio_r(processed_audio),  // Send DSP audio to Right Ear
        .lrck(i2s_lrck),
        .sdata(i2s_din)
    );

endmodule