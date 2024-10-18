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
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer


import tb_top
from tb_top import SpiTransactor, clock_n_reset




@cocotb.test()
async def spi_test(dut):
    log_level = os.environ.get('LOG_LEVEL', 'INFO') # NOTSET=0 DEBUG=10 INFO=20 WARN=30 ERROR=40 CRITICAL=50
    dut._log.setLevel(log_level)

    # Hack/Fix for missing "negedge reset" in verilator, works OK in icarus
    dut.spi_select_in.value = 0
    await Timer(1, 'ps')
    # add assert for PLL reset stable

    # SPI Transactor
    t = SpiTransactor(dut)

    # Start camera clock
    cr = cocotb.start_soon(clock_n_reset(dut.camera_pixel_clock, None, f=36.0*10e6))       # 36 MHz clock

    
    #await Timer(20, units='us')
    
    # 1. Test single byte read from ID register 0xDB
    a = 0xdb
    id = [0x81]
    read_bytes = await t.spi_read(0xdb)
    assert read_bytes == id , f"ID register {hex(a)}: Expected: {[hex(i) for i in id]}. Received: {[hex(i) for i in read_bytes]}."
    
    # 2. Now lets power up the PLL 0x40/0x41
    await t.spi_write(0x40, 0x1)
    # Wait for PLL to lock & global reset to kick in - 20ms
    await Timer(20, units='us')
    # Check PLL lock flag
    a = 0x41
    read_bytes = await t.spi_read(a)
    assert read_bytes == [1] , f"ID register {hex(a)}: Expected: 0x1. Received: {[hex(i) for i in read_bytes]}."

    # 3. Image Buffer clock switch

    # 3a. Read Image buffer using PLL clock (default)
    read_bytes = await t.spi_read(0x22)
    # 3b. Switch Image buffer clock to SPI clock 0x41
    await t.spi_write(0x40, 0x3)
    # 3c. Power down PLL 0x41
    await t.spi_write(0x40, 0x2)
    # 3d. Read 2 bytes from Image buffer using SPI clock - low power PLL mode
    read_bytes = await t.spi_read(0x22, 2)
    # 3e. Power up PLL again
    await t.spi_write(0x40, 0x3)
    await Timer(20, units='us')
    read_bytes = await t.spi_read(0x41)
    assert read_bytes == [1]
    # 3f. Switch Image buffer clock back to PLL clock
    await t.spi_write(0x40, 0x1)
    # 3d. Read 3 bytes from Image buffer using PLL clock
    read_bytes = await t.spi_read(0x22, 3)




    # Finish
    await Timer(5, units='us')
