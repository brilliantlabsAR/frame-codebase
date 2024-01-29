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

`include "../debayer.sv"
`include "image_gen.sv"

module debayer_tb;

logic pixel_clock = 0;
logic reset_n = 0;

logic [9:0] pixel_data;
logic line_valid;
logic frame_valid;

initial begin
    #10
    reset_n <= 1;
    #2500
    reset_n <= 0;
    #10
    $finish;
end

image_gen image_gen (
    .pixel_clock_in(pixel_clock),
    .reset_n_in(reset_n),

    .pixel_data_out(pixel_data),
    .line_valid(line_valid),
    .frame_valid(frame_valid)
);

debayer debayer (
    .pixel_clock_in(pixel_clock),
    .reset_n_in(reset_n),

    .pixel_data_in(pixel_data),
    .line_valid_in(line_valid),
    .frame_valid_in(frame_valid)
);

initial begin
    forever #1 pixel_clock <= ~pixel_clock;
end

initial begin
    $dumpfile("simulation/debayer_tb.fst");
    $dumpvars(0, debayer_tb);
end

endmodule