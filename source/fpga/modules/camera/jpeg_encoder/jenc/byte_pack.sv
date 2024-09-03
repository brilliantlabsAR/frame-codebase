/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module byte_pack (
    //packed code+coeff
    input   logic [5:0]             codecoeff_length,
    input   logic [51:0]            codecoeff,
    input   logic                   codecoeff_tlast,
    input   logic                   codecoeff_valid,
    output  logic                   codecoeff_hold,

    output  logic [31:0]            out_data,
    output  logic                   out_tlast,
    output  logic                   out_valid,
    input   logic                   out_hold,

    input   logic                   clk,
    input   logic                   resetn
);

// Pack up to 52 bits into 4 byte words
logic [31:0]            data_0;
logic [2:0]             nbytes_0;
logic                   tlast_0;
logic                   valid_0;
logic                   hold_0;

bit_pack bit_pack_0 (
    .in_data                ({codecoeff, 12'h0}),
    .in_nbits               ({1'b0, codecoeff_length}),
    .in_tlast               (codecoeff_tlast),
    .in_valid               (codecoeff_valid),
    .in_hold                (codecoeff_hold),

    .out_data               (data_0),
    .out_nbytes             (nbytes_0),
    .out_tlast              (tlast_0),
    .out_valid              (valid_0),
    .out_hold               (hold_0 & valid_0),

    .*
);

// pad 0xFF with 0x00
logic [63:0]            data_1;
logic [3:0]             nbytes_1;
logic                   tlast_1;
logic                   valid_1;
logic                   hold_1;

ff00 ff00 ( 
    .in_data                (data_0),
    .in_nbytes              (nbytes_0),
    .in_tlast               (tlast_0),
    .in_valid               (valid_0),
    .in_hold                (hold_0),

    .out_data               (data_1),
    .out_nbytes             (nbytes_1),
    .out_tlast              (tlast_1),
    .out_valid              (valid_1),
    .out_hold               (hold_1 & valid_1),

    .*
);

// Pack up to 8 bytes into 4 byte words
bit_pack bit_pack_1 (
    .in_data                (data_1),
    .in_nbits               ({nbytes_1, 3'h0}),     // bytes -> bits
    .in_tlast               (tlast_1),
    .in_valid               (valid_1),
    .in_hold                (hold_1),

    .out_nbytes             ( ),    // always full 32 bits/4 bytes
    .out_hold               (out_hold & out_valid),

    .*
);

endmodule
