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
`include "../crop.sv"
`include "image_gen.sv"

module debayer_tb;

logic pixel_clock = 0;
logic reset_n = 0;

logic [9:0] pixel_data_gen_to_debayer;
logic line_valid_gen_to_debayer;
logic frame_valid_gen_to_debayer;

logic [11:0] pixel_red_data_debayer_to_crop;
logic [11:0] pixel_green_data_debayer_to_crop;
logic [11:0] pixel_blue_data_debayer_to_crop;
logic line_valid_debayer_to_crop;
logic frame_valid_debayer_to_crop;

initial begin
    #10
    reset_n <= 1;
    #80000
    reset_n <= 0;
    #10
    $finish;
end

image_gen image_gen (
    .pixel_clock_in(pixel_clock),
    .reset_n_in(reset_n),

    .pixel_data_out(pixel_data_gen_to_debayer),
    .line_valid(line_valid_gen_to_debayer),
    .frame_valid(frame_valid_gen_to_debayer)
);

debayer debayer (
    .pixel_clock_in(pixel_clock),
    .reset_n_in(reset_n),

    .pixel_data_in(pixel_data_gen_to_debayer),
    .line_valid_in(line_valid_gen_to_debayer),
    .frame_valid_in(frame_valid_gen_to_debayer),

    .pixel_red_data_out(pixel_red_data_debayer_to_crop),
    .pixel_green_data_out(pixel_green_data_debayer_to_crop),
    .pixel_blue_data_out(pixel_blue_data_debayer_to_crop),
    .line_valid_out(line_valid_debayer_to_crop),
    .frame_valid_out(frame_valid_debayer_to_crop)
);

logic [30:0] final_rgb_pixel;

assign final_rgb_pixel = {pixel_red_data_debayer_to_crop[9:0], 
                          pixel_green_data_debayer_to_crop[9:0],
                          pixel_blue_data_debayer_to_crop[9:0]};

always_ff @(negedge pixel_clock) begin
    
    if (line_valid_debayer_to_crop && frame_valid_debayer_to_crop) begin
        $display("%d", final_rgb_pixel);
    end

end

crop crop (
    .pixel_clock_in(pixel_clock),
    .reset_n_in(reset_n),

    .pixel_red_data_in(pixel_red_data_debayer_to_crop[9:0]),
    .pixel_green_data_in(pixel_green_data_debayer_to_crop[9:0]),
    .pixel_blue_data_in(pixel_blue_data_debayer_to_crop[9:0]),
    .line_valid_in(line_valid_debayer_to_crop),
    .frame_valid_in(frame_valid_debayer_to_crop)
);

initial begin
    forever #1 pixel_clock <= ~pixel_clock;
end

initial begin
    $dumpfile("simulation/debayer_tb.fst");
    $dumpvars(0, debayer_tb);
end

endmodule