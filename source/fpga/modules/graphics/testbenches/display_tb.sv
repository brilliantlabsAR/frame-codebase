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

`timescale 10ns / 10ns

`include "modules/graphics/display.sv"

module display_tb (
    output logic display_clock,
    output logic display_hsync,
    output logic display_vsync,
    output logic display_y0,
    output logic display_y1,
    output logic display_y2,
    output logic display_y3,
    output logic display_cr0,
    output logic display_cr1,
    output logic display_cr2,
    output logic display_cb0,
    output logic display_cb1,
    output logic display_cb2
);

logic clock = 0;
initial begin : clock_25MHz
    forever #2 clock <= ~clock;
end

initial begin
    $dumpfile("sim/display_tb.fst");
    $dumpvars(0, display_tb);
end

initial begin
    #10000000
    $finish;
end

display display (
    .clock_in(clock),
    .clock_out(display_clock),
    .hsync(display_hsync),
    .vsync(display_vsync),
    .y0(display_y0),
    .y1(display_y1),
    .y2(display_y2),
    .y3(display_y3),
    .cr0(display_cr0),
    .cr1(display_cr1),
    .cr2(display_cr2),
    .cb0(display_cb0),
    .cb1(display_cb1),
    .cb2(display_cb2)
);

endmodule