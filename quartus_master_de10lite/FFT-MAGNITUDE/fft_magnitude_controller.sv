module fft_mag_controller #(
    parameter int N = 512,
    parameter int ADDR_WIDTH = 9,  // log2(512) = 9
    parameter int FFT_WIDTH = 24,
    parameter int MAG_WIDTH = 24,
    // Internal FFT datapath width (reduce to save LABs)
    parameter int FFT_DSP_WIDTH = 16
) (
    input logic clk,
    input logic reset,
    input logic clk_pixel,
    input logic noise_capture_start,

    input logic signed [FFT_WIDTH-1:0] sample,
    input logic                        sample_valid,

    input  logic [ADDR_WIDTH-1:0] magnitude_index,
    output logic [ MAG_WIDTH-1:0] magnitude_data
);

  logic [ADDR_WIDTH-1:0] fft_index;
  logic signed [FFT_DSP_WIDTH-1:0] fftr, ffti;
  logic                     fft_valid;

  logic [FFT_DSP_WIDTH-1:0] magnitude_narrow;
  logic [    MAG_WIDTH-1:0] magnitude;
  logic [    MAG_WIDTH-1:0] prev_magnitude;
  logic [    MAG_WIDTH-1:0] magnitude_to_store;

  // instantiate the FFT
  fft_512 #(
      .N(N),
      .log2N(ADDR_WIDTH),
      .SAMPLE_SIZE(FFT_DSP_WIDTH)
  ) u_fft (
      .clk      (clk),
      .reset    (reset),
      // Truncate by keeping MSBs to preserve sign + scale
      .in_sample(sample[FFT_WIDTH-1-:FFT_DSP_WIDTH]),
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
      .i_data   (fftr),
      .q_data   (ffti),
      .magnitude(magnitude_narrow)
  );

  // Zero-extend magnitude into the stored width
  always_comb begin
    magnitude = {MAG_WIDTH{1'b0}};
    magnitude[FFT_DSP_WIDTH-1:0] = magnitude_narrow;
  end

  // ------------------------------------------------------------
  // Bin-by-bin noise floor capture + subtraction (KEY1)
  // ------------------------------------------------------------
  localparam integer N_FRAMES = 4;  // average across 4 FFT frames
  localparam integer AVG_SHIFT = 2;  // divide by 4 (2^2)
  localparam integer FRAME_BITS = 2;  // log2(4) = 2
  localparam integer NOISE_SUM_WIDTH = MAG_WIDTH + FRAME_BITS;
  // Renderer only displays bins 0..127 (128 bins)
  localparam integer DISPLAY_BINS = 128;

  logic noise_ready;
  logic capturing;
  logic capture_pending;
  logic [FRAME_BITS-1:0] capture_frame;

  // Per-bin sum of magnitudes during capture.
  // Async read (combinational) is used for subtraction.
  (* ramstyle = "M10K" *) logic [NOISE_SUM_WIDTH-1:0] noise_sum_mem[0:DISPLAY_BINS-1];

  wire [6:0] fft_index_disp = fft_index[6:0];

  // Magnitude minus noise floor (clip at 0).
  always_comb begin
    logic [NOISE_SUM_WIDTH-1:0] noise_floor_sum;
    logic [      MAG_WIDTH-1:0] noise_floor;

    if (noise_ready && (fft_index < DISPLAY_BINS)) begin
      noise_floor_sum = noise_sum_mem[fft_index_disp] >> AVG_SHIFT;
      noise_floor     = noise_floor_sum[MAG_WIDTH-1:0];

      if (magnitude > noise_floor) magnitude_to_store = magnitude - noise_floor;
      else magnitude_to_store = {MAG_WIDTH{1'b0}};
    end else begin
      // During capture, or for bins we don't display: store raw magnitude.
      magnitude_to_store = magnitude;
    end
  end

  // Capture control + per-bin accumulation.
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      capturing       <= 1'b0;
      capture_pending <= 1'b0;
      noise_ready     <= 1'b0;
      capture_frame   <= {FRAME_BITS{1'b0}};
    end else begin
      // Wait to start capture on the next FFT frame boundary (fft_index==0).
      if (noise_capture_start) begin
        noise_ready     <= 1'b0;
        capturing       <= 1'b0;
        capture_pending <= 1'b1;
        capture_frame   <= {FRAME_BITS{1'b0}};
      end

      // Arm capture when we hit bin 0 of the next FFT frame.
      if (capture_pending && fft_valid && (fft_index == 0)) begin
        capturing       <= 1'b1;
        capture_pending <= 1'b0;
        capture_frame   <= {FRAME_BITS{1'b0}};
      end

      // Update per-bin sums while capturing.
      // Also include the first bin0 cycle by using an "effective capturing" condition.
      if (fft_valid && (capturing || (capture_pending && (fft_index == 0)))) begin
        // Only accumulate bins we display (0..127).
        if (fft_index < DISPLAY_BINS) begin
          // First capture frame overwrites; later frames accumulate.
          if (capture_frame == {FRAME_BITS{1'b0}}) begin
            noise_sum_mem[fft_index_disp] <= {{FRAME_BITS{1'b0}}, magnitude};
          end else begin
            noise_sum_mem[fft_index_disp] <= noise_sum_mem[fft_index_disp] + {{FRAME_BITS{1'b0}}, magnitude};
          end
        end

        // End-of-frame at last bin.
        if (fft_index == (N - 1)) begin
          if (capture_frame == (N_FRAMES - 1)) begin
            capturing   <= 1'b0;
            noise_ready <= 1'b1;
          end else begin
            capture_frame <= capture_frame + 1'b1;
          end
        end
      end
    end
  end

  // store magnitude in RAM
  mag_ram u_ram (
      .clock_a(clk),
      .clock_b(clk_pixel),

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
