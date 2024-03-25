import numpy as np

def rgb2yuv(r, g, b):
    y = np.minimum(np.maximum(0, np.round(  0.299*r +0.587*g +0.114*b            )), 255).astype(int)
    u = np.minimum(np.maximum(0, np.round((-0.299*r -0.587*g +0.886*b)/1.772 +128)), 255).astype(int)
    v = np.minimum(np.maximum(0, np.round(( 0.701*r -0.587*g -0.114*b)/1.402 +128)), 255).astype(int)
    return y, u, v

def yuv2rgb(y, u, v):
    r = np.minimum(np.maximum(0, np.round(y                             +1.402*(v-128)       )), 255).astype(int)
    g = np.minimum(np.maximum(0, np.round(y -(0.114*1.772*(u-128) +0.299*1.402*(v-128))/0.587)), 255).astype(int)
    b = np.minimum(np.maximum(0, np.round(y        +1.772*(u-128)                            )), 255).astype(int)
    return r, g, b

