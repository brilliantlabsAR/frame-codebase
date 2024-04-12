#
# Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#

import numpy as np
import scipy
import sys
import dct_aan
import quant

np.set_printoptions(suppress=True, precision=3)

# PSNR for quality measurements
def psnr(x, y):
    return 20 * np.log10(255 / (sys.float_info.epsilon + np.sqrt(np.mean((x - y) ** 2))))


# Matrix multiplication
def dct_coefficients(x, u):
    """Calculate DCT coefficients for matrix multiplication"""
    c = np.cos((2 * x + 1) * u * np.pi / 16) / 2
    if u == 0:
        c /= np.sqrt(2)
    return c


# 1D-DCT matrix for matrix multiplication
dct_matrix = np.fromfunction(np.vectorize(dct_coefficients), (8, 8), dtype=float)


def dct1d(d, sel='aan'):
    """1-D DCT"""
    if sel == 'matrix':
        return d.dot(dct_matrix)
    elif sel == 'scipy':
        return scipy.fftpack.dct(d, norm='ortho')
    elif sel == 'aan':
        # return dct_aan.dct_aan(d, scale=False)
        return np.apply_along_axis(dct_aan.dct_aan, axis=1, arr=d)

def dct2d(d, sel='scipy'):
    """2-D JPEG DCT. AAN DCT requires a scaling factor"""
    if sel == 'scipy':
        return scipy.fft.dctn(d, norm='ortho')
    return dct1d(dct1d(d, sel).T, sel).T


def check_dcts():
    # Generate random data
    # data = (256 * np.random.rand(8, 8)).astype(int)
    data = np.array([
    [139, 144, 149, 153, 155, 155, 155, 155],
    [144, 151, 153, 156, 159, 156, 156, 156],
    [150, 155, 160, 163, 158, 156, 156, 156],
    [159, 161, 162, 160, 160, 159, 159, 159],
    [159, 160, 161, 162, 162, 155, 155, 155],
    [161, 161, 161, 161, 160, 157, 157, 157],
    [162, 162, 161, 163, 162, 157, 157, 157],
    [162, 162, 161, 161, 163, 158, 158, 158]])
    data -= 128

    # 1. make sure matrix matches
    m1d = dct1d(data, 'matrix')
    s1d = dct1d(data, 'scipy')
    print('PSNR (matrix vs. scipy, 1D) = ', psnr(m1d, s1d))

    m2d = dct2d(data, 'matrix')
    s2d = dct2d(data, 'scipy')
    print('PSNR (matrix vs. scipy, 2D) = ', psnr(m2d, s2d))

    # 2. make sure AAN matches
    a1d = dct1d(data, 'aan')
    a2d = dct2d(data, 'aan')

    s = dct_aan.aan_scale_factors_1d
    print('PSNR (scipy vs. 12-bit AAN, 1D) = ', psnr(s1d, a1d * s))

    s = dct_aan.aan_scale_factors_2d
    print('PSNR (scipy vs. 12-bit AAN, 2D) = ', psnr(s2d, a2d * s))

    print('Scipy = \n', s2d)
    print('AAN = \n', a2d)
    print('AAN scaled = \n', a2d * s)

    #print(data, a2d, s2d)
    print(quant.qt_luma)
    print( s2d /quant.qt_luma )
    print(np.round( s2d /quant.qt_luma,0 ).astype(int))







if __name__ == '__main__':
    check_dcts()

qqq = """
d = np.zeros((8, 8))
d[:, :2] = 10
d[:, 4:6] = 7
d[0, :] = 14
d[5:, :] = 9

f = d.dot(dct_matrix)
out = f.T.dot(dct_matrix)
# print(np.round(dct_matrix), 23)
print('m=', dct_matrix)
print('d=', d)
print('F=', f)
print('OUT =', out)

f_0 = dct(d, norm='ortho')
out_0 = dct(f_0.T, norm='ortho')
print('\n\nF=', f_0)
print('\n\nOUT=', out_0)

f_0 = np.apply_along_axis(arai_dct.aan_dct, axis=1, arr=d)
out_0 = np.apply_along_axis(arai_dct.aan_dct, axis=1, arr=f_0.T)

# out_0 = arai_dct.aan_dct(f_0.T)
print('\n\nF=', f_0)
print('\n\nOUT=', out_0)

q = np.outer(arai_dct.s, arai_dct.s)
print("Q adjust = ", q)
print(out_0)
out_0 = out_0 * q
print(out_0)

print("PSNRs = ", psnr(out_0, out))

print("1-D q=", 1 / np.max(arai_dct.s), 1 / np.min(arai_dct.s))
print("2-D q=", 1 / np.max(q), 1 / np.min(q))

print(np.outer(dct_matrix, dct_matrix))
"""
