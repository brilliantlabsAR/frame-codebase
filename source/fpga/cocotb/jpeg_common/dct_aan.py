#
# Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
#   from https://unix4lyfe.org/dct-1d/
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#

import numpy as np
import re

#np.set_printoptions(suppress=True, precision=3)

# Precision reduction
def a_precision(a, n=12):
    return np.floor(0.5 + a * 2 ** n) / 2 ** n  # +0.5 Rounding


# Multiplier constants
a1 = np.sqrt(.5)  # = 0.707
a2 = np.sqrt(2.) * np.cos(3. / 16. * 2 * np.pi)  # = 0.541
a3 = a1  # = 0.707
a4 = np.sqrt(2.) * np.cos(1. / 16. * 2 * np.pi)  # = 1.307
a5 = np.cos(3. / 16. * 2 * np.pi)  # = 0.383
if True:
    # Reduced precision to 12 bits
    a1 = a_precision(a1)
    a2 = a_precision(a2)
    a3 = a1
    a4 = a_precision(a4)
    a5 = a_precision(a5)

# Scaling factors for q-tables
# 1-D
s = np.empty(8)
s[0] = (np.cos(0) * np.sqrt(.5) / 2) / 1                # 0.353553
s[1] = (np.cos(1. * np.pi / 16) / 2) / (-a5 + a4 + 1)   # 0.254898
s[2] = (np.cos(2. * np.pi / 16) / 2) / (a1 + 1)         # 0.270598
s[3] = (np.cos(3. * np.pi / 16) / 2) / (a5 + 1)         # 0.300672
s[4] = s[0]  # (np.cos(4.*np.pi/16)/2)/(1       )
s[5] = (np.cos(5. * np.pi / 16) / 2) / (1 - a5)         # 0.449988
s[6] = (np.cos(6. * np.pi / 16) / 2) / (1 - a1)         # 0.653281
s[7] = (np.cos(7. * np.pi / 16) / 2) / (a5 - a4 + 1)    # 1.281458

if False:
    # Reduced precision to 12 bits
    s = a_precision(s)

# 2-D to be used in JPEG quantization
aan_scale_factors_1d = np.tile(s, (8, 1))
aan_scale_factors_2d = np.outer(s, s)


def dct_aan(i, scale=False):
    # Calculate DCT according to from https://unix4lyfe.org/dct-1d/
    b = np.empty(8)
    c = np.empty(8)
    d = np.empty(9)
    e = np.empty(8)
    f = np.empty(8)
    g = np.empty(8)
    o = np.empty(8)
    
    #print(i)

    # Stage 0a
    b[0] = i[0] + i[7]
    b[1] = i[1] + i[6]
    b[2] = i[2] + i[5]
    b[3] = i[3] + i[4]
    b[4] = -i[4] + i[3]
    b[5] = -i[5] + i[2]
    b[6] = -i[6] + i[1]
    b[7] = -i[7] + i[0]
    
    # Stage 0b
    c[0] = b[0] + b[3]
    c[1] = b[1] + b[2]
    c[2] = -b[2] + b[1]
    c[3] = -b[3] + b[0]
    c[4] = -b[4] - b[5]
    c[5] = b[5] + b[6]
    c[6] = b[6] + b[7]
    c[7] = b[7]

    # stage 1 + 2
    d[0] = c[0] + c[1]
    d[1] = -c[1] + c[0]
    d[2] = (c[2] + c[3]) * a1  # c[2] + c[3]
    d[3] = c[3]
    d[4] = -c[4] * a2  # c[4]
    d[5] = c[5] * a3
    d[6] = c[6] * a4  # c[6]
    d[7] = c[7]

    d[8] = (c[4] + c[6]) * a5
    
    # makes debug easier
    d = 4096 * d

    # Stage 3a
    e[0] = d[0]
    e[1] = d[1]
    e[2] = d[2]  # d[2] * a1
    e[3] = d[3]
    e[4] = d[4] - d[8]  # -d[4] * a2 - d[8]
    e[5] = d[5] + d[7]  # d[5] # d[5] * a3
    e[6] = d[6] - d[8]  # d[6] * a4 - d[8]
    e[7] = d[7] - d[5]  # d[7]

    # stage eliminated
    f[0] = e[0]
    f[1] = e[1]
    f[2] = e[2]  # e[2] + e[3]
    f[3] = e[3]  # e[3] - e[2]
    f[4] = e[4]
    f[5] = e[5]  # e[5] + e[7]
    f[6] = e[6]
    f[7] = e[7]  # e[7] - e[5]

    # Stage 3b
    g[0] = f[0]
    g[1] = f[1]
    g[2] = f[2] + f[3]  # f[2]
    g[3] = f[3] - f[2]  # f[3]
    g[4] = f[4] + f[7]
    g[5] = f[5] + f[6]
    g[6] = -f[6] + f[5]
    g[7] = f[7] - f[4]

    # Output un-swizzle and round
    o[0] = g[0]
    o[4] = g[1]
    o[2] = g[2]
    o[6] = g[3]
    o[5] = g[4]
    o[1] = g[5]
    o[7] = g[6]
    o[3] = g[7]
    
    # add +0.5 for rounding, then shift right
    #o += np.where(o < 0, -2048, 2048)
    #o //= 4096
    o = (o + 2048) // 4096
    #print(o)

    # For JPEG push scale into quantization tables
    if scale:
        o *= s
    return o


def print_a_factors():
    for n in [12]:
        print('Multiplication constants bit width M = ', n)
        for i in range(1, 6):
            a = [0, a1, a2, a3, a4, a5]
            k = {1: 2, 2: 4, 3: 5, 4: 6, 5: 8}
            m = (0.5 + a[i] * 2 ** n) # +0.5 Rounding
            im = int(m)

            shifts = [m.start() for m in re.finditer('1', '{:08b}'.format(im)[::-1])]

            j = k[i]
            m = [f'(x[{j}] << {p})' for p in shifts]
            m = ' + '.join(m)
            b = '{:08b}'.format(im)
            b = f'a{i}:    Binary = {b}'
            dec = f'       Decimal = {im}'
            sh = f'       Shifts = {shifts}, Total = {len(shifts)}'
            print(b)
            print(dec)
            print(sh)
            m = f'       y[{j}] = {m};'

            print(m)
        print('\n')


if __name__ == "__main__":
    print_a_factors()
