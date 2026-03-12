
// main top module for hdmi on the c5g board with adv7513 transmitter
// reset is moved to the cpu_reset_n pushbutton

`timescale 1 ps / 1 ps

module hdmi_top (
    input  wire        clk_50,        // 50 mhz main board clock
    input  wire        cpu_reset_n,   // pushbutton reset, active-low

    output wire [23:0] hdmi_tx_d,     // rgb pixel data
    output wire        hdmi_tx_de,    // data enable
    output wire        hdmi_tx_hs,    // horizontal sync
    output wire        hdmi_tx_vs,    // vertical sync
    output wire        hdmi_tx_clk,   // pixel clock

    inout  wire        i2c_sda,       // i2c data for adv7513
    output wire        i2c_scl        // i2c clock for adv7513
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
	 
	 wire [8:0] bin_idx;
	 wire [15:0] bin_read;
	 
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
		  .bin_magnitude_raw (bin_read >> 6) // scale input data
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
	 
		.sample(fft_sample),
		.sample_valid(sample_valid),
	 
		.magnitude_index(bin_idx),
		.magnitude_data(bin_read)

	 );
	 
	 // send samples to fft
	 reg [8:0] sample_addr_reg;
	 wire [8:0]  sample_addr;
	 wire signed [15:0] cos_sample_raw;
	 wire signed [23:0] fft_sample;
	 reg sample_valid;
	 
	 always @(posedge clk_50 or posedge reset) begin
	    if(reset) begin
			sample_addr_reg <= 9'd0;
			sample_valid    <= 1'b0;
		 end else if (sample_addr_reg < 512) begin
		 	  sample_addr_reg <= sample_addr_reg + 9'd1;
			  sample_valid <= 1'b1;
		 end else begin
			  sample_valid <= 1'b0;
		 end
	 end

	 assign sample_addr = sample_addr_reg;
	 assign fft_sample = {{8{cos_sample_raw[15]}}, cos_sample_raw};
	 
	 //tmp digital samples of cosine wave
	 cos_samples_rom cos(
		.clock (clk_50),
		.address(sample_addr),
		.q(cos_sample_raw)
	 );
endmodule
