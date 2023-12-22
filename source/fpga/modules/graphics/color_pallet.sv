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

module color_pallet (
    input logic clock_in,
    input logic reset_n_in,

    input logic [3:0] pixel_index_in,
    output logic [9:0] yuv_color_out,

    input logic assign_color_enable_in,
    input logic [3:0] assign_color_index_in,
    input logic [9:0] assign_color_value_in
);
    
endmodule