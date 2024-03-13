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

void writeFooter(const std::string& filename) {
    // open file
    std::cout << "Writing " << filename << "...\n";
    std::ofstream outFile(filename, std::ios::out | std::ios::binary);
    if (!outFile.is_open()) {
        std::cout << "Error - Error opening output file\n";
        return;
    }
    // EOI
    outFile.put(0xFF);
    outFile.put(EOI);

    outFile.close();
}
void writeHeader(const BMPImage& image, const std::string& filename, const int qf) {
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
    QuantizationTable qTableY, qTableCbCr;

    uint res = 10;
    for (uint i = 0; i < 64; ++i) {
        float q = qTableY50.table[i];
        q *= pow(2, qf);
        q = std::floor(q + 0.5); // round
        if (q > pow(2, res)) {
            q = pow(2, res) - 1;
        } else if (q == 0) {
            q = 1;
        }
        qTableY.table[i] = (uint)q;
        std::cout << i << " m=" << pow(2, qf) << " " << qTableY50.table[i] << " " << q << " " <<   qTableY.table[i] << "\n";
    }

    writeQuantizationTable(outFile, 0, qTableY);
    writeQuantizationTable(outFile, 1, qTableCbCr);

    // SOF
    writeStartOfFrame(outFile, image);

    // DHT
    writeHuffmanTable(outFile, 0, 0, hDCTableY);
    writeHuffmanTable(outFile, 0, 1, hDCTableCbCr);
    writeHuffmanTable(outFile, 1, 0, hACTableY);
    writeHuffmanTable(outFile, 1, 1, hACTableCbCr);

    // SOS
    writeStartOfScan(outFile);

    outFile.close();
}

int main(int argc, char** argv) {
    // validate arguments
    if (argc < 2) {
        std::cout << "Error - Invalid arguments\n";
        return 1;
    }

    BMPImage image;
    image.height = 256;
    image.width = 256;
    writeHeader(image, "header.bin", -25);
    writeFooter("footer.bin");

    return 0;
}
