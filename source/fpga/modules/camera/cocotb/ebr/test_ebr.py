import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer

import random


f = 36*10e6                     # 36 MHz clock
period = round(10e9/f,2)        # in ns

@cocotb.test()
async def test_ebr(dut):
    n = 360
    m = dut.line_buf_in[1].value.n_bits

    dut.clk.value = 0
    dut.line_buf_in[2].value = 0
    dut.line_buf_in[1].value = 0

    dut.lb_we.value = 0
    dut.lb_re.value = 0
    dut.lb_ra.value = 0
    dut.lb_wa.value = 0

    """Generate clock pulses."""
    cocotb.start_soon(Clock(dut.clk, period, units="ns").start())

    await ClockCycles(dut.clk, 5)

    for _ in range(32):
        await RisingEdge(dut.clk)
        dut.lb_we.value = 1
        dut.line_buf_in[2].value = random.randint(0, 2**m - 1)
        dut.line_buf_in[1].value = random.randint(0, 2**m - 1)
        dut.lb_wa.value = random.randint(0, n - 1)
    
        await RisingEdge(dut.clk)
        dut.lb_re.value = 1
        dut.lb_we.value = 0
        dut.lb_ra.value = dut.lb_wa.value
    
        await RisingEdge(dut.clk)
        dut.lb_re.value = 0

        await RisingEdge(dut.clk)
        assert dut.line_buf_out_0[1].value == dut.line_buf_out_1[1].value
        assert dut.line_buf_out_0[2].value == dut.line_buf_out_1[2].value
    
    await ClockCycles(dut.clk, 50)

@cocotb.test()
async def test_dp_ram_be(dut):
    dut.clk.value = 0
    for i in range(2):
        dut.dp_ram_be[i].re.value = 0
        dut.dp_ram_be[i].we.value = 0

    """Generate clock pulses."""
    cocotb.start_soon(Clock(dut.clk, period, units="ns").start())
    
    await ClockCycles(dut.clk, 5)

    for _ in range(32):
        for i in range(2):
            n = 2880
            if i == 1:
                n /= 4
            m = dut.dp_ram_be[i].wd.value.n_bits

            await RisingEdge(dut.clk)
            dut.dp_ram_be[i].we.value = 1
            dut.dp_ram_be[i].wbe.value = random.randint(0, 2**8 - 1)
            dut.dp_ram_be[i].wd.value = random.randint(0, 2**m - 1)
            dut.dp_ram_be[i].wa.value = random.randint(0, n - 1)

            await RisingEdge(dut.clk)
            dut.dp_ram_be[i].we.value = 0
            dut.dp_ram_be[i].re.value = 1
            dut.dp_ram_be[i].ra.value = dut.dp_ram_be[i].wa.value

            await RisingEdge(dut.clk)
            dut.dp_ram_be[i].re.value = 0

            await RisingEdge(dut.clk)
            assert dut.dp_ram_be[i].rd_0.value == dut.dp_ram_be[i].rd_0.value


    await ClockCycles(dut.clk, 100)
