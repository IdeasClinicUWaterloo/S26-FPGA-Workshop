# Band-pass Filter

## Note:
- I guessed that the sampling frequency was 44 kHz but I think I was wrong
- The filters work in general but the coeff need to be redesigned for the ADC on the FPGA's sampling frequency so the audio doesn't sound like static

## Vocal Effect
 Audio signals that sound like they're coming from an old retro telephone. 

## Filter
A 4th-order Butterworth band-pass filter (300–3400 Hz) implemented as two cascaded second-order sections using the Direct Form I structure.

Each 2nd order filter follows the Direct Form I structure:

$$
y[n] = b_0 x[n] + b_1 x[n-1] + b_2 x[n-2] - a_1 y[n-1] - a_2 y[n-2]
$$

## MATLAB code for Coefficients
```matlab
Fs = 44000;     % sample rate
F1 = 300;       % lower passband edge
F2 = 3400;      % upper passband edge
N  = 4;         % final filter order

bpIIR = designfilt('bandpassiir', ...
    'FilterOrder', N, ...
    'HalfPowerFrequency1', F1, ...
    'HalfPowerFrequency2', F2, ...
    'SampleRate', Fs, ...
    'DesignMethod', 'butter');

fvtool(bpIIR)

[b, a] = tf(bpIIR);
[sos, g] = tf2sos(b, a);

disp('sos =')
disp(sos) % coeff
disp('g =')
disp(g) % gain
``` 
### Scaling Coefficients
Verilog does not support fractional numbers, so the coefficients are scaled by multiplying them by $2^{14}$ to maintain precision.

After all calculations are performed, the result is divided by $2^{14}$ to return the output to the correct magnitude.

## Running the Simulation Locally (Outside Quartus)

### Test signal
A three-tone signal made up of sine waves at: 
- **171.875 Hz** (below the passband)  
- **1031.25 Hz** (inside the passband)  
- **3953.125 Hz** (above the passband)  

### Terminal commands

Compile and run the simulation with Icarus Verilog:

```bash
iverilog -g2012 -o sim.out testbench.sv fourth_order_bpf.sv second_order_bpf.sv fft/cos_rom.sv fft/fft.sv fft/sin_rom.sv fft/ram.sv

vvp sim.out > simulation_log.txt 
```

Generate the frequency spectrum plot:
```bash
python -m visualize
```