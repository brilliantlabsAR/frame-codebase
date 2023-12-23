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

`ifndef RADIANT
`include "color_pallet.sv"
`include "display_driver.sv"
`include "frame_buffers.sv"
`include "sprite_engine.sv"
`endif

module graphics (
    input logic clock_in,
    input logic reset_n_in,

    input logic [7:0] op_code_in,
    input logic op_code_valid_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,

    output logic display_clock_out,
    output logic display_hsync_out,
    output logic display_vsync_out,
    output logic [3:0] display_y_out,
    output logic [2:0] display_cb_out,
    output logic [2:0] display_cr_out
);

logic [17:0] display_to_frame_buffer_read_address;
logic display_to_frame_buffer_frame_complete;

logic [3:0] frame_buffer_to_display_indexed_color;
logic [9:0] frame_buffer_to_display_real_color;

frame_buffers frame_buffers (
    .clock_in(clock_in),
    .reset_n_in(reset_n_in),

    .pixel_write_address_in(0),
    .pixel_write_data_in(0),
    .pixel_write_buffer_ready_out(),

    .pixel_read_address_in(display_to_frame_buffer_read_address),
    .pixel_read_data_out(frame_buffer_to_display_indexed_color),
    .pixel_read_frame_complete_in(display_to_frame_buffer_frame_complete),

    .switch_write_buffer_in(0)
);

color_pallet color_pallet (
    .clock_in(clock_in),
    .reset_n_in(reset_n_in),

    .pixel_index_in(frame_buffer_to_display_indexed_color),
    .yuv_color_out(frame_buffer_to_display_real_color),

    .assign_color_enable_in(0),
    .assign_color_index_in(0),
    .assign_color_value_in(0)
);

display_driver display_driver (
    .clock_in(clock_in),
    .reset_n_in(reset_n_in),

    .pixel_data_address_out(display_to_frame_buffer_read_address),
    .pixel_data_value_in(frame_buffer_to_display_real_color),
    .frame_complete_out(display_to_frame_buffer_frame_complete),

    .display_clock_out(display_clock_out),
    .display_hsync_out(display_hsync_out),
    .display_vsync_out(display_vsync_out),
    .display_y_out(display_y_out),
    .display_cb_out(display_cb_out),
    .display_cr_out(display_cr_out)
);

endmodule