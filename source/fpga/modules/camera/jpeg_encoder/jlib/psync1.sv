/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */

// One-way pulse synchronizer for single isolated pulses, ie. no handshake/ack
// assuming many clock cycles between pulses, either clock domain
module psync1 (
    input logic     in,
    input logic     in_clk,
    input logic     in_reset_n,
    output logic    out,
    input logic     out_clk,
    input logic     out_reset_n
);

logic p;
always @(posedge in_clk)
if (!in_reset_n) p <= 0;
else if (in) p <= ~p;

logic [2:0] p_cdc;
always @(posedge out_clk)
if (!out_reset_n) p_cdc <= 0;
else p_cdc <= {p_cdc, p};

always_comb out = ^p_cdc[2:1];

endmodule
