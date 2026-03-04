import re
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ---- read log (your file is UTF-16) ----
path = "simulation_log.txt"   # or full path if needed
with open(path, "r", encoding="utf-16", errors="ignore") as f:
    text = f.read()

# ---- parse "Bin ... | Real: ... | Imag: ..." lines ----
pattern = re.compile(r"Bin\s+(\d+)\s*\|\s*Real:\s*(-?\d+)\s*\|\s*Imag:\s*(-?\d+)")
rows = [(int(b), int(r), int(i)) for b, r, i in pattern.findall(text)]

if not rows:
    raise RuntimeError("No FFT bin lines found. Check file encoding / format.")

bins = np.array([b for b,_,_ in rows], dtype=int)
real = np.array([r for _,r,_ in rows], dtype=float)
imag = np.array([i for _,_,i in rows], dtype=float)
mag  = np.sqrt(real**2 + imag**2)

df = pd.DataFrame({"bin": bins, "real": real.astype(int), "imag": imag.astype(int), "mag": mag})

# ---- show top peaks ----
top = df.sort_values("mag", ascending=False).head(12)
print("\nTop FFT bins by magnitude:")
print(top.to_string(index=False))

# ---- plot linear magnitude ----
plt.figure(figsize=(12,4))
plt.plot(bins, mag)
plt.title("FFT Output Magnitude vs Bin (linear)")
plt.xlabel("Bin")
plt.ylabel("Magnitude")
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()

# ---- plot dB magnitude ----
eps = 1e-9
mag_db = 20*np.log10(mag + eps)

plt.figure(figsize=(12,4))
plt.plot(bins, mag_db)
plt.title("FFT Output Magnitude vs Bin (dB, relative)")
plt.xlabel("Bin")
plt.ylabel("Magnitude (dB)")
plt.grid(True, alpha=0.3)
plt.tight_layout()
plt.show()