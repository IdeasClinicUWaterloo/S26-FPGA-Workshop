module top (
    inout logic clk_50,         // 50 mhz main board clock
    inout logic max10_clk1_50,
    input logic cpu_reset_n,    // pushbutton reset, active-low

    // --- I2S DAC Pins ---
    output logic i2s_bclk,
    output logic i2s_lrck,
    output logic i2s_din,

    // --- HDMI signals (rgb and timing) ---
    output logic [3:0] vga_r,
    output logic [3:0] vga_g,
    output logic [3:0] vga_b,
    output logic       vga_hs,  // horizontal sync
    output logic       vga_vs,  // vertical sync

    // user i/o
    input  logic       key1_n,
    output logic [8:0] ledr,
    input  logic [8:0] sw
);

  // turn the active-low button into active-high reset
  logic reset;
  assign reset = ~cpu_reset_n;

  // ------------------------------------------------------------------
  // HDMI display
  // ------------------------------------------------------------------

  // pll to turn the 50 mhz input into 74.25 mhz for 720p video
  logic clk_pixel, pll_locked;
  pll_74mhz u_pll_74mhz (
      .areset(reset),
      .inclk0(clk_50),
      .c0    (clk_pixel),
      .locked(pll_locked)
  );

  // video timing generator for 1280x720 at 60hz
  logic [11:0] hcount, vcount;
  logic hsync, vsync, de, frame_start;
  video_timing timing_inst (
      .clk        (clk_pixel),
      .reset      (reset | ~pll_locked),
      .hcount     (hcount),
      .vcount     (vcount),
      .hsync      (hsync),
      .vsync      (vsync),
      .de         (de),
      .frame_start(frame_start)
  );

  logic [23:0] rgb;

  assign vga_hs = hsync;
  assign vga_vs = vsync;

  always_comb begin
    if (de) begin
      vga_r = rgb[23:20];
      vga_g = rgb[15:12];
      vga_b = rgb[7:4];
    end else begin
      vga_r = 4'b0000;
      vga_g = 4'b0000;
      vga_b = 4'b0000;
    end
  end

  // ------------------------------------------------------------------
  // Live microphone samples via ADC
  // ------------------------------------------------------------------
  logic [11:0] raw_mic_data;
  logic        mic_data_valid;
  logic        sys_clk;

  adc_qsys u0 (
      .clk_clk                             (max10_clk1_50),
      .reset_reset_n                       (1'b1),
      .modular_adc_0_command_valid         (command_valid),
      .modular_adc_0_command_channel       (command_channel),
      .modular_adc_0_command_startofpacket (command_startofpacket),
      .modular_adc_0_command_endofpacket   (command_endofpacket),
      .modular_adc_0_command_ready         (command_ready),
      .modular_adc_0_response_valid        (response_valid),
      .modular_adc_0_response_channel      (response_channel),
      .modular_adc_0_response_data         (response_data),
      .modular_adc_0_response_startofpacket(response_startofpacket),
      .modular_adc_0_response_endofpacket  (response_endofpacket),
      .clock_bridge_sys_out_clk_clk        (sys_clk)
  );

  logic       command_valid;
  logic [4:0] command_channel;
  logic       command_startofpacket;
  logic       command_endofpacket;
  logic       command_ready;

  assign command_startofpacket = 1'b1;
  assign command_endofpacket   = 1'b1;
  assign command_valid         = 1'b1;
  assign command_channel       = 5'd1;

  logic        response_valid;
  logic [ 4:0] response_channel;
  logic [11:0] response_data;
  logic        response_startofpacket;
  logic        response_endofpacket;
  logic [11:0] adc_sample_data;

  always_ff @(posedge sys_clk or posedge reset) begin
    if (reset) begin
      adc_sample_data <= 12'd0;
    end else if (response_valid) begin
      adc_sample_data <= response_data;
    end
  end

  assign raw_mic_data = adc_sample_data;

  // ========================================================
  // Audio formatting
  // ========================================================
  logic signed [15:0] formatted_audioraw16, formatted_audio16;
  logic signed [23:0] formatted_audio24;
  logic               audio_ready;

  // Convert unsigned 12-bit ADC sample to signed centered audio
  audio_processing audio (
      .clk_50(sys_clk),
      .reset(!cpu_reset_n),
      .sw(sw),
      .in_audio(formatted_audioraw16),
      .in_valid(mic_data_valid),
      .out_audio(formatted_audio16),
      .out_ready(audio_ready)
  );

  assign ledr = sw;
  assign formatted_audio24    = {{8{formatted_audio16[15]}}, formatted_audio16};

  // ========================================================
  // I2S DAC output (runs in parallel with FFT+HDMI)
  // 50MHz -> ~3.125MHz BCLK (divide by 16)
  // ========================================================
  logic [3:0] clk_div;
  logic       bclk;

  assign bclk     = clk_div[3];
  assign i2s_bclk = bclk;

  always_ff @(posedge sys_clk or negedge cpu_reset_n) begin
    if (!cpu_reset_n) begin
      clk_div <= 4'd0;
    end else begin
      clk_div <= clk_div + 4'd1;
    end
  end

  i2s_tx i2s_out (
      .rst_n  (cpu_reset_n),
      .bclk   (bclk),
      .audio_l(formatted_audio16),
      .audio_r(formatted_audio16),
      .lrck   (i2s_lrck),
      .sdata  (i2s_din)
  );

  // ============================================================================
  // Sample rate control:
  // - Pulse `measure_start` at ~48.1 kHz to make ADC conversions deterministic
  // - Forward `mic_data_valid` to the FFT as the actual `sample_valid` strobe
  // ============================================================================
  logic adc_measure_start, sample_valid;
  logic [23:0] fft_sample;
  localparam integer AUDIO_DIV = 1039;  // 50e6 / 1039 ≈ 48.1 kHz
  logic [15:0] audio_cnt;

  // KEY1 noise profile capture trigger (generated as a 1-cycle pulse)
  logic noise_capture_start;
  logic key1_n_prev;

  always_ff @(posedge sys_clk or posedge reset) begin
    if (reset) begin
      audio_cnt            <= 16'd0;
      sample_valid         <= 1'b0;
      fft_sample           <= 24'sd0;
      key1_n_prev          <= 1'b1;
      noise_capture_start  <= 1'b0;
      mic_data_valid       <= 1'b0;
      formatted_audioraw16 <= 16'sd0;
    end else begin
      noise_capture_start <= 1'b0;

      key1_n_prev <= key1_n;
      if (key1_n_prev && !key1_n) begin
        noise_capture_start <= 1'b1;
      end

      mic_data_valid <= 1'b0;

      if (audio_cnt == AUDIO_DIV - 1) begin
        audio_cnt            <= 16'd0;
        formatted_audioraw16 <= ($signed({4'b0000, raw_mic_data}) - 16'sd1650) <<< 5;
        mic_data_valid       <= 1'b1;
      end else begin
        audio_cnt <= audio_cnt + 16'd1;
      end

      if (audio_ready) begin
        fft_sample   <= formatted_audio24;
        sample_valid <= 1'b1;
      end else begin
        sample_valid <= 1'b0;
      end
    end
  end

  // ============================================================================
  // FFT display
  // ============================================================================ 
  logic [ 8:0] bin_idx;
  logic [23:0] bin_read;

  fft_mag_controller fft_mag (
      .clk(sys_clk),
      .reset(~pll_locked | reset),
      .clk_pixel(clk_pixel),
      .noise_capture_start(noise_capture_start),

      .sample(fft_sample),
      .sample_valid(sample_valid),

      .magnitude_index(bin_idx),
      .magnitude_data (bin_read)
  );

  // renderer turns bin magnitude into rgb pixels
  renderer draw (
      .clk              (clk_pixel),
      .hcount           (hcount),
      .vcount           (vcount),
      .de               (de),
      .rgb              (rgb),            // output rgb pixels
      .bin_idx          (bin_idx),
      // ~1/3 of previous height (cheap shift-add): 3/256 * bin_read
      // Retuned for 512-point FFT so bars reach multiple color bands.
      .bin_magnitude_raw(bin_read >>> 1)
  );


endmodule
