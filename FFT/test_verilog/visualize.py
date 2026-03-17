import re
import matplotlib.pyplot as plt

log_file = "simulation_log.txt"

bins = []
mags = []

pattern = re.compile(r"FFT bin\s+(\d+)\s+\|\s+Mag=(\d+)")

with open(log_file, "r", encoding="utf-16") as f:
    for line in f:
        match = pattern.search(line)
        if match:
            bins.append(int(match.group(1)))
            mags.append(int(match.group(2)))

print(f"Found {len(bins)} FFT bins")

if not bins:
    print("No FFT data found.")
    exit()

plt.figure(figsize=(12,5))
plt.plot(bins, mags)
plt.xlabel("FFT Bin")
plt.ylabel("Magnitude")
plt.title("FFT Magnitude Spectrum")
plt.grid(True)
plt.show()