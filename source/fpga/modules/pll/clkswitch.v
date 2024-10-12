/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */

// Dynamic clock switch
// assuming many clock cycles between pulses, either clock domain

module clkswitch(
    input logic     i_clk_a, 
    input logic     i_clk_b, 
    input logic     i_areset_n, 
    input logic     i_sel, 
    output logic    o_clk
);

logic [1:0]	a_sel_reg, b_sel_reg;
logic a_sel, b_sel;
logic clk_a, clk_b;

// Synchronizer for A
always @(posedge i_clk_a or negedge i_areset_n)
if (!i_areset_n)    a_sel_reg <= 1;
else                a_sel_reg <= ~i_sel & ~b_sel;

// Synchronizer for B
always @(posedge i_clk_b or negedge i_areset_n)
if (!i_areset_n)    b_sel_reg <= 0;
else                b_sel_reg <= i_sel & ~a_sel;

// Gate for A
always_latch
if (!i_clk_a) a_sel <= a_sel_reg[1];
always_comb clk_a = a_sel & i_clk_a;

// Gate for B
always_latch
if (!i_clk_b) b_sel <= b_sel_reg[1];
always_comb clk_b = b_sel & i_clk_b;

// Or
always_comb	o_clk = clk_a | clk_b;

endmodule
