# FFT HDMI Visualization (WIP)

This project drives an ADV7513 HDMI transmitter with a 1280×720@60 timing generator and renders an **FFT magnitude spectrum** as vertical bars.

## What’s on screen

- **Bars**: one bar per FFT bin, spanning the full width.
- **Baseline**: bottom line in dark gray.
- **Grid**: faint horizontal grid every 64 pixels, faint vertical grid every 64 bins.
- **Color**: bars are green→yellow-ish (red intensity increases with magnitude).

## Data flow (high level)

1. `fft_512.sv` runs a 512-point FFT in the `clk_50` domain.
2. `magnitude_approx.sv` computes a simple magnitude estimate.
3. `mag_ram.v` stores 512 magnitudes (written on `clk_50`, read on `clk_pixel`).
4. `renderer.v` reads the magnitude for the current X position and draws the bar.

## Files to tweak

- **Magnitude scaling**: `hdmi_top.v` line with `bin_read >> 6`
  - If bars are too tall/clipped, increase the shift (e.g. `>> 7`, `>> 8`)
  - If bars are too small, decrease the shift (e.g. `>> 5`)
- **Look & feel**: `renderer.v`
  - Change grid spacing, colors, baseline, etc.
- **FFT stimulus**: `hdmi_top.v` currently feeds a ROM cosine (`cos_samples_rom`) into the FFT.
  - Replace that with your real ADC/audio samples (same `sample/sample_valid` interface into `fft_mag_controller`).

## Notes

- `fft_ram.v` and `mag_ram.v` are **inferred RAMs sized for 512 entries**. The previous wizard stubs in this folder were configured for only 8 entries and would not work correctly for a 512-point FFT.

