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
logic reset = 1;
logic [3:0] reset_counter = 0;

// 450 / (9-1) = 50Mhz
OSCA #(
    .HF_CLK_DIV("8"),
    .HF_OSC_EN("ENABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(clk)
);


spi spi (
    .*
);

always @(posedge clk) begin
    camera_main_clock = ~camera_main_clock;
end

endmodule