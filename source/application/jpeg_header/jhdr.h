/*
Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
CERN Open Hardware Licence Version 2 - Permissive
Copyright (C) 2024 Robert Metchev

Pre-compiled JPEG header template (incl. quantization and Huffman tables).
QF = 50, height = 0, width = 0
Positions:  QT0 25..88, QT1 93..156, height 163..164, width 165..166
Total length = 623
*/
#include <stdlib.h>
#include <stdio.h>
void hdr(int height, int width, int qf, char header_file_name[]);
