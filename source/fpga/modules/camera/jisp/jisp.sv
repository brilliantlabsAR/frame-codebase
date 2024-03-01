/*
 * Top level for Jenc related ISP (mainly for simulation purposes)
 *
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
 module jisp #(
    parameter DW    = 8,
    parameter SENSOR_X_SIZE    = 720,
    parameter SENSOR_Y_SIZE    = 720
)(
    input   logic unsigned[DW-1:0]  rgb24[2:0], // to do: make pktized interface
    input   logic               rgb24_valid,
    output  logic               rgb24_hold,
    input   logic               frame_valid_in,
    input   logic               line_valid_in,

    output  logic [DW-1:0]      di[7:0], 
    output  logic               di_valid,
    input   logic               di_hold,
    output  logic [2:0]         di_cnt,

    input   logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_m1,
    input   logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_m1,
    input   logic               clk,
    input   logic               resetn
);

always_comb if (frame_valid_in) assert (x_size_m1[0]) else $fatal("Enforcing even image dimensions!");
always_comb if (frame_valid_in) assert (y_size_m1[0]) else $fatal("Enforcing even image dimensions!");

// for EBR simulations
`ifdef COCOTB_SIM
`ifdef USE_LATTICE_EBR
GSR GSR_INST (.GSR_N('1), .CLK(clk));
`endif
`endif

logic [DW-1:0]      yuv[2:0];
logic               yuv_valid;
logic               yuv_hold;
logic               frame_valid0;
logic               line_valid0;

logic [DW-1:0]      yuv420[2:0]; 
logic [2:0]         yuv420_valid;
logic               yuv420_hold;
logic               eof1;
logic[$clog2(SENSOR_X_SIZE)-1:0] yuv420_pixel_count;
logic[$clog2(SENSOR_Y_SIZE)-1:0] yuv420_line_count;

rgb2yuv rgb2yuv(
    .yuv,
    .yuv_valid,
    .yuv_hold,
    .frame_valid_out        (frame_valid0),
    .line_valid_out         (line_valid0),
    .*
);

subsample subsample (
    .yuvrgb_in              (yuv),
    .yuvrgb_in_valid        (yuv_valid),
    .yuvrgb_in_hold         (yuv_hold),
    .frame_valid_in         (frame_valid0),
    .line_valid_in          (line_valid0),

    .yuvrgb_out             (yuv420),
    .yuvrgb_out_valid       (yuv420_valid),
    .yuvrgb_out_hold        (yuv420_hold),
    .eof_out                (eof1),
    .yuvrgb_out_pixel_count (yuv420_pixel_count),
    .yuvrgb_out_line_count  (yuv420_line_count),

    .*
);

mcu_buffer mcu_buffer(
    .yuvrgb_in              (yuv420),
    .yuvrgb_in_valid        (yuv420_valid),
    .yuvrgb_in_hold         (yuv420_hold),
    .eof_in                 (eof1),
    .yuvrgb_in_pixel_count  (yuv420_pixel_count),
    .yuvrgb_in_line_count   (yuv420_line_count),
    .*
);
endmodule
