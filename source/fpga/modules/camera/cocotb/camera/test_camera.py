#
# Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
import sys, os, time, random

import numpy as np

if os.environ['SIM'] != 'modelsim':
    import cv2

from encoder import writeJPG_header, writeJPG_footer    # ../jed

np.set_printoptions(suppress=True, precision=3)
np.random.seed(0)

    

def initialize_ports(dut):
    """Only control ports get initialized"""
    dut.pixel_fv.value = 0
    dut.pixel_lv.value = 0
    dut.pixel_data.value = 0

    dut.spi_select_in.value = 1
    dut.spi_data_in.value = 0
    dut.spi_clock_in.value = 0


async def clock_n_reset(c, r, f, n=5):
    if r is not None:
        r.value = 0
    period = round(10e9/f, 2) # in ns
    cocotb.start_soon(Clock(c, period, units="ns").start())
    await ClockCycles(c, n)
    if r is not None:
        r.value = 1
 

async def show_image(*img_files, t=5000):
    if os.environ['SIM'] != 'modelsim':
        for img_file in img_files:
            cv2.imshow(img_file, cv2.imread(img_file))
        cv2.waitKey(t) 
        cv2.destroyAllWindows()


class SPITransactor():
    def __init__(self, dut):
        self.dut = dut


    async def spi_write_read(self, op_code, *operands):
        if len(operands) == 0:
            operands = [0]
        data_recvd = [0]*len(operands)

        await FallingEdge(self.dut.cpu_clock_8hmz)
        self.dut.spi_select_in.value = 0

        await RisingEdge(self.dut.cpu_clock_8hmz)
        for i in range(8)[::-1]:
            self.dut.spi_data_in.value = (op_code >> i) & 0x1
            self.dut.spi_clock_in.value = 1
            await FallingEdge(self.dut.cpu_clock_8hmz)
            self.dut.spi_clock_in.value = 0
            await RisingEdge(self.dut.cpu_clock_8hmz)
        for j, operand in enumerate(operands):
            for i in range(8)[::-1]:
                self.dut.spi_data_in.value = (operand >> i) & 0x1
                self.dut.spi_clock_in.value = 1
                data_recvd[j] |= (self.dut.spi_data_out.value << i)
                await FallingEdge(self.dut.cpu_clock_8hmz)
                self.dut.spi_clock_in.value = 0
                await RisingEdge(self.dut.cpu_clock_8hmz)
        self.dut.spi_data_in.value = 0
        self.dut.spi_select_in.value = 1
        return data_recvd


class Tester(SPITransactor):
    def __init__(self, dut, img_file='baboon.bmp', read_bmp=True, save_bmp_to_array=False):
        super(Tester, self).__init__(dut)
        self.dut = dut
        self.jpeg_sel = 1
        
        # Always Read RGB image
        if read_bmp and os.environ['SIM'] != 'modelsim':
            self.img_bgr = cv2.imread(img_file)
            if save_bmp_to_array:
                with open(img_file + '.npy', 'wb') as f:
                    np.save(f, self.img_bgr)
        else:
            with open(img_file + '.npy', 'rb') as f:
                self.img_bgr = np.load(f)

        # Makse sure at least 1288x768
        self.img_bgr = np.vstack([self.img_bgr] * np.ceil(768/np.shape(self.img_bgr)[0]).astype(int))
        self.img_bgr = np.hstack([self.img_bgr] * np.ceil(1288/np.shape(self.img_bgr)[1]).astype(int))
        
        self.y, self.x, _ = np.shape(self.img_bgr)
        assert self.y%2 == 0
        assert self.x%2 == 0
        
        # artificial test image
        if False:
            self.img_bgr[:, :, :] = 0
            self.img_bgr[8:, 8:, 0] = 255 # blue right bottom corner
            self.img_bgr[:8, :, 2] = 255 # red top
            self.img_bgr[:, :8, 1] = 255 # green left
            #self.img_bgr[:, :, :] = np.random.randint(0, 256, self.img_bgr.shape)

        # make bayer
        self.img_bayer = np.empty((self.y, self.x), dtype=np.uint8)        
        self.img_bayer[0::2, 0::2] = 0 + self.img_bgr[0::2, 0::2, 0] # top left B
        self.img_bayer[0::2, 1::2] = 0 + self.img_bgr[0::2, 1::2, 1] # top right G
        self.img_bayer[1::2, 0::2] = 0 + self.img_bgr[1::2, 0::2, 1] # bottom left G
        self.img_bayer[1::2, 1::2] = 0 + self.img_bgr[1::2, 1::2, 2] # bottom right R

        if False:
            self.img_bayer = self.img_bayer[0:, 180:]
            self.img_bgr = self.img_bgr[0:, 180:, :]

        self.y = int(os.environ.get('SENSOR_Y_SIZE', 768))
        self.x = int(os.environ.get('SENSOR_X_SIZE', 1288))
        self.img_bayer = self.img_bayer[:self.y, :self.x]
        self.y = int(os.environ.get('IMAGE_Y_SIZE', 200))
        self.x = int(os.environ.get('IMAGE_X_SIZE', 200))

        #orig = self.img_bgr[1:, 1:, :]; cv2.imwrite('orig.bmp', orig[:self.y, :self.x, :])

        #cv2.imshow(img_file, self.img_bayer)
        #cv2.waitKey(0) 
        #cv2.destroyAllWindows()
        #print(self.img_bayer[:8,:8])
    
    async def initialize(self):
        await RisingEdge(self.dut.cpu_clock_8hmz)
        # Capture flag
        await self.spi_write_read(0x20)
    
    async def send_bayer(self):
	    # send RGB
        await RisingEdge(self.dut.camera_pixel_clock)
        self.dut.pixel_fv.value = 1
        await ClockCycles(self.dut.camera_pixel_clock, 300)

        for line in self.img_bayer:
            await ClockCycles(self.dut.camera_pixel_clock, 300)
            self.dut.pixel_lv.value = 1
            for pix in line:

                self.dut.pixel_data.value = 4 * int(pix)
                await RisingEdge(self.dut.camera_pixel_clock)
            self.dut.pixel_lv.value = 0
            # Horizontal blanking requirement:
            #   horizontal-blanking > ceil(X-dimension/128)
            #   1 clock added above, so blank = ceil(X-dimension/128) satisfies this requirement
            #blank = (self.x + 127)//128
            
            await ClockCycles(self.dut.camera_pixel_clock, 300)
        self.dut.pixel_fv.value = 0
        await ClockCycles(self.dut.camera_pixel_clock, 300)


    async def read_image_buffer(self):
        # poll image complete
        while True:
            [read_data] = await self.spi_write_read(0x30, 0xff)
            if read_data != 0:
                read_data = await self.spi_write_read(0x30, 0xff)
                if read_data != 0:
                    break

        # read address -> need to add 4 to get size in bytes
        read_data = await self.spi_write_read(0x31, *[0xff]*3)
        bytes = 4 + sum([v*(2**(i*8)) for i,v in enumerate(read_data)])
        print(bytes)

        self.ecs = []
        for _ in range(bytes):
            ecs = await self.spi_write_read(0x22, 0xff)
            self.ecs.extend(ecs)


    async def write_ecs(self, filename='ecs_out.bin'):
        # Write bytes to file
        with open(filename, "wb") as f:
            f.write(bytearray(self.ecs))


    async def write_jpg(self, filename='jpeg_out.jpg'):
        hdr = bytearray(writeJPG_header(height=self.y, width=self.x))
        ecs = bytearray(self.ecs)
        ftr = bytearray(writeJPG_footer())

        # Write bytes to file
        with open(filename, "wb") as f:
            f.write(hdr)
            f.write(ecs)
            f.write(ftr)


    async def write_image(self):
        await self.write_jpg()
        await self.write_ecs()


@cocotb.test()
async def dct_test(dut):
    initialize_ports(dut)

    clk_op = cocotb.start_soon(clock_n_reset(dut.camera_pixel_clock, None, f=36.0*10e6))       # 36 MHz clock
    clk_os = cocotb.start_soon(clock_n_reset(dut.cpu_clock_8hmz, None, f=8*10e6))  # 8 MHz clock
    await cocotb.triggers.Combine(clk_op, clk_os)

    test_image = 'baboon.bmp'  # 256x256
    #test_image = '4.2.07.tiff'  # peppers 512x512
    #test_image = '4.2.03.tiff'  # baboon 512x512
    
    test_image = '../images/' + test_image;
    t = Tester(dut, test_image, read_bmp=False)

    #// Wait for reset, 1 frame of 76x76 to end
    #delay_us('d1250);
    await Timer(12.5, units='us')

    for _ in range(1):
        for _ in range(2):
            # send non capture frame
            bayer  = cocotb.start_soon(t.send_bayer())   
            await cocotb.triggers.Combine(bayer)  # wait for frame end


        # send capture frame
        t.jpeg_sel = 1 #int(os.environ['JPEG_SEL'])

        await t.initialize()    
        bayer  = cocotb.start_soon(t.send_bayer())   

        await t.read_image_buffer()
        await t.write_image()
    
        await show_image(test_image, 'jpeg_out.jpg' if t.jpeg_sel else 'rgb_out.bmp', t=0)

        await cocotb.triggers.Combine(bayer)  # wait for frame end
    await ClockCycles(dut.cpu_clock_8hmz, 100)
