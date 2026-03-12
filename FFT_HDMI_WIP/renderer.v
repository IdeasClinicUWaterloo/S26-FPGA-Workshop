module renderer #(
    parameter H_ACTIVE = 1280,
    parameter V_ACTIVE = 720,
	 parameter BIN_WIDTH = 24
) (
    input  wire        clk,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    input  wire        de,
    output reg  [23:0] rgb,

    output wire [8:0] bin_idx,
    input wire  [BIN_WIDTH - 1:0] bin_magnitude_raw
);

  localparam BLACK = 24'h000000;
  localparam WHITE = 24'hFFFFFF;

  assign bin_idx = hcount[9:1];

  // delay vcount and de by 1 cycle to match the RAM latency
  reg [11:0] vcount_pipe;
  reg        de_pipe;
  reg [BIN_WIDTH - 1:0] bin_magnitude;

  always @(posedge clk) begin
    vcount_pipe <= vcount;
    de_pipe     <= de;
	 
	 // clamp magnitude at upper bound
	 if(bin_magnitude_raw > V_ACTIVE) bin_magnitude <= V_ACTIVE;
	 else bin_magnitude <= bin_magnitude_raw;
  end

  always @(posedge clk) begin
    if (!de_pipe) begin
      rgb <= BLACK;
    end else begin
		if (vcount_pipe >= V_ACTIVE - bin_magnitude) begin
          rgb <= WHITE;
      end else begin
          rgb <= BLACK;
      end
	 end
  end
endmodule
