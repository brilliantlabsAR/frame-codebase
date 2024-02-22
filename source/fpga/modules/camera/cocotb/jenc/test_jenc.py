import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles, RisingEdge, FallingEdge, Timer
import numpy as np
import scipy
from queue import Queue
import os
from scipy.fft import dctn, idctn

import dct, dct_aan
import jcommon
import quant

np.set_printoptions(suppress=True, precision=3)
np.random.seed(0)

    
def initialize_ports(dut):
    dut.di_valid.value = 0
    dut.q_hold.value = 0

class Tester_1D_DCT:
    def __init__(self, dut):
        self.dut = dut
        self.qi = Queue()
        self.qo = Queue()
        self.q = Queue()
        self.cnt = 0


    def send_8x8_data(self, data=None, ref_func=dct.dct1d):
        if data is None:
            # generate 8x8 random data
            data = np.random.randint(256, size=(8, 8))
        rows, cols = data.shape
        assert cols == 8

        # Calculate reference
        if ref_func is not None:
            out = ref_func(data)

        # send invidiaual dct rows to queue
        # send imput to input queue
        for i in range(rows):
            if ref_func is not None:
                self.q.put(out[i], block=False)
            self.qi.put(data[i], block=False)
    

    async def collect(self):
        """Collect output from pipe and but onto output queue qo"""
        vec = 0
        data = []
        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.q_valid.value and not self.dut.q_hold.value:
                q = self.dut.q
                data += [jcommon.u2s(i.value, i.value.n_bits) for i in q][::-1]
                cnt = self.dut.q_cnt.value.integer
                if len(data) == 8:
                    c = cnt*len(q)/8
                    #print(data, cnt)
                    self.qo.put((data, cnt))
                    e = f'Collector: Vector {vec} (cnt={cnt}): Received={data}'
                    #print(e)
                    data = []
                    vec += 1


    async def inject(self):
        while True:
            await RisingEdge(self.dut.clk)
            if not self.qi.empty():
                while self.dut.di_hold.value:
                    await RisingEdge(self.dut.clk)
                self.dut.di_valid.value = 1
                self.dut.di_cnt.value = self.cnt
                for i, d in enumerate(self.qi.get(block=False)):
                    self.dut.di[i].value = d.item()
                self.cnt = (self.cnt + 1) % 8
            else:
                self.dut.di_valid.value = 0


    async def checker(self):
        """Check output queue qo"""
        vec = 0
        while True:
            await RisingEdge(self.dut.clk)
            if not self.qo.empty():
                #print(len(self.qo.queue), len(self.q.queue))
                out, _ = self.qo.get(block=False)
                ref = [i.item() for i in self.q.get(block=False)]
                cnt = self.dut.q_cnt.value.integer
                for pos, (o, r) in enumerate(zip(out, ref)):
                    if abs(o-r) == 1:
                        w = f'WARNING in vector {vec} (cnt={cnt}): Mismatch by 1 in coefficient {pos}: Expected={r},  Received={o}'
                        print (w)
                    elif o != r:
                        e = f'ERROR in vector {vec} (cnt={cnt}): Mismatch in coefficient {pos}: Expected={r},  Received={o}'
                        print (e)
                        raise Exception(e)
                vec += 1


    async def monitor(self):
        """Monitor output queue qo"""
        vec = 0
        while True:
            await RisingEdge(self.dut.clk)
            if self.dut.q_valid.value and not self.dut.q_hold.value:
                q = self.dut.q
                q = [i.value for i in q][::-1] # Need to reverse!
                q = [jcommon.u2s(i.integer, i.n_bits)  for i in q]
                cnt = self.dut.q_cnt.value.integer
                e = f'HW Monitor: Vector {vec} (cnt={cnt}): Received={q}'
                #print (e)
                vec += 1


@cocotb.test()
async def dct_test(dut):
    initialize_ports(dut)
    cocotb.start_soon(jcommon.clock_n_reset(dut))
    
    t = Tester_1D_DCT(dut)
    # start injector
    cocotb.start_soon(t.collect())
    cocotb.start_soon(t.inject())
    cocotb.start_soon(t.checker())
    cocotb.start_soon(t.monitor())

    await RisingEdge(dut.resetn)
    await RisingEdge(dut.clk)

    top_level = os.environ['TOPLEVEL']
    assert top_level in ['dct_aan', 'dct_2d', 'jenc']

    if top_level == 'dct_aan':
        dct_function = dct.dct1d
    if top_level == 'dct_2d':
        dct_function = dct.dct2d
    if top_level == 'jenc':
        q = quant.QTables(50)
        dct_function = lambda x: q.quantize_luma(dct.dct2d(x)).astype(int).flatten()[quant.de_zig_zag_array().flatten()].reshape(8,8)

    # 16x16 -> 6x MCU from Wallace Paper
    dut.x_size_m1.value = 15
    dut.y_size_m1.value = 15

    # Send MCU from Wallace Paper
    d = np.array([
    [139, 144, 149, 153, 155, 155, 155, 155],
    [144, 151, 153, 156, 159, 156, 156, 156],
    [150, 155, 160, 163, 158, 156, 156, 156],
    [159, 161, 162, 160, 160, 159, 159, 159],
    [159, 160, 161, 162, 162, 155, 155, 155],
    [161, 161, 161, 161, 160, 157, 157, 157],
    [162, 162, 161, 163, 162, 157, 157, 157],
    [162, 162, 161, 161, 163, 158, 158, 158]])
    
    d += np.random.randint(0, 10, (8,8))
    d -= 128
    
    q = quant.QTables(50)
    dct_function = lambda x: q.quantize_luma(dct.dct2d(x)).astype(int).flatten()[quant.de_zig_zag_array().flatten()].reshape(8,8)

    for i in range(4):
        t.send_8x8_data(d, dct_function)
        #d = np.random.randint(256, size=(8, 8))
        #t.send_8x8_data(d, dct_function)
        await ClockCycles(dut.clk, 50)  # wait for falling edge/"negedge"
    
    await ClockCycles(dut.clk, 50)  # wait for falling edge/"negedge"

    dct_d = dct.dct2d(d, sel='aan')
    qdct_d = q.quantize_chroma(dct_d, sel='aan')
    print(d.astype(int))
    print(dct_d.astype(int))
    print(q.qt_chroma_aan)
    #print(f'Chroma Q-table AAN adjusted =\n{qt.qt_chroma_aan}\n')
    print(f'Chroma Q-table AAN factors =\n{(4096*q.qt_chroma_aan_factors + .5).astype(int)}\n')
    print(qdct_d.astype(int))

    dct_function = lambda x: q.quantize_chroma(dct.dct2d(x)).astype(int).flatten()[quant.de_zig_zag_array().flatten()].reshape(8,8)
    for i in range(2):
        t.send_8x8_data(d, dct_function)
        await ClockCycles(dut.clk, 50)  # wait for falling edge/"negedge"
        
    
        
    await ClockCycles(dut.clk, 1500)  # wait for falling edge/"negedge"
