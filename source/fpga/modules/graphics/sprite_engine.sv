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

 module sprite_engine (
    input logic clock_in,
    input logic reset_n_in,

    input logic [9:0] cursor_start_x_position_in,
    input logic [9:0] cursor_start_y_position_in,
    input logic [9:0] draw_width_in,
    input logic [1:0] color_mode_in,
    input logic [3:0] color_pallet_offset_in,

    input logic sprite_draw_valid_in,
    input logic [7:0] sprite_draw_data_in,

    output logic pixel_write_enable_out,
    output logic [17:0] pixel_write_address_out,
    output logic [3:0] pixel_write_data_out,

    output logic cursor_end_position_valid_out,
    output logic [9:0] cursor_end_x_position_out,
    output logic [9:0] cursor_end_y_position_out
 );

 initial begin
    pixel_write_enable_out = 0;
    pixel_write_address_out = 0;
    pixel_write_data_out = 0;
    cursor_end_position_valid_out = 0;
    cursor_end_x_position_out = 0;
    cursor_end_y_position_out = 0;
 end
    
 endmodule