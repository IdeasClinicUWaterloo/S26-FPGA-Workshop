# Low-pass Filter

## Note:
- I guessed that the sampling frequency was 44 kHz but I think I was wrong
- The filters work in general but the coeff need to be redesigned for the ADC on the FPGA's sampling frequency so the audio doesn't sound like static

## Vocal Effect
Audio signals that sound like it's underwater/muffled. 

## Filter
A 4th-order Butterworth low-pass filter (1000 Hz) implemented as two cascaded second-order sections using the Direct Form I structure.

Each 2nd order filter follows the Direct Form I structure:

$$
y[n] = b_0 x[n] + b_1 x[n-1] + b_2 x[n-2] - a_1 y[n-1] - a_2 y[n-2]
$$

## MATLAB code for Coefficients
```matlab
Fs = 44000;     % sample rate
Fc = 800;       % cutoff
N  = 4;         % filter order

lpIIR = designfilt('lowpassiir', ...
    'FilterOrder', N, ...
    'HalfPowerFrequency', Fc, ...
    'SampleRate', Fs, ...
    'DesignMethod', 'butter');

fvtool(lpIIR)

[b, a] = tf(lpIIR);
[sos, g] = tf2sos(b, a);

disp('sos =')
disp(sos) % coeffs
disp('g =')
disp(g) % gain
``` 
### Scaling Coefficients
Verilog does not support fractional numbers, so the coefficients are scaled by multiplying them by $2^{18}$ to maintain precision.

After all calculations are performed, the result is divided by $2^{18}$ to return the output to the correct magnitude.

### Similarity to Bandpass

Implementation is similar to the band-pass filter. However, because the gain of the low-pass filter is very small, the scaling factor had to be increased to $2^{18}$ to preserve precision. This required using larger data widths for the coefficients and intermediate values.

## Running the Simulation Locally (Outside Quartus)

### Test signal
A three-tone signal made up of sine waves at: 
- **171.875 Hz**   (passband)
- **1031.25 Hz**   (close to cutoff)
- **3953.125 Hz**  (outside passband)


### Terminal commands

Compile and run the simulation with Icarus Verilog:

```bash
iverilog -g2012 -o sim.out testbench.sv fourth_order_lpf.sv second_order_lpf.sv fft/cos_rom.sv fft/fft.sv fft/sin_rom.sv fft/ram.sv

vvp sim.out > simulation_log.txt 
```

Generate the frequency spectrum plot:

```bash
python -m visualize
```