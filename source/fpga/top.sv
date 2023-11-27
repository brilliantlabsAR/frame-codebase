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

`include "modules/camera/camera.sv"
`include "modules/graphics/display.sv"
`include "modules/spi/spi.sv"

module top (
    input logic spi_clock,
    output logic spi_data_out,
    input logic spi_data_in,
    input logic spi_select,

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
    output logic display_cb2,

    output logic camera_clock
);

logic clock;

OSCA #(
    .HF_CLK_DIV("8"), // 50 MHz
    .HF_OSC_EN("ENABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(clock)
);

spi spi (
    .spi_clock(spi_clock),
    .spi_select(spi_select),
    .spi_data_out(spi_data_out),
    .spi_data_in(spi_data_in)
);

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

always_ff @(posedge clock) begin
    camera_clock <= ~camera_clock; // 25MHz
end

endmodule