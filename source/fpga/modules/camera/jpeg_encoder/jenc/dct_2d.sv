/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module dct_2d #(
    parameter DW = 8,
    // Regular 1-D DCT includes a factor of sqrt(8) = 2.828. 
    // AAN includes a factor of 1/((cos(PI/16)/2)/(-a5 + a4 + 1)) = 1/0.254898 = 3.923.
    // Combined factor for 1-D DCT = 11.096, add +4 bits to DW
    // Combined factor for 2-D DCT = 123.128, add +7 bits to DW, or +3 bits to 1st DCT output CW
    // 1st DCT: DW = 8, CW = 12
    // 2nd DCT: DW = 12, CW = 15
    parameter CW = DW + 4,
    parameter QW = CW + 3       // Coeffs after 2nd pass
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

always_comb assert (DW == 8) else $error();
always_comb assert (CW == 12) else $error();
always_comb assert (QW == 15) else $error();
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
logic signed[QW-1:0] dct1_q[7:0]; 
logic [2:0] dct1_q_cnt;
logic dct1_q_valid;
logic dct1_q_hold;

dct_1d_aan #(
    .DW     (CW),
    .CW     (QW)
) dct_1d_1 (
    .di             (dct1_d),
    .di_valid       (dct1_d_valid),
    .di_hold        (dct1_d_hold),
    .di_cnt         (dct1_d_cnt),
    .q              (dct1_q),
    .q_valid        (dct1_q_valid),
    .q_hold         (dct1_q_hold),
    .q_cnt          (dct1_q_cnt),
    .*
);

//------------------------------------------------------------------------------
// ZigZag Mem
//------------------------------------------------------------------------------

zigzag #(.QW(QW)) zigzag (
    .d          (dct1_q),
    .d_cnt      (dct1_q_cnt),
    .d_valid    (dct1_q_valid),
    .d_hold     (dct1_q_hold),

    .q          (q),
    .q_cnt      (q_cnt),
    .q_valid    (q_valid),
    .q_hold     (q_hold),
    .*
);
endmodule
