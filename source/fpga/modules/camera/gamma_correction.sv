/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Chips & Scripts (rmetchev@ieee.org) 
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2024 Brilliant Labs Limited
 */
 
 module gamma_correction (
    input logic clock_in,
    input logic reset_n_in,

    input logic [9:0] red_data_in,
    input logic [9:0] green_data_in,
    input logic [9:0] blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [9:0] red_data_out,
    output logic [9:0] green_data_out,
    output logic [9:0] blue_data_out,
    output logic line_valid_out,
    output logic frame_valid_out
);

always_comb begin : passthrough
    red_data_out = red_data_in;
    green_data_out = green_data_in;
    blue_data_out = blue_data_in;
    line_valid_out = line_valid_in;
    frame_valid_out = frame_valid_in;
end

always_ff @(posedge clock_in) begin

    // if(reset_n_in == 0 || frame_valid_in == 0 || line_valid_in == 0) begin

    // end
    
    // else begin

    // end
   
end
    
endmodule