module fft_mag_controller #(
    parameter int N = 512,
	 parameter int ADDR_WIDTH = 9, // log2(512) = 9
    parameter int FFT_WIDTH  = 24,
    parameter int MAG_WIDTH  = 24,
    // Internal FFT datapath width (reduce to save LABs)
    parameter int FFT_DSP_WIDTH = 16
) (
    input  logic                 			clk,
    input  logic                 			reset,
    input  logic 									clk_pixel,
	 
	 input  logic signed [FFT_WIDTH-1:0]	sample,
	 input  logic 									sample_valid,
	 
	 input  logic [ADDR_WIDTH-1:0]			magnitude_index,
    output logic [MAG_WIDTH-1:0] 			magnitude_data
);

  logic [ADDR_WIDTH-1:0]       fft_index;
  logic signed [FFT_DSP_WIDTH-1:0] fftr, ffti;
  logic                   fft_valid;

  logic [FFT_DSP_WIDTH-1:0] magnitude_narrow;
  logic [MAG_WIDTH-1:0]     magnitude;
  logic [MAG_WIDTH-1:0]     prev_magnitude;
  logic [MAG_WIDTH-1:0]     magnitude_to_store;

  // instantiate the FFT
  fft_512 #(
      .N(N),
      .log2N(ADDR_WIDTH),
      .SAMPLE_SIZE(FFT_DSP_WIDTH)
  ) u_fft (
      .clk      (clk),
      .reset    (reset),
      // Truncate by keeping MSBs to preserve sign + scale
      .in_sample(sample[FFT_WIDTH-1 -: FFT_DSP_WIDTH]),
      .in_valid (sample_valid),
      .out_index(fft_index),
      .out_fftr (fftr),
      .out_ffti (ffti),
      .out_valid(fft_valid)
  );

  // magnitude logic
  magnitude_approx #(
      .WIDTH(FFT_DSP_WIDTH)
  ) u_mag (
      .i_data    (fftr),
      .q_data    (ffti),
      .magnitude (magnitude_narrow)
  );

  // Zero-extend magnitude into the stored width
  always_comb begin
    magnitude = {MAG_WIDTH{1'b0}};
    magnitude[FFT_DSP_WIDTH-1:0] = magnitude_narrow;
  end

  // One-frame smoothing: store average of previous and current magnitudes.
  // This reduces flicker without long-term smearing.
  always_comb begin
    magnitude_to_store = (prev_magnitude + magnitude) >> 1;
  end

  // store magnitude in RAM
  mag_ram u_ram (
      .clock_a    (clk),
      .clock_b    (clk_pixel),

      // write only on Port A
      .address_a(fft_index),
      .data_a   (magnitude_to_store),
      .wren_a   (fft_valid),
      .q_a      (prev_magnitude),

      // read only on Port B
      .address_b(magnitude_index),
      .data_b   ({MAG_WIDTH{1'b0}}),
      .wren_b   (1'b0),
      .q_b      (magnitude_data)
  );

endmodule