/*
Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
CERN Open Hardware Licence Version 2 - Permissive
Copyright (C) 2024 Robert Metchev
*/
#include "jhdr.h"
int main(int argc, char *argv[]) {
    if(argc <= 2) 
        exit(1);
    // call hdr, write header to "header.bin"
    hdr(atoi(argv[1]), atoi(argv[2]), argc > 3 ? atoi(argv[3]) :  50 , argc > 4 ? argv[4] :  "header.bin");
    return 0;
}

