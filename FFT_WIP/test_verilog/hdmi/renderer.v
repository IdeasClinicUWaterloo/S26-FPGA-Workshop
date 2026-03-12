module renderer #(
    parameter H_ACTIVE = 1280,
    parameter V_ACTIVE = 720
) (
    input  wire        clk,
    input  wire [11:0] hcount,
    input  wire [11:0] vcount,
    input  wire        de,
    output reg  [23:0] rgb,

    output wire [8:0] bin_idx,
    input wire [15:0] bin_magnitude
);

  localparam BLACK = 24'h000000;
  localparam WHITE = 24'hFFFFFF;

  assign bin_idx = hcount[9:1];

  // delay vcount and de by 1 cycle to match the RAM latency
  reg [11:0] vcount_pipe;
  reg        de_pipe;

  always @(posedge clk) begin
    vcount_pipe <= vcount;
    de_pipe     <= de;
  end

  always @(posedge clk) begin
    if (!de_pipe) begin
      rgb <= BLACK;
    end else begin
        if (vcount_pipe <= V_ACTIVE && vcount_pipe >= (V_ACTIVE - (bin_magnitude >> 6))) begin
          rgb <= WHITE;
        end else begin
          rgb <= BLACK;
        end
    end
  end

endmodule
