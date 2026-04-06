import re
import numpy as np
import matplotlib.pyplot as plt

raw_bins = []
raw_re = []
raw_im = []

filt_bins = []
filt_re = []
filt_im = []

with open("simulation_log.txt", "r", encoding="utf-16") as f:
    for line in f:
        raw_match = re.search(r"RAW\s+FFT bin (\d+) : Re=([-0-9]+) Im=([-0-9]+)", line)
        filt_match = re.search(r"FILT FFT bin (\d+) : Re=([-0-9]+) Im=([-0-9]+)", line)

        if raw_match:
            raw_bins.append(int(raw_match.group(1)))
            raw_re.append(int(raw_match.group(2)))
            raw_im.append(int(raw_match.group(3)))

        if filt_match:
            filt_bins.append(int(filt_match.group(1)))
            filt_re.append(int(filt_match.group(2)))
            filt_im.append(int(filt_match.group(3)))

raw_bins = np.array(raw_bins)
filt_bins = np.array(filt_bins)

raw_mag = np.sqrt(np.array(raw_re)**2 + np.array(raw_im)**2)
filt_mag = np.sqrt(np.array(filt_re)**2 + np.array(filt_im)**2)

# Use the same y-axis scale for both plots
ymax = max(np.max(raw_mag), np.max(filt_mag))

fig, axs = plt.subplots(2, 1, figsize=(10, 8))

axs[0].plot(raw_bins, raw_mag)
axs[0].set_title("Input Spectrum")
axs[0].set_xlabel("FFT Bin")
axs[0].set_ylabel("Magnitude")
axs[0].set_ylim(0, ymax)
axs[0].grid(True)

axs[1].plot(filt_bins, filt_mag, color="orange")
axs[1].set_title("Output Spectrum (Filtered)")
axs[1].set_xlabel("FFT Bin")
axs[1].set_ylabel("Magnitude")
axs[1].set_ylim(0, ymax)
axs[1].grid(True)

plt.tight_layout()
plt.show()