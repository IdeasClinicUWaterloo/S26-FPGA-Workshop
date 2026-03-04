import numpy as np
import math


def int_to_twos_complement_hex(number, bits):
    """
    Return the 2's complement hexadecimal representation of a number 
    for a given number of bits.
    """
    if number >= 0:
        # For positive numbers, simply format to hex with zero padding
        return format(number, f'0{bits//4}x')
    else:
        # For negative numbers, apply the bitwise AND with the mask
        mask = (1 << bits) - 1
        twos_comp_val = number & mask
        return format(twos_comp_val, f'0{bits//4}x')


scale = 2**15  # Q1.15
N = 512

for k in range(256):
    cos_val = round(scale*math.sin((2*math.pi*k)/N))

    c = 0; 
    if cos_val < 0:
        c = int_to_twos_complement_hex(cos_val, 16)
    else: 
        c = hex(cos_val)
    print(c)