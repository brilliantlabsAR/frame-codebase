#include <iostream>
#include <fstream>
#include <vector>

#include "jpg.h"

// helper function to read a 4-byte integer in little-endian
uint getInt(std::ifstream& inFile) {
    return (inFile.get() <<  0)
         + (inFile.get() <<  8)
         + (inFile.get() << 16)
         + (inFile.get() << 24);
}

// helper function to read a 2-byte short integer in little-endian
uint getShort(std::ifstream& inFile) {
    return (inFile.get() << 0)
         + (inFile.get() << 8);
}

BMPImage readBMP(const std::string& filename) {
    BMPImage image;

    // open file
    std::cout << "Reading " << filename << "...\n";
    std::ifstream inFile(filename, std::ios::in | std::ios::binary);
    if (!inFile.is_open()) {
        std::cout << "Error - Error opening input file\n";
        return image;
    }

    if (inFile.get() != 'B' || inFile.get() != 'M') {
        std::cout << "Error - Invalid BMP file\n";
        inFile.close();
        return image;
    }

    getInt(inFile); // size
    getInt(inFile); // nothing
    if (getInt(inFile) != 0x1A) {
        std::cout << "Error - Invalid offset\n";
        inFile.close();
        return image;
    }
    if (getInt(inFile) != 12) {
        std::cout << "Error - Invalid DIB size\n";
        inFile.close();
        return image;
    }
    image.width = getShort(inFile);
    image.height = getShort(inFile);
    if (getShort(inFile) != 1) {
        std::cout << "Error - Invalid number of planes\n";
        inFile.close();
        return image;
    }
    if (getShort(inFile) != 24) {
        std::cout << "Error - Invalid bit depth\n";
        inFile.close();
        return image;
    }

    if (image.height == 0 || image.width == 0) {
        std::cout << "Error - Invalid dimensions\n";
        inFile.close();
        return image;
    }

    image.blockHeight = (image.height + 7) / 8;
    image.blockWidth = (image.width + 7) / 8;

    image.blocks = new (std::nothrow) Block[image.blockHeight * image.blockWidth];
    if (image.blocks == nullptr) {
        std::cout << "Error - Memory error\n";
        inFile.close();
        return image;
    }

    const uint paddingSize = image.width % 4;

    for (uint y = image.height - 1; y < image.height; --y) {
        const uint blockRow = y / 8;
        const uint pixelRow = y % 8;
        for (uint x = 0; x < image.width; ++x) {
            const uint blockColumn = x / 8;
            const uint pixelColumn = x % 8;
            const uint blockIndex = blockRow * image.blockWidth + blockColumn;
            const uint pixelIndex = pixelRow * 8 + pixelColumn;
            image.blocks[blockIndex].b[pixelIndex] = inFile.get();
            image.blocks[blockIndex].g[pixelIndex] = inFile.get();
            image.blocks[blockIndex].r[pixelIndex] = inFile.get();
        }
        for (uint i = 0; i < paddingSize; ++i) {
            inFile.get();
        }
    }

    inFile.close();
    return image;
}

// convert all pixels in a block from RGB color space to YCbCr
void RGBToYCbCrBlock(Block& block) {
    for (uint y = 0; y < 8; ++y) {
        for (uint x = 0; x < 8; ++x) {
            const uint pixel = y * 8 + x;
            int y  =  0.2990 * block.r[pixel] + 0.5870 * block.g[pixel] + 0.1140 * block.b[pixel] - 128;
            int cb = -0.1687 * block.r[pixel] - 0.3313 * block.g[pixel] + 0.5000 * block.b[pixel];
            int cr =  0.5000 * block.r[pixel] - 0.4187 * block.g[pixel] - 0.0813 * block.b[pixel];
            if (y  < -128) y  = -128;
            if (y  >  127) y  =  127;
            if (cb < -128) cb = -128;
            if (cb >  127) cb =  127;
            if (cr < -128) cr = -128;
            if (cr >  127) cr =  127;
            block.y[pixel]  = y;
            block.cb[pixel] = cb;
            block.cr[pixel] = cr;
        }
    }
}

// convert all pixels from RGB color space to YCbCr
void RGBToYCbCr(const BMPImage& image) {
    for (uint y = 0; y < image.blockHeight; ++y) {
        for (uint x = 0; x < image.blockWidth; ++x) {
            RGBToYCbCrBlock(image.blocks[y * image.blockWidth + x]);
        }
    }
}

// perform 1-D FDCT on all columns and rows of a block component
//   resulting in 2-D FDCT
void forwardDCTBlockComponent(int* const component) {
    for (uint i = 0; i < 8; ++i) {
        const float a0 = component[0 * 8 + i];
        const float a1 = component[1 * 8 + i];
        const float a2 = component[2 * 8 + i];
        const float a3 = component[3 * 8 + i];
        const float a4 = component[4 * 8 + i];
        const float a5 = component[5 * 8 + i];
        const float a6 = component[6 * 8 + i];
        const float a7 = component[7 * 8 + i];

        const float b0 = a0 + a7;
        const float b1 = a1 + a6;
        const float b2 = a2 + a5;
        const float b3 = a3 + a4;
        const float b4 = a3 - a4;
        const float b5 = a2 - a5;
        const float b6 = a1 - a6;
        const float b7 = a0 - a7;

        const float c0 = b0 + b3;
        const float c1 = b1 + b2;
        const float c2 = b1 - b2;
        const float c3 = b0 - b3;
        const float c4 = b4;
        const float c5 = b5 - b4;
        const float c6 = b6 - c5;
        const float c7 = b7 - b6;

        const float d0 = c0 + c1;
        const float d1 = c0 - c1;
        const float d2 = c2;
        const float d3 = c3 - c2;
        const float d4 = c4;
        const float d5 = c5;
        const float d6 = c6;
        const float d7 = c5 + c7;
        const float d8 = c4 - c6;

        const float e0 = d0;
        const float e1 = d1;
        const float e2 = d2 * m1;
        const float e3 = d3;
        const float e4 = d4 * m2;
        const float e5 = d5 * m3;
        const float e6 = d6 * m4;
        const float e7 = d7;
        const float e8 = d8 * m5;

        const float f0 = e0;
        const float f1 = e1;
        const float f2 = e2 + e3;
        const float f3 = e3 - e2;
        const float f4 = e4 + e8;
        const float f5 = e5 + e7;
        const float f6 = e6 + e8;
        const float f7 = e7 - e5;

        const float g0 = f0;
        const float g1 = f1;
        const float g2 = f2;
        const float g3 = f3;
        const float g4 = f4 + f7;
        const float g5 = f5 + f6;
        const float g6 = f5 - f6;
        const float g7 = f7 - f4;

        component[0 * 8 + i] = g0 * s0;
        component[4 * 8 + i] = g1 * s4;
        component[2 * 8 + i] = g2 * s2;
        component[6 * 8 + i] = g3 * s6;
        component[5 * 8 + i] = g4 * s5;
        component[1 * 8 + i] = g5 * s1;
        component[7 * 8 + i] = g6 * s7;
        component[3 * 8 + i] = g7 * s3;
    }
    for (uint i = 0; i < 8; ++i) {
        const float a0 = component[i * 8 + 0];
        const float a1 = component[i * 8 + 1];
        const float a2 = component[i * 8 + 2];
        const float a3 = component[i * 8 + 3];
        const float a4 = component[i * 8 + 4];
        const float a5 = component[i * 8 + 5];
        const float a6 = component[i * 8 + 6];
        const float a7 = component[i * 8 + 7];

        const float b0 = a0 + a7;
        const float b1 = a1 + a6;
        const float b2 = a2 + a5;
        const float b3 = a3 + a4;
        const float b4 = a3 - a4;
        const float b5 = a2 - a5;
        const float b6 = a1 - a6;
        const float b7 = a0 - a7;

        const float c0 = b0 + b3;
        const float c1 = b1 + b2;
        const float c2 = b1 - b2;
        const float c3 = b0 - b3;
        const float c4 = b4;
        const float c5 = b5 - b4;
        const float c6 = b6 - c5;
        const float c7 = b7 - b6;

        const float d0 = c0 + c1;
        const float d1 = c0 - c1;
        const float d2 = c2;
        const float d3 = c3 - c2;
        const float d4 = c4;
        const float d5 = c5;
        const float d6 = c6;
        const float d7 = c5 + c7;
        const float d8 = c4 - c6;

        const float e0 = d0;
        const float e1 = d1;
        const float e2 = d2 * m1;
        const float e3 = d3;
        const float e4 = d4 * m2;
        const float e5 = d5 * m3;
        const float e6 = d6 * m4;
        const float e7 = d7;
        const float e8 = d8 * m5;

        const float f0 = e0;
        const float f1 = e1;
        const float f2 = e2 + e3;
        const float f3 = e3 - e2;
        const float f4 = e4 + e8;
        const float f5 = e5 + e7;
        const float f6 = e6 + e8;
        const float f7 = e7 - e5;

        const float g0 = f0;
        const float g1 = f1;
        const float g2 = f2;
        const float g3 = f3;
        const float g4 = f4 + f7;
        const float g5 = f5 + f6;
        const float g6 = f5 - f6;
        const float g7 = f7 - f4;

        component[i * 8 + 0] = g0 * s0;
        component[i * 8 + 4] = g1 * s4;
        component[i * 8 + 2] = g2 * s2;
        component[i * 8 + 6] = g3 * s6;
        component[i * 8 + 5] = g4 * s5;
        component[i * 8 + 1] = g5 * s1;
        component[i * 8 + 7] = g6 * s7;
        component[i * 8 + 3] = g7 * s3;
    }
}

// perform FDCT on all MCUs
void forwardDCT(const BMPImage& image) {
    for (uint y = 0; y < image.blockHeight; ++y) {
        for (uint x = 0; x < image.blockWidth; ++x) {
            for (uint i = 0; i < 3; ++i) {
                forwardDCTBlockComponent(image.blocks[y * image.blockWidth + x][i]);
            }
        }
    }
}

// quantize a block component based on a quantization table
void quantizeBlockComponent(const QuantizationTable& qTable, int* const component) {
    for (uint i = 0; i < 64; ++i) {
        component[i] /= (signed)qTable.table[i];
    }
}

// quantize all MCUs
void quantize(const BMPImage& image) {
    for (uint y = 0; y < image.blockHeight; ++y) {
        for (uint x = 0; x < image.blockWidth; ++x) {
            for (uint i = 0; i < 3; ++i) {
                quantizeBlockComponent(*qTables100[i], image.blocks[y * image.blockWidth + x][i]);
            }
        }
    }
}

class BitWriter {
private:
    byte nextBit = 0;
    std::vector<byte>& data;

public:
    BitWriter(std::vector<byte>& d) :
    data(d)
    {}

    void writeBit(uint bit) {
        if (nextBit == 0) {
            data.push_back(0);
        }
        data.back() |= (bit & 1) << (7 - nextBit);
        nextBit = (nextBit + 1) % 8;
        if (nextBit == 0 && data.back() == 0xFF) {
            data.push_back(0);
        }
    }

    void writeBits(uint bits, uint length) {
        for (uint i = 1; i <= length; ++i) {
            writeBit(bits >> (length - i));
        }
    }
};

// generate all Huffman codes based on symbols from a Huffman table
void generateCodes(HuffmanTable& hTable) {
    uint code = 0;
    for (uint i = 0; i < 16; ++i) {
        for (uint j = hTable.offsets[i]; j < hTable.offsets[i + 1]; ++j) {
            hTable.codes[j] = code;
            code += 1;
        }
        code <<= 1;
    }
}

uint bitLength(int v) {
    uint length = 0;
    while (v > 0) {
        v >>= 1;
        length += 1;
    }
    return length;
}

bool getCode(const HuffmanTable& hTable, byte symbol, uint& code, uint& codeLength) {
    for (uint i = 0; i < 16; ++i) {
        for (uint j = hTable.offsets[i]; j < hTable.offsets[i + 1]; ++j) {
            if (symbol == hTable.symbols[j]) {
                code = hTable.codes[j];
                codeLength = i + 1;
                return true;
            }
        }
    }
    return false;
}

bool encodeBlockComponent(
    BitWriter& bitWriter,
    int* const component,
    int& previousDC,
    const HuffmanTable& dcTable,
    const HuffmanTable& acTable
) {
    // encode DC value
    int coeff = component[0] - previousDC;
    previousDC = component[0];

    uint coeffLength = bitLength(std::abs(coeff));
    if (coeffLength > 11) {
        std::cout << "Error - DC coefficient length greater than 11\n";
        return false;
    }
    if (coeff < 0) {
        coeff += (1 << coeffLength) - 1;
    }

    uint code = 0;
    uint codeLength = 0;
    if (!getCode(dcTable, coeffLength, code, codeLength)) {
        std::cout << "Error - Invalid DC value\n";
        return false;
    }
    bitWriter.writeBits(code, codeLength);
    bitWriter.writeBits(coeff, coeffLength);

    // encode AC values
    for (uint i = 1; i < 64; ++i) {
        // find zero run length
        byte numZeroes = 0;
        while (i < 64 && component[zigZagMap[i]] == 0) {
            numZeroes += 1;
            i += 1;
        }

        if (i == 64) {
            if (!getCode(acTable, 0x00, code, codeLength)) {
                std::cout << "Error - Invalid AC value\n";
                return false;
            }
            bitWriter.writeBits(code, codeLength);
            return true;
        }

        while (numZeroes >= 16) {
            if (!getCode(acTable, 0xF0, code, codeLength)) {
                std::cout << "Error - Invalid AC value\n";
                return false;
            }
            bitWriter.writeBits(code, codeLength);
            numZeroes -= 16;
        }

        // find coeff length
        coeff = component[zigZagMap[i]];
        coeffLength = bitLength(std::abs(coeff));
        if (coeffLength > 10) {
            std::cout << "Error - AC coefficient length greater than 10\n";
            return false;
        }
        if (coeff < 0) {
            coeff += (1 << coeffLength) - 1;
        }

        // find symbol in table
        byte symbol = numZeroes << 4 | coeffLength;
        if (!getCode(acTable, symbol, code, codeLength)) {
            std::cout << "Error - Invalid AC value\n";
            return false;
        }
        bitWriter.writeBits(code, codeLength);
        bitWriter.writeBits(coeff, coeffLength);
    }

    return true;
}

// encode all the Huffman data from all MCUs
std::vector<byte> encodeHuffmanData(const BMPImage& image) {
    std::vector<byte> huffmanData;
    BitWriter bitWriter(huffmanData);

    int previousDCs[3] = { 0 };

    for (uint i = 0; i < 3; ++i) {
        if (!dcTables[i]->set) {
            generateCodes(*dcTables[i]);
            dcTables[i]->set = true;
        }
        if (!acTables[i]->set) {
            generateCodes(*acTables[i]);
            acTables[i]->set = true;
        }
    }

    for (uint y = 0; y < image.blockHeight; ++y) {
        for (uint x = 0; x < image.blockWidth; ++x) {
            for (uint i = 0; i < 3; ++i) {
                if (!encodeBlockComponent(
                        bitWriter,
                        image.blocks[y * image.blockWidth + x][i],
                        previousDCs[i],
                        *dcTables[i],
                        *acTables[i])) {
                    return std::vector<byte>();
                }
            }
        }
    }

    return huffmanData;
}

// helper function to write a 2-byte short integer in big-endian
void putShort(std::ofstream& outFile, const uint v) {
    outFile.put((v >> 8) & 0xFF);
    outFile.put((v >> 0) & 0xFF);
}

void writeQuantizationTable(std::ofstream& outFile, byte tableID, const QuantizationTable& qTable) {
    outFile.put(0xFF);
    outFile.put(DQT);
    putShort(outFile, 67);
    outFile.put(tableID);
    for (uint i = 0; i < 64; ++i) {
        outFile.put(qTable.table[zigZagMap[i]]);
    }
}

void writeStartOfFrame(std::ofstream& outFile, const BMPImage& image) {
    outFile.put(0xFF);
    outFile.put(SOF0);
    putShort(outFile, 17);
    outFile.put(8);
    putShort(outFile, image.height);
    putShort(outFile, image.width);
    outFile.put(3);
    for (uint i = 1; i <= 3; ++i) {
        outFile.put(i);
        outFile.put(0x11);
        outFile.put(i == 1 ? 0 : 1);
    }
}

void writeHuffmanTable(std::ofstream& outFile, byte acdc, byte tableID, const HuffmanTable& hTable) {
    outFile.put(0xFF);
    outFile.put(DHT);
    putShort(outFile, 19 + hTable.offsets[16]);
    outFile.put(acdc << 4 | tableID);
    for (uint i = 0; i < 16; ++i) {
        outFile.put(hTable.offsets[i + 1] - hTable.offsets[i]);
    }
    for (uint i = 0; i < 16; ++i) {
        for (uint j = hTable.offsets[i]; j < hTable.offsets[i + 1]; ++j) {
            outFile.put(hTable.symbols[j]);
        }
    }
}

void writeStartOfScan(std::ofstream& outFile) {
    outFile.put(0xFF);
    outFile.put(SOS);
    putShort(outFile, 12);
    outFile.put(3);
    for (uint i = 1; i <= 3; ++i) {
        outFile.put(i);
        outFile.put(i == 1 ? 0x00 : 0x11);
    }
    outFile.put(0);
    outFile.put(63);
    outFile.put(0);
}

void writeAPP0(std::ofstream& outFile) {
    outFile.put(0xFF);
    outFile.put(APP0);
    putShort(outFile, 16);
    outFile.put('J');
    outFile.put('F');
    outFile.put('I');
    outFile.put('F');
    outFile.put(0);
    outFile.put(1);
    outFile.put(2);
    outFile.put(0);
    putShort(outFile, 100);
    putShort(outFile, 100);
    outFile.put(0);
    outFile.put(0);
}

void writeJPG(const BMPImage& image, const std::string& filename) {
    std::vector<byte> huffmanData = encodeHuffmanData(image);
    if (huffmanData.size() == 0) {
        return;
    }

    // open file
    std::cout << "Writing " << filename << "...\n";
    std::ofstream outFile(filename, std::ios::out | std::ios::binary);
    if (!outFile.is_open()) {
        std::cout << "Error - Error opening output file\n";
        return;
    }

    // SOI
    outFile.put(0xFF);
    outFile.put(SOI);

    // APP0
    writeAPP0(outFile);

    // DQT
    writeQuantizationTable(outFile, 0, qTableY100);
    writeQuantizationTable(outFile, 1, qTableCbCr100);

    // SOF
    writeStartOfFrame(outFile, image);

    // DHT
    writeHuffmanTable(outFile, 0, 0, hDCTableY);
    writeHuffmanTable(outFile, 0, 1, hDCTableCbCr);
    writeHuffmanTable(outFile, 1, 0, hACTableY);
    writeHuffmanTable(outFile, 1, 1, hACTableCbCr);

    // SOS
    writeStartOfScan(outFile);

    // ECS
    outFile.write((char*)&huffmanData[0], huffmanData.size());

    // EOI
    outFile.put(0xFF);
    outFile.put(EOI);

    outFile.close();
}

int main(int argc, char** argv) {
    // validate arguments
    if (argc < 2) {
        std::cout << "Error - Invalid arguments\n";
        return 1;
    }

    for (int i = 1; i < argc; ++i) {
        const std::string filename(argv[i]);

        // read image
        BMPImage image = readBMP(filename);
        // validate image
        if (image.blocks == nullptr) {
            continue;
        }

        // color conversion
        RGBToYCbCr(image);

        // Forward Discrete Cosine Transform
        forwardDCT(image);

        // quantize DCT coefficients
        quantize(image);

        // write JPG file
        const std::size_t pos = filename.find_last_of('.');
        const std::string outFilename = (pos == std::string::npos) ?
            (filename + ".jpg") :
            (filename.substr(0, pos) + ".jpg");
        writeJPG(image, outFilename);

        delete[] image.blocks;
    }
    return 0;
}
