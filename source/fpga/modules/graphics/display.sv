/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

module display (
    input logic clock_in,

    output logic clock_out = 1,
    output logic hsync = 0,
    output logic vsync = 0,
    output logic y0,
    output logic y1,
    output logic y2,
    output logic y3,
    output logic cr0,
    output logic cr1,
    output logic cr2,
    output logic cb0,
    output logic cb1,
    output logic cb2
);

assign y0 = 1;
assign y1 = 1;
assign y2 = 1;
assign y3 = 1;
assign cr0 = 1;
assign cr1 = 1;
assign cr2 = 1;
assign cb0 = 1;
assign cb1 = 1;
assign cb2 = 1;

logic [15:0] hsync_counter = 0;
logic [15:0] vsync_counter = 0;

logic internal_clock = 1;

always_ff @(posedge clock_in) begin
    
    clock_out <= ~clock_out;
    internal_clock <= ~internal_clock;

end

always_ff @(posedge internal_clock) begin

    if (hsync_counter < 857) hsync_counter <= hsync_counter + 1;

    else begin 

        hsync_counter <= 0;

        if (vsync_counter < 524) vsync_counter <= vsync_counter + 1;

        else vsync_counter <= 0;

    end

    // Output the horizontal sync signal based on column number
    if (hsync_counter < 64) hsync <= 0;

    else hsync <= 1;

    // Output the vertical sync signal based on line number
    if (vsync_counter < 6) vsync <= 0;

    else vsync <= 1;

end

endmodule