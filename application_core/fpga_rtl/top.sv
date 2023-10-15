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
`include "modules/graphics/graphics.sv"
`include "modules/spi/spi.sv"

module top (
    input logic sck,
    output logic cipo,
    input logic copi,
    input logic cs,

    output logic camera_main_clock
);

logic clk;

OSCA #(
    .HF_CLK_DIV("8"), // 50 MHz
    .HF_OSC_EN("ENABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(clk)
);

spi spi (
    .*
);

always @(posedge clk) begin
    camera_main_clock = ~camera_main_clock; // 25MHz
end

endmodule