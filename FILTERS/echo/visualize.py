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

plt.figure(figsize=(10, 4))
plt.plot(samples, ins)
plt.title("Input Signal")
plt.xlabel("Sample")
plt.ylabel("Amplitude")
plt.grid(True)

plt.figure(figsize=(10, 4))
plt.plot(samples, outs)
plt.title("Output Signal")
plt.xlabel("Sample")
plt.ylabel("Amplitude")
plt.grid(True)

plt.show()