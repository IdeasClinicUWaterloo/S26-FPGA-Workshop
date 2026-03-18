module renderer #(
    parameter H_ACTIVE = 1280,
    parameter V_ACTIVE = 720,
    parameter BIN_WIDTH = 24,
    parameter N_BINS    = 512
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

  // Plot layout
  localparam integer PLOT_LEFT   = 64;
  localparam integer PLOT_TOP    = 32;
  localparam integer PLOT_WIDTH  = 1024; // fixed plot width
  localparam integer PLOT_RIGHT  = PLOT_LEFT + PLOT_WIDTH - 1;
  localparam integer PLOT_BOTTOM = V_ACTIVE - 48;
  localparam integer PLOT_HEIGHT = PLOT_BOTTOM - PLOT_TOP + 1;

  // Display only the low-frequency region (0..~6kHz) by stretching the lowest bins
  // across the full plot width. With Fs≈24kHz and N=512, bin width ≈ 46.875Hz,
  // so bins 0..127 cover ≈ 0..6kHz (~128 bins).
  localparam integer DISPLAY_BINS = 128;    // bins 0..127
  localparam integer BIN_PIXELS   = 8;      // 1024px / 128 bins = 8px per bin

  // Cheap X->bin mapping (no mult/div): 8 pixels per bin inside plot.
  wire in_plot_x = (hcount >= PLOT_LEFT) && (hcount <= PLOT_RIGHT);
  wire [11:0] x_plot = hcount - PLOT_LEFT;
  wire [8:0]  bin_from_x = {2'b00, x_plot[9:3]};  // 0..127 (8px per bin)
  assign bin_idx = in_plot_x ? bin_from_x : 9'd0;

  // delay vcount and de by 1 cycle to match the RAM latency
  reg [11:0] vcount_pipe;
  reg        de_pipe;
  reg [BIN_WIDTH - 1:0] bin_magnitude;
  reg [8:0]  bin_idx_pipe;
  reg [11:0] hcount_pipe;
  reg [11:0] mag_clip;
  reg [11:0] bar_height;
  reg [11:0] y_plot;
  reg [23:0] bar_color;

  always @(posedge clk) begin
    vcount_pipe <= vcount;
    de_pipe     <= de;
    bin_idx_pipe <= bin_idx;
    hcount_pipe <= hcount;
	 
	 // clamp magnitude at upper bound (later clipped to plot height)
	 if(bin_magnitude_raw > V_ACTIVE) bin_magnitude <= V_ACTIVE;
	 else bin_magnitude <= bin_magnitude_raw;
  end

  // 5x7 font (digits only). Returns 5-bit row bitmap, MSB=left pixel.
  function [4:0] font5x7_digit;
    input [3:0] digit;
    input [2:0] row;
    begin
      case (digit)
        4'd0: case (row) 3'd0:font5x7_digit=5'b01110; 3'd1:font5x7_digit=5'b10001; 3'd2:font5x7_digit=5'b10011; 3'd3:font5x7_digit=5'b10101; 3'd4:font5x7_digit=5'b11001; 3'd5:font5x7_digit=5'b10001; 3'd6:font5x7_digit=5'b01110; default:font5x7_digit=5'b00000; endcase
        4'd1: case (row) 3'd0:font5x7_digit=5'b00100; 3'd1:font5x7_digit=5'b01100; 3'd2:font5x7_digit=5'b00100; 3'd3:font5x7_digit=5'b00100; 3'd4:font5x7_digit=5'b00100; 3'd5:font5x7_digit=5'b00100; 3'd6:font5x7_digit=5'b01110; default:font5x7_digit=5'b00000; endcase
        4'd2: case (row) 3'd0:font5x7_digit=5'b01110; 3'd1:font5x7_digit=5'b10001; 3'd2:font5x7_digit=5'b00001; 3'd3:font5x7_digit=5'b00010; 3'd4:font5x7_digit=5'b00100; 3'd5:font5x7_digit=5'b01000; 3'd6:font5x7_digit=5'b11111; default:font5x7_digit=5'b00000; endcase
        4'd3: case (row) 3'd0:font5x7_digit=5'b11110; 3'd1:font5x7_digit=5'b00001; 3'd2:font5x7_digit=5'b00001; 3'd3:font5x7_digit=5'b01110; 3'd4:font5x7_digit=5'b00001; 3'd5:font5x7_digit=5'b00001; 3'd6:font5x7_digit=5'b11110; default:font5x7_digit=5'b00000; endcase
        4'd4: case (row) 3'd0:font5x7_digit=5'b00010; 3'd1:font5x7_digit=5'b00110; 3'd2:font5x7_digit=5'b01010; 3'd3:font5x7_digit=5'b10010; 3'd4:font5x7_digit=5'b11111; 3'd5:font5x7_digit=5'b00010; 3'd6:font5x7_digit=5'b00010; default:font5x7_digit=5'b00000; endcase
        4'd5: case (row) 3'd0:font5x7_digit=5'b11111; 3'd1:font5x7_digit=5'b10000; 3'd2:font5x7_digit=5'b11110; 3'd3:font5x7_digit=5'b00001; 3'd4:font5x7_digit=5'b00001; 3'd5:font5x7_digit=5'b10001; 3'd6:font5x7_digit=5'b01110; default:font5x7_digit=5'b00000; endcase
        4'd6: case (row) 3'd0:font5x7_digit=5'b00110; 3'd1:font5x7_digit=5'b01000; 3'd2:font5x7_digit=5'b10000; 3'd3:font5x7_digit=5'b11110; 3'd4:font5x7_digit=5'b10001; 3'd5:font5x7_digit=5'b10001; 3'd6:font5x7_digit=5'b01110; default:font5x7_digit=5'b00000; endcase
        4'd7: case (row) 3'd0:font5x7_digit=5'b11111; 3'd1:font5x7_digit=5'b00001; 3'd2:font5x7_digit=5'b00010; 3'd3:font5x7_digit=5'b00100; 3'd4:font5x7_digit=5'b01000; 3'd5:font5x7_digit=5'b01000; 3'd6:font5x7_digit=5'b01000; default:font5x7_digit=5'b00000; endcase
        4'd8: case (row) 3'd0:font5x7_digit=5'b01110; 3'd1:font5x7_digit=5'b10001; 3'd2:font5x7_digit=5'b10001; 3'd3:font5x7_digit=5'b01110; 3'd4:font5x7_digit=5'b10001; 3'd5:font5x7_digit=5'b10001; 3'd6:font5x7_digit=5'b01110; default:font5x7_digit=5'b00000; endcase
        4'd9: case (row) 3'd0:font5x7_digit=5'b01110; 3'd1:font5x7_digit=5'b10001; 3'd2:font5x7_digit=5'b10001; 3'd3:font5x7_digit=5'b01111; 3'd4:font5x7_digit=5'b00001; 3'd5:font5x7_digit=5'b00010; 3'd6:font5x7_digit=5'b01100; default:font5x7_digit=5'b00000; endcase
        default: case (row) 3'd0:font5x7_digit=5'b00000; 3'd1:font5x7_digit=5'b00000; 3'd2:font5x7_digit=5'b00000; 3'd3:font5x7_digit=5'b00000; 3'd4:font5x7_digit=5'b00000; 3'd5:font5x7_digit=5'b00000; 3'd6:font5x7_digit=5'b00000; default:font5x7_digit=5'b00000; endcase
      endcase
    end
  endfunction

  function is_digit_pixel;
    input [11:0] px;
    input [11:0] py;
    input [11:0] x0;
    input [11:0] y0;
    input [3:0]  digit;
    reg [2:0] row;
    reg [2:0] col;
    reg [4:0] bits;
    begin
      if (px < x0 || px >= x0 + 12'd5 || py < y0 || py >= y0 + 12'd7) begin
        is_digit_pixel = 1'b0;
      end else begin
        row = py - y0;
        col = px - x0;
        bits = font5x7_digit(digit, row);
        is_digit_pixel = bits[4 - col];
      end
    end
  endfunction

  function is_3digit_pixel;
    input [11:0] px;
    input [11:0] py;
    input [11:0] x0;
    input [11:0] y0;
    input [9:0]  value; // 0..999
    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;
    begin
      hundreds = (value / 100) % 10;
      tens     = (value / 10)  % 10;
      ones     = value % 10;

      is_3digit_pixel =
        is_digit_pixel(px, py, x0 + 12'd0,  y0, hundreds) ||
        is_digit_pixel(px, py, x0 + 12'd6,  y0, tens)     ||
        is_digit_pixel(px, py, x0 + 12'd12, y0, ones);
    end
  endfunction

  function is_4digit_pixel;
    input [11:0] px;
    input [11:0] py;
    input [11:0] x0;
    input [11:0] y0;
    input [13:0] value; // 0..9999
    reg [3:0] thousands;
    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;
    begin
      thousands = (value / 1000) % 10;
      hundreds  = (value / 100)  % 10;
      tens      = (value / 10)   % 10;
      ones      = value % 10;

      is_4digit_pixel =
        is_digit_pixel(px, py, x0 + 12'd0,  y0, thousands) ||
        is_digit_pixel(px, py, x0 + 12'd6,  y0, hundreds)  ||
        is_digit_pixel(px, py, x0 + 12'd12, y0, tens)      ||
        is_digit_pixel(px, py, x0 + 12'd18, y0, ones);
    end
  endfunction

  always @(posedge clk) begin
    if (!de_pipe) begin
      rgb <= BLACK;
    end else begin
      // Clip magnitude to plot height (pixels)
      mag_clip = (bin_magnitude > PLOT_HEIGHT) ? PLOT_HEIGHT[11:0] : bin_magnitude[11:0];
      bar_height = mag_clip;

      // Default background
      rgb <= BLACK;

      // Axis lines
      if (hcount_pipe == PLOT_LEFT-1 && vcount_pipe >= PLOT_TOP && vcount_pipe <= PLOT_BOTTOM) begin
        rgb <= 24'h808080; // Y axis
      end else if (vcount_pipe == PLOT_BOTTOM && hcount_pipe >= PLOT_LEFT-1 && hcount_pipe <= PLOT_RIGHT) begin
        rgb <= 24'h808080; // X axis
      end

      // Choose bar color (heatmap by magnitude/presence):
      // purple -> blue -> green -> yellow -> orange -> red
      if (bar_height < (PLOT_HEIGHT[11:0] >> 3))        bar_color <= 24'h8000FF; // purple
      else if (bar_height < (PLOT_HEIGHT[11:0] >> 2))   bar_color <= 24'h0000FF; // blue
      else if (bar_height < (PLOT_HEIGHT[11:0] >> 1))   bar_color <= 24'h00FF00; // green
      else if (bar_height < (PLOT_HEIGHT[11:0] - (PLOT_HEIGHT[11:0] >> 2))) bar_color <= 24'hFFFF00; // yellow
      else if (bar_height < (PLOT_HEIGHT[11:0] - (PLOT_HEIGHT[11:0] >> 3))) bar_color <= 24'hFF7F00; // orange
      else                                        bar_color <= 24'hFF0000; // red

      // Grid lines (light)
      if (hcount_pipe >= PLOT_LEFT && hcount_pipe <= PLOT_RIGHT &&
          vcount_pipe >= PLOT_TOP  && vcount_pipe <= PLOT_BOTTOM) begin
        // Verilog doesn't allow slicing an expression like (a-b)[n:m],
        // so use a mask test instead.
        if (((hcount_pipe - PLOT_LEFT) & 12'h07F) == 12'd0) rgb <= 24'h101010; // vertical grid every 128px (=64 bins)
        if (((vcount_pipe - PLOT_TOP)  & 12'h03F) == 12'd0) rgb <= 24'h101010; // horizontal grid every 64px

        // Bars (draw on top of grid)
        y_plot = PLOT_BOTTOM - vcount_pipe;
        if (y_plot < bar_height) rgb <= bar_color;
      end

      // X axis labels (bin numbers)
      // Frequency labels in Hz for the displayed 0..6kHz region.
      if (vcount_pipe >= PLOT_BOTTOM + 12'd6 && vcount_pipe < PLOT_BOTTOM + 12'd13) begin
        // Tick X positions for 0..6kHz across 1024px: 0, 170, 341, 512, 683, 853, 1023
        if (is_3digit_pixel(hcount_pipe, vcount_pipe, PLOT_LEFT + 12'd0,    PLOT_BOTTOM + 12'd6, 10'd0))    rgb <= 24'hFFFFFF;
        if (is_4digit_pixel(hcount_pipe, vcount_pipe, PLOT_LEFT + 12'd160,  PLOT_BOTTOM + 12'd6, 14'd1000)) rgb <= 24'hFFFFFF;
        if (is_4digit_pixel(hcount_pipe, vcount_pipe, PLOT_LEFT + 12'd331,  PLOT_BOTTOM + 12'd6, 14'd2000)) rgb <= 24'hFFFFFF;
        if (is_4digit_pixel(hcount_pipe, vcount_pipe, PLOT_LEFT + 12'd502,  PLOT_BOTTOM + 12'd6, 14'd3000)) rgb <= 24'hFFFFFF;
        if (is_4digit_pixel(hcount_pipe, vcount_pipe, PLOT_LEFT + 12'd673,  PLOT_BOTTOM + 12'd6, 14'd4000)) rgb <= 24'hFFFFFF;
        if (is_4digit_pixel(hcount_pipe, vcount_pipe, PLOT_LEFT + 12'd843,  PLOT_BOTTOM + 12'd6, 14'd5000)) rgb <= 24'hFFFFFF;
        if (is_4digit_pixel(hcount_pipe, vcount_pipe, PLOT_LEFT + 12'd994,  PLOT_BOTTOM + 12'd6, 14'd6000)) rgb <= 24'hFFFFFF;
      end

      // Y axis labels (0, 50, 100 percent)
      if (hcount_pipe < PLOT_LEFT-12'd6 && hcount_pipe >= 12'd6) begin
        if (is_3digit_pixel(hcount_pipe, vcount_pipe, 12'd6, PLOT_BOTTOM - 12'd7, 10'd0))   rgb <= 24'hFFFFFF;
        if (is_3digit_pixel(hcount_pipe, vcount_pipe, 12'd6, PLOT_TOP + (PLOT_HEIGHT/2) - 12'd3, 10'd50))  rgb <= 24'hFFFFFF;
        if (is_3digit_pixel(hcount_pipe, vcount_pipe, 12'd6, PLOT_TOP - 12'd3, 10'd100)) rgb <= 24'hFFFFFF;
      end
	 end
  end
endmodule
