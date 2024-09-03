/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module bit_pack (
    //packed code+coeff
    input   logic [63:0]            in_data,
    input   logic [6:0]             in_nbits,
    input   logic                   in_tlast,
    input   logic                   in_valid,
    output  logic                   in_hold,

    output  logic [31:0]            out_data,
    output  logic [2:0]             out_nbytes,
    output  logic                   out_tlast,
    output  logic                   out_valid,
    input   logic                   out_hold,

    input   logic                   clk,
    input   logic                   resetn
);

// 1.)  64-bit to 32-bit align: There will be extremely rarely more than 32 bits.
//      Stall during 1st 32 bits.
logic [31:0]            in32_data;
logic [5:0]             in32_nbits;
logic                   in32_tlast;
logic                   in32_valid;
logic                   in32_hold;
logic                   long_in; 

always @(posedge clk)
if (!resetn) begin
    in32_valid <= 0;
    long_in <= 0;
end
else if (~(in32_hold & in32_valid)) begin
    in32_valid <= in_valid;
    
    if (long_in)
        long_in <= 0;
    else if (in_valid & in_nbits > 32)
        long_in <= 1;
end

always @(posedge clk)
if (~(in32_hold & in32_valid))
    if (long_in) begin
        in32_nbits <= in_nbits - 32;
        in32_data <= in_data;
        in32_tlast <= in_tlast;
    end
    else if (in_valid)
        if (in_nbits > 32)  begin
            in32_nbits <= 32;
            in32_data <= in_data >> 32;
            in32_tlast <= 0;
        end
        else begin
            in32_nbits <= in_nbits;
            in32_data <= in_data >> 32;
            in32_tlast <= in_tlast;
        end

// Stall to split 32+ into 32 + remainder
always_comb in_hold = (in32_hold & in32_valid) | (~long_in & in_nbits > 32); // goes out


// 2.)  incoming: 32 bits max = 4 bytes
//      send data when more than 31 bits in storage
logic [5:0]             bit_count, next_bit_count, next_bit_count_incr, next_bit_count_decr;
logic [63:0]            bit_packer, next_bit_packer, next_bit_packer_load;
logic [5:0]             next_bit_packer_shift;
logic                   tlast_cycle, next_tlast_cycle;
logic                   next_out_tlast;

always_comb out_data = (bit_packer >> 32) | (out_tlast ? (32'hffffffff >> bit_count) : 0);
always_comb next_bit_count = bit_count + next_bit_count_incr - next_bit_count_decr;
always_comb next_bit_packer = (bit_packer << next_bit_packer_shift) | (next_bit_packer_load << (32 + next_bit_count_decr - bit_count));

always_comb begin
    if (out_tlast) begin
        next_bit_count_decr = bit_count;
        next_bit_packer_shift = 32;
    end
    else if (bit_count >= 32) begin
        next_bit_count_decr = 32;
        next_bit_packer_shift = 32;
    end
    else begin
        next_bit_count_decr = 0;
        next_bit_packer_shift = 0;
    end

    if (in32_valid & ~in32_hold) begin
        next_bit_count_incr = in32_nbits;
        next_bit_packer_load = in32_data;
    end
    else begin
        next_bit_count_incr = 0;
        next_bit_packer_load = 0;
    end

    if (tlast_cycle)
        next_tlast_cycle = ~out_tlast;
    else if (in32_valid)
        next_tlast_cycle = in32_tlast;
    else
        next_tlast_cycle = tlast_cycle;
end

always @(posedge clk)
if (!resetn) begin
    bit_count <= 0;
    tlast_cycle <= 0;
    out_tlast <= 0;
    out_valid <= 0;
    bit_packer <= 0;
end
else if (~(out_hold & out_valid)) begin   
    bit_count <= next_bit_count;
    tlast_cycle <= next_tlast_cycle;

    out_tlast <= next_tlast_cycle & next_bit_count <= 32;
    out_valid <= (next_tlast_cycle & next_bit_count <= 32) | next_bit_count >= 32; //always_comb out_valid = out_tlast | bit_count >= 32;

    bit_packer <= next_bit_packer;
end

always @(posedge clk)
if (~(out_hold & out_valid))
    out_nbytes <= (next_tlast_cycle & next_bit_count <= 32) ? (next_bit_count + 7) >> 3 : 4; // always_comb out_nbytes = out_tlast ? (bit_count + 7) >> 3 : 4;

always_comb in32_hold = (out_hold & out_valid) | (tlast_cycle & ~out_tlast);

endmodule
