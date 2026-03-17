# Echo


## Note 
- Would be good to find a way to remove background noise (sounds like rain)

## Vocal Effect
An echo effect makes the audio sound like you're in a cave or long hallway.

## Implementation

The current sample is combined with a delayed sample from an earlier time. The delayed sample is scaled by $\frac{1}{2}$ so each repeated echo is quieter than the previous one.

The output is given by:

$$
y[n] = x[n] + \frac{1}{2}x[n-D]
$$

where:
- $x[n]$ is the current input sample
- $x[n-D]$ is the delayed sample
- $D$ is the delay length in samples

## Running the Simulation Locally (Outside Quartus)

### Test signal
Two impulse signals

### Terminal commands

Compile and run the simulation with Icarus Verilog:

```bash
iverilog -g2012 -o sim.out testbench.sv echo.sv

vvp sim.out > simulation_log.txt 
```

Generate time-domain plots:
```bash
python -m visualize
```