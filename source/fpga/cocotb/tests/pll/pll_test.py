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

@cocotb.test()
async def spi_test(dut):
    log_level = os.environ.get('LOG_LEVEL', 'INFO') # NOTSET=0 DEBUG=10 INFO=20 WARN=30 ERROR=40 CRITICAL=50
    dut._log.setLevel(log_level)

    dut.pll_reset = 1
    await Timer(5, units='us')

    dut.pll_reset = 0
    await Timer(1, units='us')

    # Finish
    await Timer(1000, units='us')
