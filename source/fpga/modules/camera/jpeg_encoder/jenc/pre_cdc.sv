/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module pre_cdc (
    //128 bits
    input   logic [127:0]           in_data,
    input   logic [4:0]             in_bytes,
    input   logic                   in_tlast,
    input   logic                   in_valid,
    output  logic                   in_hold,
    input   logic [19:0]            in_size,

    //32 bits
    output  logic [31:0]            out_data,
    output  logic [2:0]             out_bytes,
    output  logic                   out_tlast,
    output  logic                   out_valid,
    input   logic                   out_hold,
    output  logic [19:0]            out_size,

    input   logic                   clk,
    input   logic                   resetn
);


// count words with 1 cycle gap
logic [2:0]             word_cnt;

always_comb in_hold     = in_valid & (word_cnt!=7 | out_hold);

// data out
// need to reverse data endianness 
logic [127:0]           in_data_rr;
always_comb 
    for(int i=0; i<16; i++)
        in_data_rr[8*i +: 8] = in_data[8*(15-i) +: 8];    

always_comb out_bytes   = 4;    // always 4
always_comb out_tlast   = in_tlast & word_cnt[2:1] == 3;
always_comb out_valid   = word_cnt[0];

always @(posedge clk)
if (!resetn)
    word_cnt <= 0;
else if (!out_hold & (word_cnt!=0 | in_valid)) begin
        word_cnt <= word_cnt + 1;
        out_data <= in_data_rr[32*word_cnt[2:1] +: 32];
        out_size <= ((in_size >> 4) << 4) | (word_cnt[2:1] << 2); // in_size 16 byte increments
end
endmodule
