import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer

import numpy as np
import cv2

from queue import Queue
import os, sys

import jcommon
from jcommon import psnr, rmse

np.set_printoptions(suppress=True, precision=3)
np.random.seed(0)


def initialize_ports(dut):
    dut.rgb24_valid.value = 0
    dut.frame_valid_in.value = 0
    dut.line_valid_in.value = 0
    dut.di_hold.value = 0


class TesterJISP:
    def __init__(self, dut, img_file=None):
        self.dut = dut
        self.q_rgb_in = Queue()
        self.q_yuv_ref = Queue()
        self.q_yuv_out = Queue()
        self.q_yuv420_ref = Queue()
        self.q_yuv420_out = Queue()
        self.q_yuv8x8 = Queue()
        if (img_file is not None):
            self.ld_img(img_file)


    def ld_img(self, img_file):
        #self.img_bgr = cv2.imread(img_file)[664:664+720,1176:1176+720,:]
        self.img_bgr = cv2.imread(img_file)
        
        # Create some synthetic image
        # try {2,4,8,10,12,14}x136
        self.img_bgr = np.empty((48,48,3), dtype=np.uint8)
        for j in range(self.img_bgr.shape[0]):
            self.img_bgr[j,:,0] = 200*j/(self.img_bgr.shape[0]-1)
        for j in range(self.img_bgr.shape[1]):
            self.img_bgr[:,j,2] = 200*j/(self.img_bgr.shape[1]-1)
            self.img_bgr[:,j,1] = 200*(self.img_bgr.shape[1]-1-j)/(self.img_bgr.shape[1]-1)
        
        # get size
        self.y_size, self.x_size = self.img_bgr[:,:,0].shape
      
        self.x_size16 = 16*((self.x_size+15)//16)
        self.y_size16 = 16*((self.y_size+15)//16)

        # RGB (order = BGR)
        self.simg_bgr = cv2.split(self.img_bgr)

        # YCbCr (order = YCrCb)
        self.img_yvu = cv2.cvtColor(self.img_bgr, cv2.COLOR_BGR2YCrCb)
        self.simg_yvu = cv2.split(self.img_yvu)

        # YCbCr (order = YCrCb) 420
        #res = cv2.resize(img, None, fx=0.2, fy=0.2, interpolation = cv2.INTER_CUBIC)
        self.simg_yvu420 = [i.astype(np.uint16) for i in self.simg_yvu[:]]
        for i in range(1,3):
            self.simg_yvu420[i][::2,::2] = (self.simg_yvu420[i][::2,::2] + self.simg_yvu420[i][1::2,::2] + self.simg_yvu420[i][::2,1::2] + self.simg_yvu420[i][1::2,1::2] + 2)//4
            self.simg_yvu420[i] = self.simg_yvu420[i][::2,::2].astype(np.uint8)

        if False:
            cv2.imshow(img_file + str(self.img_bgr[:,:,0].shape), self.img_bgr)
            cv2.waitKey(0) 
            cv2.destroyAllWindows()

        
    def send_img(self, img_file=None):
        if (img_file is not None):
            self.ld_img(img_file)
        for y in range(self.y_size):
            for x in range(self.x_size):
                self.q_rgb_in.put(((x, y), self.img_bgr[y,x,:]), block=False)
                self.q_yuv_ref.put(self.img_yvu[y,x,:], block=False)
                
                if x%2==1 and y%2==1:
                    d = [self.simg_yvu420[0][y,x], self.simg_yvu420[1][y//2,x//2], self.simg_yvu420[2][y//2,x//2]]
                else:
                    d = [self.simg_yvu420[0][y,x], 0, 0]
                self.q_yuv420_ref.put(d, block=False)
                
 
    async def collect_yuv(self):
        """Collect output from pipe and but onto output queue qo"""
        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.rgb2yuv.yuv_valid.value==1 and self.dut.rgb2yuv.yuv_hold.value==0:
                yuv = [self.dut.rgb2yuv.yuv[i].value.integer for i in [0,2,1]]
                self.q_yuv_out.put(np.array(yuv))

            if self.dut.subsample.yuvrgb_out_valid.value[2] and self.dut.subsample.yuvrgb_out_hold.value==0:
                yuv = [self.dut.subsample.yuvrgb_out[0].value.integer, 0, 0]
                if self.dut.subsample.yuvrgb_out_valid.value[1]:
                    yuv[1] = self.dut.subsample.yuvrgb_out[2].value.integer
                    yuv[2] = self.dut.subsample.yuvrgb_out[1].value.integer
                self.q_yuv420_out.put(np.array(yuv))

            if self.dut.mcu_buffer.di_valid.value and not self.dut.mcu_buffer.di_hold.value:
                di = [(i.integer + 128)%256 for i in self.dut.mcu_buffer.di.value][::-1]
                self.q_yuv8x8.put(di)

    async def check_yuv(self):
        v = 0
        w = 0
        while True:
            await RisingEdge(self.dut.clk)
            if not self.q_yuv_out.empty():
                out = self.q_yuv_out.get(block=False)
                ref = self.q_yuv_ref.get(block=False)
                if rmse(out, ref) > 1:
                    e = f'ERROR in pixel # {v}: Expected={ref},  Received={out}'
                    raise Exception(e)
                v += 1

            if not self.q_yuv420_out.empty():
                out = self.q_yuv420_out.get(block=False)
                ref = self.q_yuv420_ref.get(block=False)
                if rmse(out, ref) > 1:
                    e = f'ERROR in pixel # {w}: Expected={ref},  Received={out}'
                    print(e)
                    raise Exception(e)
                w += 1

            if len(self.q_yuv8x8.queue) == self.x_size16 * self.y_size16 * 3//(2 * 8):
                u = 0
                s1 = (self.y_size16, self.x_size16)
                s2 = [i//2 for i in s1] #(self.y_size16//2, self.x_size16//2)
                tmp = [np.zeros(s1, dtype=np.uint8), np.zeros(s2, dtype=np.uint8), np.zeros(s2, dtype=np.uint8)]

                for i in range(self.y_size16//16):
                    for j in range(self.x_size16//16):
                        for k in range(4):
                            for l in range(8):
                                out = self.q_yuv8x8.get(block=False)
                                y = 16*i + 8*(k//2) + l
                                x = 16*j  + 8*(k%2)
                                tmp[0][y, x:x+8] =  out
                        for c in range(2,0,-1):
                            for k in range(1):
                                for l in range(8):
                                    out = self.q_yuv8x8.get(block=False)
                                    y = 8*i + l
                                    x = 8*j
                                    tmp[c][y, x:x+8] =  out

                # Resize 16x16 aligned to original image size
                tmp[0] = tmp[0][:self.y_size,:self.x_size]
                for c in range(1,3):
                    tmp[c] = tmp[c][:self.y_size//2,:self.x_size//2]
                                
                # Resize 4:2:0 to 4:4:4
                for c in range(1,3):
                    tmp[c] = cv2.resize(tmp[c], dsize=(self.x_size, self.y_size), interpolation=cv2.INTER_LINEAR)

                # Convert YCbCr to BGR
                bgr = cv2.cvtColor(cv2.merge(tmp), code=cv2.COLOR_YCrCb2BGR)
                
                if True:
                    cv2.imshow('Original', self.img_bgr)
                    cv2.imshow('Received', bgr)
                    cv2.waitKey(0) 
                    cv2.destroyAllWindows()
                    
                #print('PSNR =', psnr(1.0*bgr.flatten() , 1.0*self.img_bgr.flatten()))
                #print('RMSE =', rmse(1.0*bgr.flatten() , 1.0*self.img_bgr.flatten()))


    async def inject(self):
        self.dut.x_size_m1.value = self.x_size - 1
        self.dut.y_size_m1.value = self.y_size - 1
        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.resetn.value == 1 and not self.q_rgb_in.empty():
                self.dut.frame_valid_in.value = 1
                self.dut.line_valid_in.value = 1
                self.dut.rgb24_valid.value = 1
                ((x, y), (b, g, r)) = self.q_rgb_in.get(block=False)
                for i, c in enumerate([r, g, b]):
                    self.dut.rgb24[i].value = c.item()
                while self.dut.rgb24_hold.value:
                    await RisingEdge(self.dut.clk)
                if x == self.x_size - 1:
                    await RisingEdge(self.dut.clk)
                    self.dut.line_valid_in.value = 0
                    self.dut.rgb24_valid.value = 0
                    if y == self.y_size - 1:
                        self.dut.frame_valid_in.value = 0
                    while self.dut.rgb24_hold.value:
                        await RisingEdge(self.dut.clk)
            else:
                self.dut.rgb24_valid.value = 0
    

@cocotb.test()
async def test_jisp(dut):
    initialize_ports(dut)
    cocotb.start_soon(jcommon.clock_n_reset(dut))
    cocotb.start_soon(jcommon.finishn(dut, 2500))

    t = TesterJISP(dut, 'DeltaE_8bit_gamma2.2.tif')
    cocotb.start_soon(t.inject())
    cocotb.start_soon(t.collect_yuv())
    cocotb.start_soon(t.check_yuv())

    
    await RisingEdge(dut.resetn)
    await RisingEdge(dut.clk)

    t.send_img()
    await ClockCycles(dut.clk, 250)
    t.send_img()

    await ClockCycles(dut.clk, 25000)
