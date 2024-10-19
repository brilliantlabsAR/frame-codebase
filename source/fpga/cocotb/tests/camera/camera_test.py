#
# Authored by: Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#
import sys, os, time, random, logging
import numpy as np

import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer

from tb_top import SpiTransactor, clock_n_reset


class JpegTester():
    def __init__(self, dut, spi, img_file='baboon.bmp', qf=50, read_bmp=True, save_bmp_to_array=False):
        self.dut = dut
        self.spi = spi
        self.jpeg_sel = 1
        self.qf = qf
        
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
            orig = self.img_bgr[:,:,:]
            self.img_bgr[:, :, :] = 0
            self.img_bgr[9:, 9:, 0] = 255 # blue right bottom corner
            self.img_bgr[:9, :, 2] = 255 # red top
            self.img_bgr[:, :9, 1] = 255 # green left
            #self.img_bgr[:, :, :] = np.random.randint(0, 256, self.img_bgr.shape)
            #self.img_bgr[:, 175:, :] = 128
            #self.img_bgr[:, :, :] = 128

        # make bayer
        self.img_bayer = np.empty((self.y, self.x), dtype=np.uint8)        
        self.img_bayer[0::2, 0::2] = 0 + self.img_bgr[0::2, 0::2, 0] # top left B
        self.img_bayer[0::2, 1::2] = 0 + self.img_bgr[0::2, 1::2, 1] # top right G
        self.img_bayer[1::2, 0::2] = 0 + self.img_bgr[1::2, 0::2, 1] # bottom left G
        self.img_bayer[1::2, 1::2] = 0 + self.img_bgr[1::2, 1::2, 2] # bottom right R

        if False:
            self.img_bayer = self.img_bayer[0:, 180:]
            self.img_bgr = self.img_bgr[0:, 180:, :]

        #self.y = int(os.environ.get('SENSOR_Y_SIZE', 768))
        #self.x = int(os.environ.get('SENSOR_X_SIZE', 1288))
        self.y = int(os.environ.get('SENSOR_Y_SIZE', 204))
        self.x = int(os.environ.get('SENSOR_X_SIZE', 204))
        self.img_bayer = self.img_bayer[:self.y, :self.x]
        self.y = int(os.environ.get('IMAGE_Y_SIZE', 200))
        self.x = int(os.environ.get('IMAGE_X_SIZE', 200))

        #orig = self.img_bgr[1:, 1:, :]; cv2.imwrite('orig.bmp', orig[:self.y, :self.x, :])

        #cv2.imshow(img_file, self.img_bayer)
        #cv2.waitKey(0) 
        #cv2.destroyAllWindows()
        #print(self.img_bayer[:8,:8])


    async def initialize(self):
        """ Initialize Jpeg core"""
        # 1. Set compression factor and kick off capture flag
        qf_select = {int(os.environ.get(f'QF{i}', q)): i for i, q in enumerate([50, 100, 10, 25])}[self.qf]
        await self.spi.spi_write(0x26, qf_select)
        await self.spi.spi_write(0x20, 1)


    async def send_bayer(self):
	    # send RGB
        await RisingEdge(self.dut.camera_pixel_clock)
        self.dut.pixel_fv.value = 1
        await ClockCycles(self.dut.camera_pixel_clock, 300)

        self.dut._log.debug("******** Frame")
        for l, line in enumerate(self.img_bayer):
            self.dut._log.debug(f"         Line={l}")
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
            [read_data] = await self.spi.spi_read(0x30)
            if read_data != 0:
                read_data = await self.spi.spi_read(0x30)
                if read_data != 0:
                    break
        return
        # read address -> need to add 4 to get size in bytes
        read_data = await self.spi_write_read(0x31, *[0xff]*2)
        bytes = 4 + sum([v*(2**(i*8)) for i,v in enumerate(read_data)])

        self.dut._log.debug(f"******** Compressed bytes={bytes}")
        if True:
            self.ecs = await self.spi_write_read(0x22, *[0xff]*bytes)
        else:
            self.ecs = []
            for _ in range(bytes):
                ecs = await self.spi_write_read(0x22, 0xff)
                self.ecs.extend(ecs)


@cocotb.test()
async def jpeg_test(dut):
    log_level = os.environ.get('LOG_LEVEL', 'INFO') # NOTSET=0 DEBUG=10 INFO=20 WARN=30 ERROR=40 CRITICAL=50
    dut._log.setLevel(log_level)

    # Hack/Fix for missing "negedge reset" in verilator, works OK in icarus
    dut.spi_select_in.value = 0
    await Timer(1, 'ps')

    # SPI Transactor
    spi = SpiTransactor(dut)

    # Start camera clock
    cr = cocotb.start_soon(clock_n_reset(dut.camera_pixel_clock, None, f=36.0*10e6))       # 36 MHz clock

    test_image = 'baboon.bmp'  # 256x256
    #test_image = '4.2.07.tiff'  # peppers 512x512
    #test_image = '4.2.03.tiff'  # baboon 512x512

    test_image = '../../images/' + test_image;
    qf = int(os.environ.get('QF', 50))
    
    # Add jpeg tester
    t = JpegTester(dut, spi, test_image, qf=qf, read_bmp=False)

    # Wait for PLL to power up, lock & global reset
    await spi.spi_write(0x40, 0x1)
    await Timer(20, units='us')
    pll_lock = await spi.spi_read(0x41)
    assert pll_lock == [1]

    for _ in range(1):
        for _ in range(2):
            # send a few non capture frames
            bayer  = cocotb.start_soon(t.send_bayer())   
            await cocotb.triggers.Combine(bayer)  # wait for frame end

        # send capture frame
        t.jpeg_sel = 1 #int(os.environ['JPEG_SEL'])

        await t.initialize()    
        bayer  = cocotb.start_soon(t.send_bayer())   

        await t.read_image_buffer()


    # Finish
    await Timer(10, units='us')
