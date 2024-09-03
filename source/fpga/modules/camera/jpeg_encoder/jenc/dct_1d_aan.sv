/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
// Implementation of AAN 1-D DCT, adopted from from https://unix4lyfe.org/dct-1d/
`include "jpeg_encoder.vh"
module dct_1d_aan #(
    parameter DW = 8,
    // Regular 1-D DCT includes a factor of sqrt(8) = 2.828. 
    // AAN includes a factor of 1/((cos(PI/16)/2)/(-a5 + a4 + 1)) = 1/0.254898 = 3.923.
    // Combined factor for 1-D DCT = 11.096, add +4 bits to DW
    // Combined factor for 2-D DCT = 123.128, add +7 bits to DW, or (7 - 4) = +3 bits to 1st DCT output
    // 1st DCT: DW = 8, CW = 12
    // 2nd DCT: DW = 12, CW = 15
    parameter CW = 12,
    parameter M_BITS = 12           // Precision of FP multiplier factors a1,2,3,4,5. a4 needs 13 bits, because a4 > 1
)(
    input   logic signed[DW-1:0]    di[7:0], 
    input   logic                   di_valid,
    output  logic                   di_hold,
    input   logic [2:0]             di_cnt,
    output  logic signed[CW-1:0]    q[7:0],
    output  logic                   q_valid,
    input   logic                   q_hold,
    output  logic [2:0]             q_cnt,
    input   logic                   clk,
    input   logic                   resetn
);

always_comb assert ((DW == 8 && CW == 12) || (DW == 12 && CW == 15)) else $error();
always_comb assert (M_BITS == 12) else $error();

//------------------------------------------------------------------------------
// Multplication constants
//------------------------------------------------------------------------------
/*
a1 = np.sqrt(.5)                                     = 0.707
a2 = np.sqrt(2.) * np.cos(3. / 16. * 2 * np.pi)      = 0.541
a3 = a1                                              = 0.707
a4 = np.sqrt(2.) * np.cos(1. / 16. * 2 * np.pi)      = 1.307
a5 = np.cos(3. / 16. * 2 * np.pi)                    = 0.383

Multiplication constants bit width M =  12
a1:    Binary = 101101010000
       Decimal = 2896
       Shifts = [4, 6, 8, 9, 11], Total = 5
       y[2] = (x[2] << 4) + (x[2] << 6) + (x[2] << 8) + (x[2] << 9) + (x[2] << 11);
a2:    Binary = 100010101001
       Decimal = 2217
       Shifts = [0, 3, 5, 7, 11], Total = 5
       y[4] = (x[4] << 0) + (x[4] << 3) + (x[4] << 5) + (x[4] << 7) + (x[4] << 11);
a3:    Binary = 101101010000
       Decimal = 2896
       Shifts = [4, 6, 8, 9, 11], Total = 5
       y[5] = (x[5] << 4) + (x[5] << 6) + (x[5] << 8) + (x[5] << 9) + (x[5] << 11);
a4:    Binary = 1010011101000
       Decimal = 5352
       Shifts = [3, 5, 6, 7, 10, 12], Total = 6
       y[6] = (x[6] << 3) + (x[6] << 5) + (x[6] << 6) + (x[6] << 7) + (x[6] << 10) + (x[6] << 12);
a5:    Binary = 11000011111
       Decimal = 1567
       Shifts = [0, 1, 2, 3, 4, 9, 10], Total = 7
       y[8] = (x[8] << 0) + (x[8] << 1) + (x[8] << 2) + (x[8] << 3) + (x[8] << 4) + (x[8] << 9) + (x[8] << 10);
*/
parameter MW = CW + M_BITS + 2;     // 26 or 29 (+1 bit for sign extension, +1 bit for a4 >= 1)
parameter signed[M_BITS+1:0] a1 = 2896;
parameter signed[M_BITS+1:0] a2 = 2217;
parameter signed[M_BITS+1:0] a3 = a1;
parameter signed[M_BITS+1:0] a4 = 5352;
parameter signed[M_BITS+1:0] a5 = 1567;
//------------------------------------------------------------------------------
// pipeline control
//------------------------------------------------------------------------------
logic [2:0] en;
logic i2_hold;
logic i1_hold;
logic i0_hold;

always_comb q_valid = en[2];
always @(posedge clk) 
if (!resetn)
    en <= 0;
else begin
    if (!i0_hold) en[0] <= di_valid;
    if (!i1_hold) en[1] <= en[0];
    if (!i2_hold) en[2] <= en[1];
end

// Pipeline row counter
logic [2:0] cntq[1:0];
always @(posedge clk) begin
    if (di_valid & !i0_hold) cntq[0] <= di_cnt;
    if (en[0] & !i1_hold) cntq[1] <= cntq[0];
    if (en[1] & !i2_hold) q_cnt <= cntq[1];
end
        
always_comb i2_hold = q_hold & en[2];
always_comb i1_hold = i2_hold & en[1];
always_comb i0_hold = i1_hold & en[0];
always_comb di_hold = i0_hold & di_valid;
//------------------------------------------------------------------------------
// Stage 0: Butterflies
//------------------------------------------------------------------------------
logic signed[CW-1:0]    i[7:0];
logic signed[CW-1:0]    b[7:0];
logic signed[CW-1:0]    c[8:0];

// rename inputs to match source code
always_comb
    for (int j=0; j<8; j++)
        i[j] = di[j];

// Stage 0a: 1st butterfly
always_comb begin
    b[0] = i[0] + i[7];
    b[1] = i[1] + i[6];
    b[2] = i[2] + i[5];
    b[3] = i[3] + i[4];
    b[4] = -i[4] + i[3];
    b[5] = -i[5] + i[2];
    b[6] = -i[6] + i[1];
    b[7] = -i[7] + i[0];
end

// Stage 0b: More butterfly
always @(posedge clk) if (di_valid & !i0_hold) begin
    c[0] <= b[0] + b[3];
    c[1] <= b[1] + b[2];
    c[2] <= -b[2] + b[1];
    c[3] <= -b[3] + b[0];
    c[4] <= -b[4] - b[5];
    c[5] <= b[5] + b[6];
    c[6] <= b[6] + b[7];
    c[7] <= b[7];
    c[8] <= -b[4] - b[5] + b[6] + b[7]; // Moved from: d_tmp[8] = c[4] + c[6];
end

//------------------------------------------------------------------------------
// Stage 1+2: 5x Multiplication - fractions scaled 1 -> 256, this expands
// calculation +8 bits
//
// Can be Expanded to 4 pipeline stages
//------------------------------------------------------------------------------
logic signed[MW-1:0]    d[8:0];
logic signed[MW-1:0]    d_tmp[8:0];

always_comb begin
    d_tmp[0] = c[0] + c[1];
    d_tmp[1] = -c[1] + c[0];
    //d[2] = (c[2] + c[3]) * a1;      // c[2] + c[3]
    d_tmp[2] = c[2] + c[3];
    d_tmp[3] = c[3];
    //d[4] = -c[4] * a2;              // c[4]
    d_tmp[4] = -c[4];
    //d[5] = c[5] * a3;
    d_tmp[5] = c[5];
    //d[6] = c[6] * a4;               // c[6]
    d_tmp[6] = c[6];
    d_tmp[7] = c[7];

    //d[8] = (c[4] + c[6]) * a5;      // (d[4] + d[6]) * a5;
    d_tmp[8] = c[4] + c[6];
end

always @(posedge clk) if (en[0] & !i1_hold) begin
    // scale 0,1,3,7 here due to lack of actual multiplication
    d[0] <= d_tmp[0] << M_BITS;
    d[1] <= d_tmp[1] << M_BITS;
    d[3] <= d_tmp[3] << M_BITS;
    d[7] <= d_tmp[7] << M_BITS;
    
`ifndef DCT_USE_DSP_MULT
    // 2,4,5,6 mults coded up explicitely
    //d[2] = (c[2] + c[3]) * a1;      // c[2] + c[3]
    if (M_BITS == 8)
        d[2] <= (d_tmp[2] << 0) + (d_tmp[2] << 2) + (d_tmp[2] << 4) + (d_tmp[2] << 5) + (d_tmp[2] << 7);
    else // M_BITS == 12
        d[2] <= (d_tmp[2] << 4) + (d_tmp[2] << 6) + (d_tmp[2] << 8) + (d_tmp[2] << 9) + (d_tmp[2] << 11);

    //d[4] = -c[4] * a2;              // c[4]
    if (M_BITS == 8)
        d[4] <= (d_tmp[4] << 1) + (d_tmp[4] << 3) + (d_tmp[4] << 7);
    else // M_BITS == 12
        d[4] <= (d_tmp[4] << 0) + (d_tmp[4] << 3) + (d_tmp[4] << 5) + (d_tmp[4] << 7) + (d_tmp[4] << 11);

    //d[5] = c[5] * a3;
    //a3 = a1
    if (M_BITS == 8)
        d[5] <= (d_tmp[5] << 0) + (d_tmp[5] << 2) + (d_tmp[5] << 4) + (d_tmp[5] << 5) + (d_tmp[5] << 7);
    else // M_BITS == 12
        d[5] <= (d_tmp[5] << 4) + (d_tmp[5] << 6) + (d_tmp[5] << 8) + (d_tmp[5] << 9) + (d_tmp[5] << 11);

    //d[6] = c[6] * a4;               // c[6]
    if (M_BITS == 8)
        d[6] <= (d_tmp[6] << 1) + (d_tmp[6] << 2) + (d_tmp[6] << 3) + (d_tmp[6] << 6) + (d_tmp[6] << 8);
    else // M_BITS == 12
        d[6] <= (d_tmp[6] << 3) + (d_tmp[6] << 5) + (d_tmp[6] << 6) + (d_tmp[6] << 7) + (d_tmp[6] << 10) + (d_tmp[6] << 12);

    //d[8] = (c[4] + c[6]) * a5;      // (d[4] + d[6]) * a5;
    if (M_BITS == 8)
        d[8] <= (d_tmp[8] << 0) + (d_tmp[8] << 5) + (d_tmp[8] << 6);
    else // M_BITS == 12
        d[8] <= (d_tmp[8] << 0) + (d_tmp[8] << 1) + (d_tmp[8] << 2) + (d_tmp[8] << 3) + (d_tmp[8] << 4) + (d_tmp[8] << 9) + (d_tmp[8] << 10);
`else
    d[2] <= d_tmp[2] * a1;
    d[4] <= d_tmp[4] * a2;
    d[5] <= d_tmp[5] * a3;
    d[6] <= d_tmp[6] * a4;
    d[8] <= d_tmp[8] * a5;
`endif //DCT_USE_DSP_MULT
end
    
//------------------------------------------------------------------------------
// Stage 3: Final butterflies
//------------------------------------------------------------------------------
logic signed[MW-1:0]    e[7:0];
logic signed[MW-1:0]    f[7:0];
logic signed[MW-1:0]    g[7:0];
logic signed[MW-1:0]    o[7:0];
logic signed[MW-1:0]    round = 1 << (M_BITS - 1);

// Stage 3a
always_comb begin
    e[0] = d[0];
    e[1] = d[1];
    e[2] = d[2];            // d[2] * a1
    e[3] = d[3];
    e[4] = d[4] - d[8];     // -d[4] * a2 - d[8]
    e[5] = d[5] + d[7];     // d[5] // d[5] * a3
    e[6] = d[6] - d[8];     // d[6] * a4 - d[8]
    e[7] = d[7] - d[5];     // d[7]
end

// stage eliminated
always_comb begin
    f[0] = e[0];
    f[1] = e[1];
    f[2] = e[2];    // e[2] + e[3]
    f[3] = e[3];    // e[3] - e[2]
    f[4] = e[4];
    f[5] = e[5];    // e[5] + e[7]
    f[6] = e[6];
    f[7] = e[7];    // e[7] - e[5]
end

// Stage 3b
always_comb begin
    g[0] = f[0];
    g[1] = f[1];
    g[2] = f[2] + f[3];     // f[2]
    g[3] = f[3] - f[2];     // f[3]
    g[4] = f[4] + f[7];
    g[5] = f[5] + f[6];
    g[6] = -f[6] + f[5];
    g[7] = f[7] - f[4];
    
    //if (en[2] & !i_hold) 
end

// Output un-swizzle, and add rounding bit (+ (0.5 << MBITS))
always @(posedge clk) if (en[1] & !i2_hold) begin
    o[0] <= g[0] + round;
    o[4] <= g[1] + round;
    o[2] <= g[2] + round;
    o[6] <= g[3] + round;
    o[5] <= g[4] + round;
    o[1] <= g[5] + round;
    o[7] <= g[6] + round;
    o[3] <= g[7] + round;
end

//------------------------------------------------------------------------------
// Output
//------------------------------------------------------------------------------
// Undo multiplier scaling, but not AAN scaling
always_comb
    for (int j=0; j<8; j++)
        q[j] = o[j] >> M_BITS;
endmodule
