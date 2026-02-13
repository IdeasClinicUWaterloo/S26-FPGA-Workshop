module TOP_FILE (
	input CLOCK_50_B5B, 
	input CPU_RESET_N,
	input AUD_ADCDAT,
 
	inout AUD_BCLK,
	inout AUD_ADCLRCK, 
	inout AUD_DACLRCK,
	inout I2C_SDA,
	
	output AUD_XCK,
	output AUD_DACDAT, 
	output I2C_SCL,
	output [9:0] LEDR,
	output [35:0] GPIO
	);
	
   /***************************************************************
	                  INTERNAL WIRES AND REGISTERS
	***************************************************************/
	
	wire reset; 
	wire pll_locked;
	(* keep, preserve *) wire master_clk;
	(* keep, preserve *) wire lrclk_48k;
	(* keep, preserve *) wire bit_clk;
	
	(* keep, preserve *) wire [15:0] l_data;
	(* keep, preserve *) wire [15:0] r_data;
	(* keep, preserve *) wire [15:0] l_play;
	(* keep, preserve *) wire [15:0] r_play;
	(* keep, preserve *) reg data_valid;
	
	assign reset = !CPU_RESET_N;
	assign AUD_XCK = master_clk;
	assign AUD_ADCLRCK = lrclk_48k;
	assign AUD_DACLRCK = lrclk_48k; 
	
	assign bit_clk = AUD_BCLK; 
	
   assign GPIO[0] = AUD_ADCDAT;
	assign GPIO[1] = AUD_ADCLRCK;
	
	/*****************************************************************************
	 *                             SEQUENTIAL LOGIC                              *
	 *****************************************************************************/
	
	always @(posedge data_valid) begin 
		l_play <= l_data;
		r_play <= r_data; 
	end
			
	/***************************************************************
	                       INTERNAL MODULES
	***************************************************************/
	
	// 12.288 MHz
	pll_12MHz master_clk_12MHz (
		.refclk     (CLOCK_50_B5B),
		.rst        (reset),
		.outclk_0   (master_clk),
		.locked     (pll_locked)
	);
	
   // 48 kHz
	clock_divider sampling_freq(
		.clk_in     (master_clk),
		.divisor		(256),
		.clk_out    (lrclk_48k)
	);
		
	// divisor from datasheet
	clock_divider bit_stream(
		.clk_in     (master_clk),
		.divisor		(4),
		.clk_out    (AUD_BCLK)
	);

	// i2c communication
	i2c codec_i2c (
		.clk     (CLOCK_50_B5B),    	  // 50 mhz pixel clock
		.reset	(!pll_locked || reset),   
		.scl		(I2C_SCL),     				
		.sda		(I2C_SDA)      		
	);
	
	// deserializer
	deserializer audio_deserial (
		.reset	(!pll_locked || reset),
		.lrclk	(AUD_ADCLRCK),     
		.bclk		(AUD_BCLK),
		.dat		(AUD_ADCDAT),
		.l_data	(l_data),
		.r_data	(r_data),
		.data_valid (data_valid)
	);
	
	// serializer
	serializer audio_serial (
		.reset		(!pll_locked || reset),
		.lrclk		(AUD_DACLRCK),
		.bclk			(AUD_BCLK),
		.l_data_in	(l_play),
		.r_data_in	(r_play),
		.dat			(AUD_DACDAT),
		.data_sent  ()// pulses when both L and R words have been sent
	);

endmodule