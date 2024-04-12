/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module dp_ram #(
    parameter DW = 18,
    parameter DEPTH = 360   // in words 
)(
    input logic[DW-1:0]                 wd,
    input logic[$clog2(DEPTH)-1:0]      wa,
    input logic                         we,
    output logic[DW-1:0]                rd,
    input logic[$clog2(DEPTH)-1:0]      ra,
    input logic                         re,
    input logic                         wclk,
    input logic                         rclk
);

logic[DW-1:0]       mem[0:DEPTH-1]; /* synthesis syn_ramstyle="Block_RAM" */

always @(posedge wclk)
begin
    // write
    if (we)
        mem[wa] <= wd;
end
always @(posedge rclk)
begin
    // read
    if (re)
        rd <= mem[ra];
end

endmodule
