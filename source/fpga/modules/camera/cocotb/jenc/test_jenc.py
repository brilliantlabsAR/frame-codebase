import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
import sys, os, time

import numpy as np
import cv2

from encoder import writeJPG_header, writeJPG_footer    # ../jed

np.set_printoptions(suppress=True, precision=3)
np.random.seed(0)

    

def initialize_ports(dut):
    """Only control ports get initialized"""
    dut.debayered_line_valid.value = 0
    dut.debayered_frame_valid.value = 0

    dut.jpeg_sel.value = 0
    dut.jpeg_out_size_clear.value = 0
    dut.jpeg_reset.value = 0


async def clock_n_reset(c, r, f, n=5):
    r.value = 0
    period = round(10e9/f, 2) # in ns
    cocotb.start_soon(Clock(c, period, units="ns").start())
    await ClockCycles(c, n)
    r.value = 1
 

async def show_image(*img_files, t=5000):
    for img_file in img_files:
        cv2.imshow(img_file, cv2.imread(img_file))
    cv2.waitKey(t) 
    cv2.destroyAllWindows()


class Tester():
    def __init__(self, dut, img_file='baboon.bmp'):
        self.dut = dut
        self.img_bgr = cv2.imread(img_file)

        self.y, self.x, _ = np.shape(self.img_bgr)
        assert self.y%2 == 0
        assert self.x%2 == 0
        self.jpeg_sel = 0

    
    async def initialize_encoder(self):
        await RisingEdge(self.dut.clock_spi_in)

        #configure image size
        self.dut.y_size_m1.value = self.y - 1
        self.dut.x_size_m1.value = self.x - 1

    	# enable encoder
        self.jpeg_sel = 1
        self.dut.jpeg_sel.value = self.jpeg_sel

    	# reset encoder
        self.dut.jpeg_reset.value = 1
        await RisingEdge(self.dut.clock_spi_in)
        self.dut.jpeg_reset.value = 0
        await RisingEdge(self.dut.jpeg_reset_n)
    
        #improved debug
        self.dut.buffer_read_address.value = -1
    

    async def send_rgb(self):
	    # send RGB
        await RisingEdge(self.dut.clock_pixel_in)
        for line in self.img_bgr:
            await RisingEdge(self.dut.clock_pixel_in)
            for pix in line:
                self.dut.debayered_frame_valid.value = 1
                self.dut.debayered_line_valid.value = 1

                self.dut.debayered_red_data.value = 4 * int(pix[2])
                self.dut.debayered_green_data.value = 4 * int(pix[1])
                self.dut.debayered_blue_data.value = 4 * int(pix[0])
                await RisingEdge(self.dut.clock_pixel_in)
            self.dut.debayered_line_valid.value = 0
            # Horizontal blanking requirement:
            #   horizontal-blanking > ceil(X-dimension/128)
            #   1 clock added above, so blank = ceil(X-dimension/128) satisfies this requirement
            blank = (self.x + 127)//128
            
            await ClockCycles(self.dut.clock_pixel_in, blank)
        self.dut.debayered_frame_valid.value = 0


    async def read_rgb_buffer(self):
        await FallingEdge(self.dut.rgb_cdc.frame_valid)
        await RisingEdge(self.dut.clock_spi_in)

        bytes = self.y * self.x
        bgr_out = []
        for self.dut.buffer_read_address.value in range(bytes):
            await RisingEdge(self.dut.clock_spi_in)
            await RisingEdge(self.dut.clock_spi_in)
            pix = self.dut.buffer_read_data.value.integer
            r = 32*((pix>>5) & 7)
            g = 32*((pix>>2) & 7)
            b = 64*(pix & 3)
            bgr_out.append([b, g, r])

        self.bgr_out = np.array(bgr_out, dtype=np.uint8).reshape(self.y, self.x, 3)
        

    async def read_jpeg_buffer(self):
        # poll size
        while True:
            await RisingEdge(self.dut.clock_spi_in)
            bytes = self.dut.jpeg_out_size.value.integer
            if bytes != 0:
                break

        self.dut.jpeg_out_size_clear.value = 1

        self.ecs = []
        for self.dut.buffer_read_address.value in range(bytes):
            await RisingEdge(self.dut.clock_spi_in)
            await RisingEdge(self.dut.clock_spi_in)
            self.ecs.append(self.dut.buffer_read_data.value.integer)
            #print (self.dut.buffer_read_address.value.integer, hex(self.dut.buffer_read_data.value.integer))

        self.dut.jpeg_out_size_clear.value = 0


    async def read_image_buffer(self):
        if self.jpeg_sel:
            await self.read_jpeg_buffer()
        else:
            await self.read_rgb_buffer()


    async def write_jpg(self, filename='jpeg_out.jpg'):
        hdr = bytearray(writeJPG_header(height=self.y, width=self.x))
        ecs = bytearray(self.ecs)
        ftr = bytearray(writeJPG_footer())

        # Write bytes to file
        with open(filename, "wb") as f:
            f.write(hdr)
            f.write(ecs)
            f.write(ftr)


    async def write_bmp(self, filename='rgb_out.bmp'):
        #cv2.imwrite(img_file + '.orig.bmp', self.img_bgr)
        #import imageio; imageio.imwrite('file_name.jpg', self.img_bgr[:,:,[2,1,0]])
        cv2.imwrite(filename, self.bgr_out)    


    async def write_image(self):
        if self.jpeg_sel:
            await self.write_jpg()
        else:
            await self.write_bmp()


@cocotb.test()
async def dct_test(dut):
    initialize_ports(dut)

    c1 = cocotb.start_soon(clock_n_reset(dut.clock_spi_in, dut.reset_spi_n_in, f=1.02 * 72*10e6)) # 72 MHz clock
    c0 = cocotb.start_soon(clock_n_reset(dut.clock_pixel_in, dut.reset_pixel_n_in, f=0.98 * 36*10e6)) # 36 MHz clock
    await cocotb.triggers.Combine(c1, c0)
    
    await ClockCycles(dut.clock_spi_in, 2)

    test_image = 'baboon.bmp'
    t = Tester(dut, test_image)

    await t.initialize_encoder()    
    cocotb.start_soon(t.send_rgb())   

    await t.read_image_buffer()
    await t.write_image()
    
    await show_image(test_image, 'jpeg_out.jpg' if t.jpeg_sel else 'rgb_out.bmp', t=0)

    await ClockCycles(dut.clock_spi_in, 10000)  # wait for falling edge/"negedge"
