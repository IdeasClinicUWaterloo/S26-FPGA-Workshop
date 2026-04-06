import re
import matplotlib.pyplot as plt

filename = "simulation_log.txt"

ins = []
outs = []

pattern = re.compile(r"in\s*=\s*(-?\d+)\s*,\s*out\s*=\s*(-?\d+)")

with open(filename, "r", encoding="utf-16") as f:
    for line in f:
        match = pattern.search(line)
        if match:
            ins.append(int(match.group(1)))
            outs.append(int(match.group(2)))

print("Samples parsed:", len(ins))

if len(ins) == 0:
    raise ValueError("No samples parsed. Check filename/path and log format.")

samples = list(range(len(ins)))

# Create one window with two plots
fig, axs = plt.subplots(2, 1, figsize=(10, 6), sharex=True)

# Input signal
axs[0].plot(samples, ins)
axs[0].set_title("Input Signal")
axs[0].set_ylabel("Amplitude")
axs[0].grid(True)

# Output signal
axs[1].plot(samples, outs, color="orange")
axs[1].set_title("Output Signal")
axs[1].set_xlabel("Sample")
axs[1].set_ylabel("Amplitude")
axs[1].grid(True)

plt.tight_layout()
plt.show()