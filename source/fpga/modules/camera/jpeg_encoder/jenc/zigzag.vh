/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
/*
[[ 0  1  5  6 14 15 27 28]
 [ 2  4  7 13 16 26 29 42]
 [ 3  8 12 17 25 30 41 43]
 [ 9 11 18 24 31 40 44 53]
 [10 19 23 32 39 45 52 54]
 [20 22 33 38 46 51 55 60]
 [21 34 37 47 50 56 59 61]
 [35 36 48 49 57 58 62 63]]
*/
// `include guards
`ifndef __ZIGZAG__ 
`define __ZIGZAG__



function automatic [5:0] en_zigzag(input [5:0] i);
    case(i)
         0: en_zigzag =  0;
         1: en_zigzag =  1;
         8: en_zigzag =  2;
        16: en_zigzag =  3;
         9: en_zigzag =  4;
         2: en_zigzag =  5;
         3: en_zigzag =  6;
        10: en_zigzag =  7;
        17: en_zigzag =  8;
        24: en_zigzag =  9;
        32: en_zigzag = 10;
        25: en_zigzag = 11;
        18: en_zigzag = 12;
        11: en_zigzag = 13;
         4: en_zigzag = 14;
         5: en_zigzag = 15;
        12: en_zigzag = 16;
        19: en_zigzag = 17;
        26: en_zigzag = 18;
        33: en_zigzag = 19;
        40: en_zigzag = 20;
        48: en_zigzag = 21;
        41: en_zigzag = 22;
        34: en_zigzag = 23;
        27: en_zigzag = 24;
        20: en_zigzag = 25;
        13: en_zigzag = 26;
         6: en_zigzag = 27;
         7: en_zigzag = 28;
        14: en_zigzag = 29;
        21: en_zigzag = 30;
        28: en_zigzag = 31;
        35: en_zigzag = 32;
        42: en_zigzag = 33;
        49: en_zigzag = 34;
        56: en_zigzag = 35;
        57: en_zigzag = 36;
        50: en_zigzag = 37;
        43: en_zigzag = 38;
        36: en_zigzag = 39;
        29: en_zigzag = 40;
        22: en_zigzag = 41;
        15: en_zigzag = 42;
        23: en_zigzag = 43;
        30: en_zigzag = 44;
        37: en_zigzag = 45;
        44: en_zigzag = 46;
        51: en_zigzag = 47;
        58: en_zigzag = 48;
        59: en_zigzag = 49;
        52: en_zigzag = 50;
        45: en_zigzag = 51;
        38: en_zigzag = 52;
        31: en_zigzag = 53;
        39: en_zigzag = 54;
        46: en_zigzag = 55;
        53: en_zigzag = 56;
        60: en_zigzag = 57;
        61: en_zigzag = 58;
        54: en_zigzag = 59;
        47: en_zigzag = 60;
        55: en_zigzag = 61;
        62: en_zigzag = 62;
        63: en_zigzag = 63;
        /*
         0: en_zigzag =  0;
         1: en_zigzag =  1;
         2: en_zigzag =  5;
         3: en_zigzag =  6;
         4: en_zigzag = 14;
         5: en_zigzag = 15;
         6: en_zigzag = 27;
         7: en_zigzag = 28;
         8: en_zigzag =  2;
         9: en_zigzag =  4;
        10: en_zigzag =  7;
        11: en_zigzag = 13;
        12: en_zigzag = 16;
        13: en_zigzag = 26;
        14: en_zigzag = 29;
        15: en_zigzag = 42;
        16: en_zigzag =  3;
        17: en_zigzag =  8;
        18: en_zigzag = 12;
        19: en_zigzag = 17;
        20: en_zigzag = 25;
        21: en_zigzag = 30;
        22: en_zigzag = 41;
        23: en_zigzag = 43;
        24: en_zigzag =  9;
        25: en_zigzag = 11;
        26: en_zigzag = 18;
        27: en_zigzag = 24;
        28: en_zigzag = 31;
        29: en_zigzag = 40;
        30: en_zigzag = 44;
        31: en_zigzag = 53;
        32: en_zigzag = 10;
        33: en_zigzag = 19;
        34: en_zigzag = 23;
        35: en_zigzag = 32;
        36: en_zigzag = 39;
        37: en_zigzag = 45;
        38: en_zigzag = 52;
        39: en_zigzag = 54;
        40: en_zigzag = 20;
        41: en_zigzag = 22;
        42: en_zigzag = 33;
        43: en_zigzag = 38;
        44: en_zigzag = 46;
        45: en_zigzag = 51;
        46: en_zigzag = 55;
        47: en_zigzag = 60;
        48: en_zigzag = 21;
        49: en_zigzag = 34;
        50: en_zigzag = 37;
        51: en_zigzag = 47;
        52: en_zigzag = 50;
        53: en_zigzag = 56;
        54: en_zigzag = 59;
        55: en_zigzag = 61;
        56: en_zigzag = 35;
        57: en_zigzag = 36;
        58: en_zigzag = 48;
        59: en_zigzag = 49;
        60: en_zigzag = 57;
        61: en_zigzag = 58;
        62: en_zigzag = 62;
        63: en_zigzag = 63;
        */
    endcase
endfunction

function automatic [5:0] de_zigzag(input [5:0] i);
    case(i)
         0: de_zigzag =  0;
         1: de_zigzag =  1;
         2: de_zigzag =  8;
         3: de_zigzag = 16;
         4: de_zigzag =  9;
         5: de_zigzag =  2;
         6: de_zigzag =  3;
         7: de_zigzag = 10;
         8: de_zigzag = 17;
         9: de_zigzag = 24;
        10: de_zigzag = 32;
        11: de_zigzag = 25;
        12: de_zigzag = 18;
        13: de_zigzag = 11;
        14: de_zigzag =  4;
        15: de_zigzag =  5;
        16: de_zigzag = 12;
        17: de_zigzag = 19;
        18: de_zigzag = 26;
        19: de_zigzag = 33;
        20: de_zigzag = 40;
        21: de_zigzag = 48;
        22: de_zigzag = 41;
        23: de_zigzag = 34;
        24: de_zigzag = 27;
        25: de_zigzag = 20;
        26: de_zigzag = 13;
        27: de_zigzag =  6;
        28: de_zigzag =  7;
        29: de_zigzag = 14;
        30: de_zigzag = 21;
        31: de_zigzag = 28;
        32: de_zigzag = 35;
        33: de_zigzag = 42;
        34: de_zigzag = 49;
        35: de_zigzag = 56;
        36: de_zigzag = 57;
        37: de_zigzag = 50;
        38: de_zigzag = 43;
        39: de_zigzag = 36;
        40: de_zigzag = 29;
        41: de_zigzag = 22;
        42: de_zigzag = 15;
        43: de_zigzag = 23;
        44: de_zigzag = 30;
        45: de_zigzag = 37;
        46: de_zigzag = 44;
        47: de_zigzag = 51;
        48: de_zigzag = 58;
        49: de_zigzag = 59;
        50: de_zigzag = 52;
        51: de_zigzag = 45;
        52: de_zigzag = 38;
        53: de_zigzag = 31;
        54: de_zigzag = 39;
        55: de_zigzag = 46;
        56: de_zigzag = 53;
        57: de_zigzag = 60;
        58: de_zigzag = 61;
        59: de_zigzag = 54;
        60: de_zigzag = 47;
        61: de_zigzag = 55;
        62: de_zigzag = 62;
        63: de_zigzag = 63;
    endcase
endfunction
`endif // __ZIGZAG__  _
