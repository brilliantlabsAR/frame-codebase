/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
/*
Take 8-bit input samples (0..255)
Subtract 128 (-128..127)
Do N*N fDCT, where N=8
Output can have log2(N)+8 bits = 11 bits (-1024..1023)
DC coefficients are stored as a difference, so they can have 12 bits// Implementation of 2-D DCT, sharing one 1-D DCT
*/
module dct_2d #(
    parameter DW = 8,
    // Regular 1-D DCT adds +3 bits (8 -> 11) to coefficients, but 
    // AAN includes a factor of 3.923 on top of that, so +2 bits for 1-D (8+3+2=13) or +4 bits for 2-D (8+3+4=15)      
    parameter CW = DW + 5,
    parameter C2W = CW + 5,     // Coeffs after 2nd pass full size
    parameter QW = DW + 7       // Coeffs after 2nd are normlized to 15 bits (11 + 4)
)(
    input   logic signed[DW-1:0]    di[7:0], 
    input   logic                   di_valid,
    output  logic                   di_hold,
    input   logic [2:0]             di_cnt,
    output  logic signed[QW-1:0]    q[1:0],
    output  logic                   q_valid,
    input   logic                   q_hold,
    output  logic [4:0]             q_cnt,
    input   logic                   clk,
    input   logic                   resetn,
    input   logic                   clk_x22,
    input   logic                   resetn_x22
);

//------------------------------------------------------------------------------
// DCT0
//------------------------------------------------------------------------------
logic signed[CW-1:0] dct0_q[7:0]; 
logic [2:0] dct0_q_cnt;
logic dct0_q_valid;
logic dct0_q_hold;

dct_1d_aan #(
    .DW     (DW),
    .CW     (CW)
) dct_1d_0 (
    .di             (di),
    .di_valid       (di_valid),
    .di_hold        (di_hold),
    .di_cnt         (di_cnt),
    .q              (dct0_q),
    .q_valid        (dct0_q_valid),
    .q_hold         (dct0_q_hold),
    .q_cnt          (dct0_q_cnt),
    .q_cnt_zig_zag_timing (),
    .*
);

//------------------------------------------------------------------------------
// Transpose Mem
//------------------------------------------------------------------------------
logic signed[CW-1:0] dct1_d[7:0]; 
logic [2:0] dct1_d_cnt;
logic dct1_d_valid;
logic dct1_d_hold;

transpose #(.QW(CW)) transpose (
    .d          (dct0_q),
    .d_cnt      (dct0_q_cnt),
    .d_valid    (dct0_q_valid),
    .d_hold     (dct0_q_hold),
    .q          (dct1_d),
    .q_cnt      (dct1_d_cnt),
    .q_valid    (dct1_d_valid),
    .q_hold     (dct1_d_hold),
    .*
);

//------------------------------------------------------------------------------
// DCT1
//------------------------------------------------------------------------------
logic signed[C2W-1:0] dct1_q[7:0]; 
logic [QW-1:0] dct1_q_0[7:0]; 
logic [2:0] dct1_q_cnt;
logic [5:0] dct1_q_cnt_zig_zag_timing[7:0];
logic dct1_q_valid;
logic dct1_q_hold;

dct_1d_aan #(
    .DW     (CW),
    .CW     (C2W)
) dct_1d_1 (
    .di             (dct1_d),
    .di_valid       (dct1_d_valid),
    .di_hold        (dct1_d_hold),
    .di_cnt         (dct1_d_cnt),
    .q              (dct1_q),
    .q_valid        (dct1_q_valid),
    .q_hold         (dct1_q_hold),
    .q_cnt          (dct1_q_cnt),
    .q_cnt_zig_zag_timing (dct1_q_cnt_zig_zag_timing),
    .*
);

always_comb
    for (int j=0; j<8; j++)
        dct1_q_0[j] = dct1_q[j];

//------------------------------------------------------------------------------
// ZigZag Mem
//------------------------------------------------------------------------------

zigzag #(.QW(QW)) zigzag (
    .d          (dct1_q_0),
    .d_cnt      (dct1_q_cnt),
    .d_cnt_zig_zag_timing (dct1_q_cnt_zig_zag_timing),
    .d_valid    (dct1_q_valid),
    .d_hold     (dct1_q_hold),

    .q          (q),
    .q_cnt      (q_cnt),
    .q_valid    (q_valid),
    .q_hold     (q_hold),
    .*
);
endmodule
