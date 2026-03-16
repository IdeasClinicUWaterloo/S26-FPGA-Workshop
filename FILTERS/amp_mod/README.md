# Amplitude Modulation

## Note:
- the testbench and visualize.py is still WIP

## Vocal Effect
 Audio signals that sound like they're pulsating.

## Amplitude Modulation
Multiply the incoming samples by a sine wave. We also add a constant offset to the sine so it never goes negative because negative audio sounds really weird. 

$$
y[n] = A sin[n + C] * x[n]
$$

### Scaling Coefficients
Verilog does not support fractional numbers, so the coefficients are scaled by multiplying them by $2^{14}$ to maintain precision.

We also added a phase shift to the sine wave so the scale increased from $2^{14}$ to $2^{15}$.

But after all calculations are performed, the result is divided by $2^{14}$ to return the output to the correct magnitude with an additional gain of 2 because it was a bit quiet before.

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