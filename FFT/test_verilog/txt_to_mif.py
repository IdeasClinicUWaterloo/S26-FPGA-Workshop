input_file = "cos_samples.txt"
output_file = "cos_samples.mif"

width = 16

with open(input_file, "r", encoding="utf-8", errors="ignore") as f:
    values = [line.strip().upper() for line in f if line.strip()]

depth = len(values)

with open(output_file, "w") as f:
    f.write(f"WIDTH={width};\n")
    f.write(f"DEPTH={depth};\n\n")
    f.write("ADDRESS_RADIX=UNS;\n")
    f.write("DATA_RADIX=HEX;\n\n")
    f.write("CONTENT BEGIN\n")

    for addr, value in enumerate(values):
        f.write(f"    {addr} : {value};\n")

    f.write("END;\n")

print(f"Created {output_file} with {depth} entries.")