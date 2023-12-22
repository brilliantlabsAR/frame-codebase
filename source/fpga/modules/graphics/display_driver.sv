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

module display_driver (
    input logic clock_in,
    input logic reset_n_in,

    output logic [16:0] pixel_data_address_out,
    input logic [9:0] pixel_data_value_in,
    output logic frame_complete_out,

    output logic display_clock_out,
    output logic display_hsync_out,
    output logic display_vsync_out,
    output logic [3:0] display_y_out,
    output logic [2:0] display_cb_out,
    output logic [2:0] display_cr_out
);

logic [15:0] hsync_counter = 0;
logic [15:0] vsync_counter = 0;
logic [16:0] pixel_address_counter = 0;

always_ff @(posedge clock_in) begin

    // Toggle display clock at 25MHz
    display_clock_out <= ~display_clock_out;

    // The rest of the logic also runs on a 25MHz clock
    if (display_clock_out) begin

        // Set the pixel output value
        display_y_out <= pixel_data_value_in[9:6];
        display_cb_out <= pixel_data_value_in[5:3];
        display_cr_out <= pixel_data_value_in[2:0];

        if (hsync_counter < 857) hsync_counter <= hsync_counter + 1;

        else begin 

            hsync_counter <= 0;

            if (vsync_counter < 524) vsync_counter <= vsync_counter + 1;

            else vsync_counter <= 0;

        end

        // Output the horizontal sync signal based on column number
        if (hsync_counter < 64) display_hsync_out <= 0;

        else display_hsync_out <= 1;

        // Output the vertical sync signal based on line number
        if (vsync_counter < 6) display_vsync_out <= 0;

        else display_vsync_out <= 1;

    end

end

endmodule