import logging

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer,  First, Edge
from cocotbext.spi import SpiMaster, SpiBus, SpiConfig
from cocotb_bus.bus import Bus


async def clock_n_reset(c, r, f=0, n=5, t=10):
    """
    Kick off clocksExample:
    clk_op = cocotb.start_soon(clock_n_reset(dut.camera_pixel_clock, None, f=36.0*10e6))       # 36 MHz clock
    clk_os = cocotb.start_soon(clock_n_reset(dut.cpu_clock_8hmz, None, f=8*10e6))  # 8 MHz clock
    await cocotb.triggers.Combine(clk_op, clk_os)
    """
    if r is not None:
        r.value = 0
    if c is not None:
        period = round(10e9/f, 2) # in ns
        cocotb.start_soon(Clock(c, period, units="ns").start())
        await ClockCycles(c, n)
    else:
        await Timer(t, 'us')
    if r is not None:
        r.value = 1


class SpiTransactor:
    def __init__(self, dut):
        self.dut = dut
        self.log = logging.getLogger("SPI Transactor")
        self.log.setLevel(self.dut._log.level)

        # Define bus as recommended
        self.bus = Bus(dut, None, 
            {
                "sclk": "spi_clock_in",
                "miso": "spi_data_out",
                "mosi": "spi_data_in",
                "cs":   "spi_select_in",
            }, optional_signals=[]
        )

        # Define SPI config
        self.config = SpiConfig(
            word_width  = 8,        # 8 bits
            sclk_freq   = 8e6,      # 8 MHz
            cpol        = 0,
            cpha        = 0,
            msb_first   = True,
            #frame_spacing_ns = 10,
            #ignore_rx_value = None,
            cs_active_low = True,   # optional (assumed True)
        )

        self.source = SpiMaster(self.bus, self.config)

    async def spi_write(self, address, data):
        try:
            if len(data) == 0:
                data = [0]
        except TypeError:
            data = [data]
        self.log.info(f"SPI WRITE: ADDRESS=0x{address:02x} DATA={[hex(i) for i in data]} ")
        await self.source.write([address] + data, burst=True)
        _ = await self.source.read() # flush read queue

    async def spi_read(self, address, n=1):
        d = [address] + [0]*n
        await self.source.write([address] + [0]*n, burst=True)
        read_bytes = await self.source.read()
        read_bytes = read_bytes[1:]
        self.log.info(f"SPI READ:  ADDRESS=0x{address:02x} DATA={[hex(i) for i in read_bytes]} ")
        return [int(i) for i in read_bytes]


