import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
import sys, os, time

import numpy as np

if os.environ['SIM'] != 'modelsim':
    import cv2

from encoder import writeJPG_header, writeJPG_footer    # ../jed

np.set_printoptions(suppress=True, precision=3)
np.random.seed(0)

    

def initialize_ports(dut):
    """Only control ports get initialized"""
    dut.byte_to_pixel_frame_valid.value = 0
    dut.byte_to_pixel_line_valid.value = 0

    dut.op_code_valid_in.value = 0
    dut.operand_valid_in.value = 0



async def clock_n_reset(c, r, f, n=5):
    r.value = 0
    period = round(10e9/f, 2) # in ns
    cocotb.start_soon(Clock(c, period, units="ns").start())
    await ClockCycles(c, n)
    r.value = 1
 

async def show_image(*img_files, t=5000):
    if os.environ['SIM'] != 'modelsim':
        for img_file in img_files:
            cv2.imshow(img_file, cv2.imread(img_file))
        cv2.waitKey(t) 
        cv2.destroyAllWindows()


class SPITransactor():
    def __init__(self, dut):
        self.regs = [0] * 256
        self.dut = dut


    async def spi_write(self, op_code, *operands):
        if len(operands) == 0:
        	operands = [0]
        await RisingEdge(self.dut.clock_spi_in)
        for i, operand in enumerate(operands):
            self.dut.operand_valid_in.value = 1
            self.dut.op_code_valid_in.value = 1
            self.dut.op_code_in.value = op_code + i
            self.dut.operand_in.value = operand
            self.regs[op_code + i] = operand    # store in memory

            await RisingEdge(self.dut.clock_spi_in)
            self.dut.operand_valid_in.value = 0
            self.dut.op_code_valid_in.value = 0


    async def spi_read(self, op_code, n=1):
        await RisingEdge(self.dut.clock_spi_in)
        for i in range(n):
            self.dut.operand_valid_in.value = 1
            self.dut.op_code_valid_in.value = 1
            self.dut.operand_count_in.value = i
            self.dut.op_code_in.value = op_code

            await RisingEdge(self.dut.clock_spi_in)
            self.dut.operand_valid_in.value = 0
            self.dut.op_code_valid_in.value = 0
            
            while self.dut.response_valid_out.value == 0:
                await RisingEdge(self.dut.clock_spi_in)
            self.regs[op_code + i] = self.dut.response_out.value.integer
        return self.regs[op_code:op_code + n]



class Tester(SPITransactor):
    def __init__(self, dut, img_file='baboon.bmp', read_bmp=True, save_bmp_to_array=False):
        super().__init__(dut)
        self.dut = dut
        self.jpeg_sel = 0
        
        # Always Read RGB image
        if read_bmp and os.environ['SIM'] != 'modelsim':
            self.img_bgr = cv2.imread(img_file)
            if save_bmp_to_array:
                with open(img_file + '.npy', 'wb') as f:
                    np.save(f, self.img_bgr)
        else:
            with open(img_file + '.npy', 'rb') as f:
                self.img_bgr = np.load(f)

        # Makse sure at least 720x720
        self.img_bgr = np.vstack([self.img_bgr] * np.ceil(720/np.shape(self.img_bgr)[0]).astype(int))
        self.img_bgr = np.hstack([self.img_bgr] * np.ceil(720/np.shape(self.img_bgr)[1]).astype(int))
        
        self.y, self.x, _ = np.shape(self.img_bgr)
        assert self.y%2 == 0
        assert self.x%2 == 0

        # make bayer
        self.img_bayer = np.empty((self.y, self.x), dtype=np.uint8)        
        self.img_bayer[0::2, 0::2] = 0 + self.img_bgr[0::2, 0::2, 0] # top left B
        self.img_bayer[0::2, 1::2] = 0 + self.img_bgr[0::2, 1::2, 1] # top right G
        self.img_bayer[1::2, 0::2] = 0 + self.img_bgr[1::2, 0::2, 1] # bottom left G
        self.img_bayer[1::2, 1::2] = 0 + self.img_bgr[1::2, 1::2, 2] # bottom right R

        self.y, self.x = 720, 720  # crop full sensor size
        self.img_bayer = self.img_bayer[:self.y,:self.x]
        self.y, self.x = 200, 200  # re-define jpeg image size

        self.y, self.x = 80, 80  # crop full sensor size
        self.img_bayer = self.img_bayer[:self.y,:self.x]
        self.y, self.x = 64, 64  # re-define jpeg image size

        #cv2.imshow(img_file, self.img_bayer)
        #cv2.waitKey(0) 
        #cv2.destroyAllWindows()
        #print(self.img_bayer[:8,:8])
    
    async def initialize_encoder(self):
        await RisingEdge(self.dut.clock_spi_in)

        #configure image size (FIXME)
        self.dut.X_CROP_START.value = 4
        self.dut.X_CROP_END.value =   4 + 2 + self.x
        self.dut.Y_CROP_START.value = 4
        self.dut.Y_CROP_END.value =   4 + 2 + self.y

    	# enable & reset encoder
        self.jpeg_sel = 1
        await self.spi_write(0x30, 0x4)
        # wait 16 cycles
        await ClockCycles(self.dut.clock_spi_in, 16)
        await self.spi_write(0x30, 0x9)
        await ClockCycles(self.dut.clock_spi_in, 16)
        
        # Capture flag
        await self.spi_write(0x20)
    
    

    async def send_bayer(self):
	    # send RGB
        await RisingEdge(self.dut.clock_pixel_in)
        for line in self.img_bayer:
            await RisingEdge(self.dut.clock_pixel_in)
            for pix in line:
                self.dut.byte_to_pixel_frame_valid.value = 1
                self.dut.byte_to_pixel_line_valid.value = 1

                self.dut.byte_to_pixel_data.value = 4 * int(pix)
                await RisingEdge(self.dut.clock_pixel_in)
            self.dut.byte_to_pixel_line_valid.value = 0
            # Horizontal blanking requirement:
            #   horizontal-blanking > ceil(X-dimension/128)
            #   1 clock added above, so blank = ceil(X-dimension/128) satisfies this requirement
            blank = (self.x + 127)//128
            
            await ClockCycles(self.dut.clock_pixel_in, blank)
        self.dut.byte_to_pixel_frame_valid.value = 0
        await ClockCycles(self.dut.clock_pixel_in, blank)


    async def read_rgb_buffer(self):
        await FallingEdge(self.dut.rgb_cdc.frame_valid)
        await RisingEdge(self.dut.clock_spi_in)

        bytes = self.y * self.x
        bgr_out = []

        for self.dut.bytes_read.value in range(bytes):
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
            await self.spi_read(0x31, 3)
            bytes = sum([v*(2**(i*8)) for i,v in enumerate(self.regs[0x31:0x31+3])])
            if bytes != 0:
                break
                
        # Read one more time to avoid race condition
        await self.spi_read(0x31, 3)
        bytes = sum([v*(2**(i*8)) for i,v in enumerate(self.regs[0x31:0x31+3])])

        self.ecs = []
        for i in range(bytes):
            await self.spi_read(0x22)
            self.ecs.append(self.regs[0x22])


        # jpeg_out_size_clear.value = 1
        await self.spi_write(0x30, 0x2)

        # wait 16 cycles
        await ClockCycles(self.dut.clock_spi_in, 16)

        # jpeg_out_size_clear.value = 0 + reset
        await self.spi_write(0x30, 0x4)


    async def read_image_buffer(self):
        if self.jpeg_sel:
            await self.read_jpeg_buffer()
        else:
            await self.read_rgb_buffer()


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


    async def write_bmp(self, filename='rgb_out.bmp'):
        #cv2.imwrite(img_file + '.orig.bmp', self.img_bgr)
        #import imageio; imageio.imwrite('file_name.jpg', self.img_bgr[:,:,[2,1,0]])
        if os.environ['SIM'] != 'modelsim':
            cv2.imwrite(filename, self.bgr_out)    


    async def write_image(self):
        if self.jpeg_sel:
            await self.write_jpg()
            await self.write_ecs()
        else:
            await self.write_bmp()


@cocotb.test()
async def dct_test(dut):
    initialize_ports(dut)

    c1 = cocotb.start_soon(clock_n_reset(dut.clock_spi_in, dut.reset_spi_n_in, f=1.02 * 72*10e6)) # 72 MHz clock
    c0 = cocotb.start_soon(clock_n_reset(dut.clock_pixel_in, dut.reset_pixel_n_in, f=0.98 * 36*10e6)) # 36 MHz clock
    c2 = cocotb.start_soon(clock_n_reset(dut.clk_x22, dut.resetn_x22, f=78*10e6)) # 78 MHz clock
    await cocotb.triggers.Combine(c0, c1, c2)
    
    await ClockCycles(dut.clock_spi_in, 2)

    test_image = 'baboon.bmp'  # 256x256
    test_image = '4.2.07.tiff'  # peppers 512x512
    #test_image = '4.2.03.tiff'  # baboon 512x512
    
    test_image = '../jenc/' + test_image;
    t = Tester(dut, test_image, read_bmp=False)

    for _ in range(1):
        if False:
            # send non capture frame
            bayer  = cocotb.start_soon(t.send_bayer())   
            await cocotb.triggers.Combine(bayer)  # wait for frame end


        # send capture frame
        await t.initialize_encoder()    
        bayer  = cocotb.start_soon(t.send_bayer())   

        await t.read_image_buffer()
        await t.write_image()
    
        await show_image(test_image, 'jpeg_out.jpg' if t.jpeg_sel else 'rgb_out.bmp', t=0)

        await cocotb.triggers.Combine(bayer)  # wait for frame end
    await ClockCycles(dut.clock_spi_in, 100)
