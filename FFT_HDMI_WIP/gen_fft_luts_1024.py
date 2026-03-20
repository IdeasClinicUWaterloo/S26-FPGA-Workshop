import math
from pathlib import Path


def fmt_addr(addr: int) -> str:
    # Match the existing MIF style:
    # - 0..FF use 2 hex digits (00..FF)
    # - 100..1FF use 3 hex digits (100..1FF)
    if addr <= 0xFF:
        return f"{addr:02X}"
    return f"{addr:03X}"


def write_mif(path: Path, values):
    # Intel MIF header compatible with the existing project files
    depth = len(values)
    lines = []
    lines.append("WIDTH=16;")
    lines.append(f"DEPTH={depth};")
    lines.append("ADDRESS_RADIX=HEX;")
    lines.append("DATA_RADIX=HEX;")
    lines.append("CONTENT BEGIN")
    for addr, v in enumerate(values):
        # store as 16-bit signed in hex (two's complement)
        u16 = v & 0xFFFF
        lines.append(f"  {fmt_addr(addr)} : {u16:04X};")
    lines.append("END;")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main():
    # Current FFT cores index twiddles by k in [0..N/2-1] with:
    #   cos_lut[k] = cos(2*pi*k/N)
    #   sin_lut[k] = sin(2*pi*k/N)
    # where values are stored as Q1.15 (scale 32767).
    N = 1024
    DEPTH = N // 2  # 512 unique twiddle values due to symmetry
    SCALE = 32767

    cos_values = []
    sin_values = []
    for k in range(DEPTH):
        angle = 2.0 * math.pi * k / N
        c = int(round(math.cos(angle) * SCALE))
        s = int(round(math.sin(angle) * SCALE))
        # Clamp to 16-bit signed range just in case of rounding artifacts
        c = max(-32768, min(32767, c))
        s = max(-32768, min(32767, s))
        cos_values.append(c)
        sin_values.append(s)

    out_dir = Path(__file__).resolve().parent
    write_mif(out_dir / "cos_lut_1024.mif", cos_values)
    write_mif(out_dir / "sin_lut_1024.mif", sin_values)
    print("Generated cos_lut_1024.mif and sin_lut_1024.mif")


if __name__ == "__main__":
    main()

