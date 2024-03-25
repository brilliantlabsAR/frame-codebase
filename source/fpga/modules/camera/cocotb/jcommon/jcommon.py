import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
import numpy as np
import sys, os

np.set_printoptions(suppress=True, precision=3)


def rmse(x,y):
    return np.sqrt(np.mean((x-y)**2))

def psnr(x,y):
    return 20*(np.log10(255) - np.log10(rmse(x,y) + sys.float_info.epsilon))

def u2s(x, bits):
    """Unsigned to signed converter"""
    n = 2**(bits - 1)
    return (x + n)%(2*n) - n


async def clock_n_reset(dut):
    """36 MHz clock"""
    f = 36*10e6         # 36 MHz clock
    period = round(10e9/f,2)     # in ns
    """Generate clock pulses."""
    dut.resetn.value = 0
    cocotb.start_soon(Clock(dut.clk, period, units="ns").start())
    await ClockCycles(dut.clk, 5)
    dut.resetn.value = 1


async def finishn(dut, n):
    await ClockCycles(dut.clk, n)

