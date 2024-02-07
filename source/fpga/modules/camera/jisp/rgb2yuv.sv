/*
 * RGB to Y Cb Cr conversion
 *
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
 module rgb2yuv #(
    parameter DW    = 8,
    parameter MW    = 8
)(
    input   logic unsigned[DW-1:0]  rgb24[2:0], // to do: make pktized interface
    input   logic               rgb24_valid,
    output  logic               rgb24_hold,
    input   logic               frame_valid_in,
    input   logic               line_valid_in,
    output  logic unsigned[DW-1:0]  yuv[2:0], // to do: make pktized interface
    output  logic               yuv_valid,
    input   logic               yuv_hold,
    output  logic               frame_valid_out,
    output  logic               line_valid_out,
    input   logic               clk,
    input   logic               resetn
);

localparam YW = DW + 1;

/*
Color space conversion matrix: 
Spec: Y-matrix = [0.299 0.587 0.114], KCb = 0.5643340857787811, KCr = 0.7132667617689015
8-bit precision: Y-matrix = [ 77 150  29], KCb =144, KCr = 182(!manually adjusted!)
Binary: Y-matrix = ['01001101', '10010110', '00011101'], KCb =10010000, KCr = 10110110(!manually adjusted!)

Plus constant [0, 128, 128].T 

U = B-Y, Cb = 128 + U/2(1-Kb) = 128 + KCb*U, KCb = 1/(2*(1-0.114)) = 1/(2*0.886) = 1/1.772 = 0.5643340857787811
V = R-Y, Cr = 128 + V/2(1-Kr) = 128 + KCr*V, KCr = 1/(2*(1-0.299)) = 1/(2*0.701) = 1/1.402 = 0.7132667617689015
*/

//  Stage 0: 
//  Calculate Kr*R, Kg*G, Kb*B
//  8 bits + 8 bits
logic unsigned[DW+MW-1:0]   k_rgb1[2:0], k_rgb0[2:0]; // to do: make pktized interface
logic unsigned[DW-1:0]      r0, b0; // to do: make pktized interface
logic s0_valid;
logic frame_valid_0;
logic line_valid_0;

always_comb begin
    k_rgb0[0] = (rgb24[0] << 6) + (rgb24[0] << 3) + (rgb24[0] << 2) + (rgb24[0] << 0);       // R: 01001101
    k_rgb0[1] = (rgb24[1] << 7) + (rgb24[1] << 4) + (rgb24[1] << 2) + (rgb24[1] << 1);       // G: 10010110
    k_rgb0[2] = (rgb24[2] << 4) + (rgb24[2] << 3) + (rgb24[2] << 2) + (rgb24[2] << 0);       // B: 00011101
end

always @(posedge clk)
if (rgb24_valid & !yuv_hold) begin
    r0 <= rgb24[0];
    b0 <= rgb24[2];
    k_rgb1[0] <= k_rgb0[0];
    k_rgb1[1] <= k_rgb0[1];
    k_rgb1[2] <= k_rgb0[2];
end

always @(posedge clk)
if (!resetn) begin
    s0_valid <= 0;
    frame_valid_0 <= 0;
    line_valid_0 <= 0;
end
else if (!yuv_hold) begin
    s0_valid <= rgb24_valid;
    frame_valid_0 <= frame_valid_in;
    line_valid_0 <= line_valid_in;
end

//  Stage 1: 
//  Calculate Y = (Kr*R, Kg*G, Kb*B)
//  Calculate U = B - Y and V = R - Y .. range is 2*0.886*255=1.772*255 or +/-225.93 and 2*0.701*255=1.402*255 or +/-178.755, so signed 9-bits
//  Y should stay in the 0..255 range even after the addition (77 150  29)*255 = 256*255
logic unsigned[YW+MW-1:0]   sum_k_rgb;
logic unsigned[DW-1:0]      y0, y1;
logic signed[YW-1:0]        u0, v0, u1, v1;
logic s1_valid;
logic frame_valid_1;
logic line_valid_1;

always_comb begin
    sum_k_rgb = k_rgb1[0] + k_rgb1[1] + k_rgb1[2];
    y0 = (sum_k_rgb + (1<<(MW - 1))) >> MW;
    u0 = b0 - y0;
    v0 = r0 - y0;
end

always @(posedge clk)
if (s0_valid & !yuv_hold) begin
    y1 <= y0;
    u1 <= u0;
    v1 <= v0;
end

always @(posedge clk)
if (!resetn) begin
    s1_valid <= 0;
    frame_valid_1 <= 0;
    line_valid_1 <= 0;
end
else if (!yuv_hold) begin
    s1_valid <= s0_valid;
    frame_valid_1 <= frame_valid_0;
    line_valid_1 <= line_valid_0;
end

//  Stage 2:
// Calculate  Cb = 128 + KCb*U = 128 + 144*U, Cr = 128 + KCr*V = 128 + 182*V
// mult range: 144*U ~= 144*225.93 ~= 127.085625 ~= 127, 182*V ~= 182*178.755 ~= 127.083632812 ~= 127
// --> 8 bits are enough!
logic signed[YW+MW-1:0]     cb1, cb1_, cr1;
logic unsigned[DW-1:0]      y2, cb2, cr2;

always_comb begin
    cb1 = (128 << MW) + (u1 << 7) + (u1 << 4);                                      // KCb = 10010000
    cr1 = (128 << MW) + (v1 << 7) + (v1 << 5) + (v1 << 4) + (v1 << 2) + (v1 << 1);  // KCr = 10110110
end

always @(posedge clk)
if (s1_valid & !yuv_hold) begin
    yuv[0] <= y1;
    yuv[1] <= (cb1 + (1<<(MW - 1))) >> MW;
    yuv[2] <= (cr1 + (1<<(MW - 1))) >> MW;
end

always @(posedge clk)
if (!resetn) begin
    yuv_valid <= 0;
    frame_valid_out <= 0;
    line_valid_out <= 0;
end
else if (!yuv_hold) begin
    yuv_valid <= s1_valid;
    frame_valid_out <= frame_valid_1;
    line_valid_out <= line_valid_1;
end
always_comb rgb24_hold = yuv_hold;
endmodule
