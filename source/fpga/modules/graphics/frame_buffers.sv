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
 
module frame_buffers (
    input logic [16:0] pixel_write_address_in,
    input logic [3:0] pixel_write_data_in,
    output logic pixel_write_buffer_ready_out,

    input logic [16:0] pixel_read_address_in,
    output logic [3:0] pixel_read_data_out,
    input logic pixel_read_frame_complete_in,

    input logic switch_write_buffer_in
);
    

endmodule