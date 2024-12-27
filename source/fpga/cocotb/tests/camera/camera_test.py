#
# Authored by: Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#
import sys, os, time, random, logging
import numpy as np
if os.environ['SIM'] != 'modelsim':
    import cv2

import cocotb
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer

from tb_top import SpiTransactor, clock_n_reset, show_image
from encoder import writeJPG_header, writeJPG_footer    # ../jed


np.set_printoptions(suppress=True, precision=3)
np.random.seed(0)

class JpegTester():
    def __init__(self, dut, spi, img_file='baboon.bmp', qf=50, read_bmp=True, save_bmp_to_array=False):
        self.dut = dut
        self.spi = spi
        self.jpeg_sel = 1
        self.qf = qf

        # initialize sensor BFM
        if os.environ['SIM'] != 'modelsim':
            self.dut.pixel_lv.value = 0
            self.dut.pixel_fv.value = 0

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
        # 1. Set compression factor
        qf_select = {int(os.environ.get(f'QF{i}', q)): i for i, q in enumerate([50, 100, 10, 25,   20, 30, 40, 80])}[self.qf]
        await self.spi.spi_write(0x26, qf_select)

        if os.environ.get('GAMMA_BYPASS', '') == '1':
            await self.spi.spi_write(0x32, 1)

        size = int(os.environ.get("IMAGE_X_SIZE", 512))
        if not size == 512:
            await self.spi.spi_write(0x23, [size >> 8, size & 0xFF])

        # kick off capture flag
        await self.spi.spi_command(0x20)

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
            [image_ready_flag] = await self.spi.spi_read(0x30)
            if image_ready_flag != 0:
                    break
            # poll less over SPI to speed up sim
            await Timer(100, units='us')

        # power down PLL and D-PHY, read out image buffer using SPI clock
        if os.environ.get('SPI_CLOCK_READOUT', 1) == 1:
            await self.spi.spi_write(0x40, 0x3)         # Switch image buffer clock to SPI clock 0x40
            await self.spi.spi_write(0x40, 0x2)         # Power down PLL - PLL_CSR 0x40
            await self.spi.spi_write(0x28, 0x1)         # Set D-PHY POWER_SAVE_ENABLE 0x28 in camera registers

        # read size in bytes
        read_data = await self.spi.spi_read(0x31, 2)
        bytes = sum([v << (i*8) for i,v in enumerate(read_data)])
        self.dut._log.info(f"ECS size = {bytes} bytes")

        if os.environ.get('SINGLE_SPI_READS', 0) == 0:
            self.ecs = await self.spi.spi_read(0x22, bytes)
        else:
            self.ecs = []
            for _ in range(bytes):
                ecs = await self.spi.spi_read(0x22, 1)
                self.ecs.extend(ecs)


    async def write_image(self, jfilename='jpeg_out.jpg', efilename='ecs_out.bin'):
        await self.write_jpg(jfilename)
        await self.write_ecs(efilename)


    async def write_ecs(self, filename='ecs_out.bin'):
        # Write bytes to file
        with open(filename, "wb") as f:
            f.write(bytearray(self.ecs))


    async def write_jpg(self, filename='jpeg_out.jpg'):
        hdr = bytearray(writeJPG_header(height=self.y, width=self.x, qf=self.qf))
        ecs = bytearray(self.ecs)
        ftr = bytearray(writeJPG_footer())

        # Write bytes to file
        with open(filename, "wb") as f:
            f.write(hdr)
            f.write(ecs)
            f.write(ftr)



@cocotb.test()
async def jpeg_test(dut):
    log_level = os.environ.get('LOG_LEVEL', 'INFO') # NOTSET=0 DEBUG=10 INFO=20 WARN=30 ERROR=40 CRITICAL=50
    dut._log.setLevel(log_level)

    # SPI Transactor
    spi = SpiTransactor(dut)

    # Start camera clock
    cr = cocotb.start_soon(clock_n_reset(dut.camera_pixel_clock, None, f=36.0*10e6))       # 36 MHz clock  

    # Hack/Fix for missing "negedge reset" in verilator, works OK in icarus
    await Timer(10, 'ns')
    dut.spi_select_in.value = 0
    await Timer(10, 'ns')
    dut.spi_select_in.value = 1
    await Timer(10, 'ns')


    test_image = 'baboon.bmp'  # 256x256
    #test_image = '4.2.07.tiff'  # peppers 512x512
    #test_image = '4.2.03.tiff'  # baboon 512x512

    test_image = '../../images/' + test_image;
    qf = int(os.environ.get('QF', 50))
    
    # Add jpeg tester
    t = JpegTester(dut, spi, test_image, qf=qf, read_bmp=False)

    # Wait for PLL to power up, lock & global reset
    await Timer(10, units='us')
    await spi.spi_write(0x40, 0x1)      # PLL_CSR - power up PLL
    await spi.spi_write(0x28, 0x0)      # Camera registers - clear POWER_SAVE_ENABLE
    await Timer(20, units='us')
    pll_lock = await spi.spi_read(0x41)
    assert pll_lock == [1]


    # Send a few non capture dummy frames
    for _ in range(2):
        bayer  = cocotb.start_soon(t.send_bayer())
        await cocotb.triggers.Combine(bayer)  # wait for frame end

    # Set up encoder
    t.jpeg_sel = 1 #int(os.environ['JPEG_SEL'])
    await t.initialize()

    # Send capture frame
    bayer  = cocotb.start_soon(t.send_bayer())

    # Read image when ready
    await t.read_image_buffer()
    await t.write_image()

    await show_image(test_image, 'jpeg_out.jpg')
    await cocotb.triggers.Combine(bayer)  # wait for frame end


    # Finish
    await Timer(10, units='us')
