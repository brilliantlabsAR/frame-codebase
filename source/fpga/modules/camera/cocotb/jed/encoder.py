from quant import qt_scale_log
from jpg import *
import numpy as np


# helper function to write a 2-byte short integer in big-endian
def putShort(out_file, v):
    out_file.append((v >> 8) & 0xFF)
    out_file.append((v >> 0) & 0xFF)


def writeQuantizationTable(out_file, tableID, qTable):
    out_file.append(0xFF)
    out_file.append(DQT)
    putShort(out_file, 67)
    out_file.append(tableID)
    for i in range(64):
        out_file.append(qTable[0][zigZagMap[i]])


def writeStartOfFrame(out_file, height, width):
    out_file.append(0xFF)
    out_file.append(SOF0)
    putShort(out_file, 17)
    out_file.append(8)
    putShort(out_file, height)
    putShort(out_file, width)
    out_file.append(3)
    for i in range(1, 4):
        out_file.append(i)
        out_file.append(0x22 if i == 1 else 0x11) # subsampling
        out_file.append(0 if i == 1 else 1)


def writeHuffmanTable(out_file, acdc, tableID, hTable):
    out_file.append(0xFF)
    out_file.append(DHT)
    putShort(out_file, 19 + hTable[0][16])
    out_file.append(acdc << 4 | tableID)
    for i in range(16):
        out_file.append(hTable[0][i + 1] - hTable[0][i])

    for i in range(16):
        for j in range(hTable[0][i], hTable[0][i + 1]):
            out_file.append(hTable[1][j])


def writeStartOfScan(out_file):
    out_file.append(0xFF)
    out_file.append(SOS)
    putShort(out_file, 12)
    out_file.append(3)
    for i in range(1, 4):
        out_file.append(i)
        out_file.append(0x00 if i == 1 else 0x11)
    out_file.append(0)
    out_file.append(63)
    out_file.append(0)


def writeAPP0(out_file):
    out_file.append(0xFF)
    out_file.append(APP0)
    putShort(out_file, 16)
    out_file.append(ord('J'))
    out_file.append(ord('F'))
    out_file.append(ord('I'))
    out_file.append(ord('F'))
    out_file.append(0)
    out_file.append(1)
    out_file.append(2)
    out_file.append(0)
    putShort(out_file, 100)
    putShort(out_file, 100)
    out_file.append(0)
    out_file.append(0)


def writeJPG_header(height, width):
    out_file = []
    
    # SOI
    out_file.append(0xFF)
    out_file.append(SOI)

    # APP0
    writeAPP0(out_file)

    # DQT
    #writeQuantizationTable(out_file, 0, qTableY100)
    #writeQuantizationTable(out_file, 1, qTableCbCr100)
    writeQuantizationTable(out_file, 0, [list(qt_scale_log(np.array(qTableY50[0]), qf_log=0)), None])
    writeQuantizationTable(out_file, 1, [list(qt_scale_log(np.array(qTableCbCr50[0]), qf_log=0)), None])

    # SOF
    writeStartOfFrame(out_file, height, width)

    # DHT
    writeHuffmanTable(out_file, 0, 0, hDCTableY)
    writeHuffmanTable(out_file, 0, 1, hDCTableCbCr)
    writeHuffmanTable(out_file, 1, 0, hACTableY)
    writeHuffmanTable(out_file, 1, 1, hACTableCbCr)

    # SOS
    writeStartOfScan(out_file)
    return out_file

def writeJPG_footer():
    out_file = []
    # EOI
    out_file.append(0xFF)
    out_file.append(EOI)
    return out_file

def writeJPG():
    out_file = []
    out_file.append(writeJPG_header())

    # ECS
    #out_file.write((char*)&huffmanData[0], huffmanData.size())

    out_file.append(writeJPG_footer())
    return out_file
