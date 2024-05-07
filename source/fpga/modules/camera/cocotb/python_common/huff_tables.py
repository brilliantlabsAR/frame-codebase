#
# Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#

import math

class HuffmanTable:
    def __init__(self, table):
        self.offsets = []
        self.symbols = []
        self.codes = []
        self.set = False
        for i, j in zip(['offsets', 'symbols', 'codes', 'set'], table):
            setattr(self, i, j)
            

# offset//codes
hDCTableY = [
    [ 0, 0, 1, 6, 7, 8, 9, 10, 11, 12, 12, 12, 12, 12, 12, 12, 12 ],
    [ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b ],
    [],
    False
]

hDCTableCbCr = [
    [ 0, 0, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 12, 12, 12, 12, 12 ],
    [ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b ],
    [],
    False
]

hACTableY = [
    [ 0, 0, 2, 3, 6, 9, 11, 15, 18, 23, 28, 32, 36, 36, 36, 37, 162 ],
    [
        0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12,
        0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
        0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xa1, 0x08,
        0x23, 0x42, 0xb1, 0xc1, 0x15, 0x52, 0xd1, 0xf0,
        0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0a, 0x16,
        0x17, 0x18, 0x19, 0x1a, 0x25, 0x26, 0x27, 0x28,
        0x29, 0x2a, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39,
        0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
        0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59,
        0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
        0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
        0x7a, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
        0x8a, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98,
        0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7,
        0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6,
        0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3, 0xc4, 0xc5,
        0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2, 0xd3, 0xd4,
        0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xe1, 0xe2,
        0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea,
        0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
        0xf9, 0xfa
    ],
    [],
    False
]

hACTableCbCr = [
    [ 0, 0, 2, 3, 5, 9, 13, 16, 20, 27, 32, 36, 40, 40, 41, 43, 162 ],
    [
        0x00, 0x01, 0x02, 0x03, 0x11, 0x04, 0x05, 0x21,
        0x31, 0x06, 0x12, 0x41, 0x51, 0x07, 0x61, 0x71,
        0x13, 0x22, 0x32, 0x81, 0x08, 0x14, 0x42, 0x91,
        0xa1, 0xb1, 0xc1, 0x09, 0x23, 0x33, 0x52, 0xf0,
        0x15, 0x62, 0x72, 0xd1, 0x0a, 0x16, 0x24, 0x34,
        0xe1, 0x25, 0xf1, 0x17, 0x18, 0x19, 0x1a, 0x26,
        0x27, 0x28, 0x29, 0x2a, 0x35, 0x36, 0x37, 0x38,
        0x39, 0x3a, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48,
        0x49, 0x4a, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58,
        0x59, 0x5a, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68,
        0x69, 0x6a, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78,
        0x79, 0x7a, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87,
        0x88, 0x89, 0x8a, 0x92, 0x93, 0x94, 0x95, 0x96,
        0x97, 0x98, 0x99, 0x9a, 0xa2, 0xa3, 0xa4, 0xa5,
        0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xb2, 0xb3, 0xb4,
        0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xc2, 0xc3,
        0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xd2,
        0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda,
        0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9,
        0xea, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8,
        0xf9, 0xfa
    ],
    [],
    False
]

dcTables = [HuffmanTable(table) for table in [hDCTableY, hDCTableCbCr]]
acTables = [HuffmanTable(table) for table in [hACTableY, hACTableCbCr]]

# generate all Huffman codes based on symbols from a Huffman table
def generateCodes(hTable):
    code = 0
    for i in range(16):
        for j in range(hTable.offsets[i], hTable.offsets[i + 1]):
            hTable.codes.append(code)
            code += 1
        code <<= 1;


def generateCodes2(tables):
    for t in tables:
        if not t.set:
            generateCodes(t)
            t.set = True


generateCodes2(dcTables)
generateCodes2(acTables)


def make_vlog_old(t, x):
    if x == 'dc':
        x = 12
        e = 12
    elif x == 'ac':
        x = 16
        e = 256
    print (f'logic [{4+x-1}:0] ht[{e-1}:0]; /* synthesis syn_romstyle = "Logic" */')
    print ('always_comb begin')
    print (f'    for (int i=0; i<{e}; i++) ht[i] =  20\'h x;')
    #print ('    case(symbol)')
    for i in range(16):
        for j in range(t.offsets[i], t.offsets[i + 1]):
            k = S
            k = '0'*(i + 1 - len(k)) + k
            #print (f'        8\'h {t.symbols[j]:02x} : ht = {{1\'b 1, 4\'d {i:>2d}, 16\'b {k:>16s}}};')
            a = f'8\'h {t.symbols[j]:02x}'
            b = ''
            if x == 12:
                a = f'4\'h {t.symbols[j]:01x}'
                b = ' 4\'b 0,'
            #print (f'        {a} : ht = {{4\'d {i:>2d}, {x}\'b {k:s}}};')
            print (f'    ht[{a}] = {{4\'d {i:>2d},{b} {x}\'b {k:s}}};')
    #print ('        default : ht = 21\'h 0;')
    #print (f'        default : ht = {x+4}\'h x;')
    #print ('    endcase')
    print ('end')




def make_memfile():
    """
    Indexing:
        Luma/chroma selected with LSB (chroma-flag)
        DC Table: indexed with SYMBOL = coefficient (0 .. 11)
        AC Table: indexed with SYMBOL = {runlength (0 .. 15),  coefficient (0 .. 10)}
            -> Swap for purposes of implementation
            index = {coefficient (0 .. 10), runlength (0 .. 15), chroma-flag} -> 9 bits
            Exceptions: Only 2 codes for coefficient==0 are valid: (0,0), (0,15)
                14 codes are invalid (0,1),.. (0,14)
        DC Table gets appended after AC table
            index = {0xB, coefficient (0 .. 11), chroma-flag}}
            
            
        address = {(ac-flag ? {coefficient, runlength} : {0xB, coefficient}), chroma-flag}
        
        Order:
            luma - AC
            luma - DC
            chroma - AC
            chroma - DC
    """
    n = 2*(11*16 + 12) #= 2*(176 + 12) = 2*188 = 376
    #n = 2**int(math.log2(n) + 1) # nearest power of 2
    n = 16*((n + 15)//16) # nearest 16
    
    mem = [0]*n
    for color in ['luma', 'chroma']:
        chroma_flag = 0 if color=='luma' else 1  # select table 
        for z in ['ac', 'dc']:
            if z == 'dc':
                x = 12
                e = 12
                t = dcTables[chroma_flag]
            elif z == 'ac':
                x = 16
                e = 256
                t = acTables[chroma_flag]

            for length_m1 in range(16):
                length = length_m1 + 1
                for j in range(t.offsets[length_m1], t.offsets[length]):
                    code = t.codes[j]
                    symbol = t.symbols[j]
                    #print(length, code, f'{code:x}', f' {symbol:x}')

                    if z == 'ac':
                        address = ((symbol & 0xf) << 5) + ((symbol & 0xf0) >> 3) + chroma_flag
                    elif z == 'dc':
                        address = (0xB << 5) + ((symbol & 0xf) << 1) + chroma_flag
            
                    #print(symbol, address , length)
                    mem[address] = [length_m1, code, f"//{z} {color}"]

    initvals = []
    for a, m in enumerate(mem):
        if type(m) is list:
            (l, c, _) = m
            dat = (c << (16 - l - 1))
        else:
            l = 0
            dat = 0xdead    

        # MEM File
        #print(a, f'{l:1x}{dat:04x}')    
        initvals.append(dat | (l << 16))

    i = 0
    while(len(initvals)):
        d = initvals[:16]
        initvals = initvals[16:]
        
        m = 0
        for j, v in enumerate(d):
            #print(j, f'{v:x}')
            m |= (((v & 0x1ff) | (((v >> 9) & 0x1ff) << 10)) << j*20)
        print(f'defparam EBR_inst.INITVAL_{i:02X} = "0x{m:080X}";')
        i += 1


        # 
#        add = f'{{8\'h {a:2x}, 1\'b 0}}'
            
#            print(add, l0, c0, note)
#        #else    :
#        #    print(add, 0)
#    for a, m in enumerate(mem[1::2]):
#        break
#        add = 2*a + 1
#        k = a >> 1
#        if type(m) is list:
#            ll, cc, note = m 
#            print(add, ll >>2, note)
#        #else    :
#        #    print(add, 0)
            


make_memfile()
