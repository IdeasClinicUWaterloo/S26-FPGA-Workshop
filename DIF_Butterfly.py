
import cmath

samples = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15] 
A = []
B = []

N = 16

# stage 0 for DIF: index difference = N/2
k2 = N // 2

for i1 in range(k2):
    i2 = i1 + k2
    
    # sum branch: a + b
    a = samples[i1] + samples[i2] 
    A.append(a)
    
    # diff branch: (a - b)Wn
    d = samples[i1] - samples[i2]       
    W = cmath.exp(-2j * cmath.pi * i1 / N)
    
    b = d * W
    B.append(b)
    
    print(W.real, W.imag)

print("A:", A)
print("B:", B)