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

    output logic [17:0] pixel_data_address_out,
    input logic [9:0] pixel_data_value_in,
    output logic frame_complete_out,

    output logic display_clock_out,
    output logic display_hsync_out,
    output logic display_vsync_out,
    output logic [3:0] display_y_out,
    output logic [2:0] display_cb_out,
    output logic [2:0] display_cr_out
);

logic [15:0] column_counter = 0;
logic [15:0] row_counter = 0;
logic [17:0] pixel_counter = 0;

always_ff @(posedge clock_in) begin

    // Toggle display clock at 25MHz
    display_clock_out <= ~display_clock_out;

    // The rest of the logic also runs on a 25MHz clock
    if (display_clock_out) begin

        // Count columns
        if (column_counter < 857) begin
            column_counter <= column_counter + 1;
        end

        else begin 
            column_counter <= 0;

            // Count rows
            if (row_counter < 524) begin
                row_counter <= row_counter + 1;
            end

            else begin 
                row_counter <= 0;
            end

        end

        // Output the horizontal sync signal based on column number
        if (column_counter < 64) begin
            display_hsync_out <= 0;
        end

        else begin 
            display_hsync_out <= 1;
        end

        // Output the vertical sync signal based on line number
        if (row_counter < 6) begin
            display_vsync_out <= 0;
        end

        else begin
            display_vsync_out <= 1;
        end

        // Increment the pixel counter based on the row and column
        if (row_counter > 43 && row_counter < 444 &&
            column_counter > 120 && column_counter < 761) begin
            pixel_counter <= pixel_counter + 1;
        end

        // Reset pixel counter at the end of each frame
        else if (row_counter == 0 && column_counter == 0) begin 
            pixel_counter <= 0;
        end

        // Set the read address for the frame buffer
        pixel_data_address_out <= pixel_counter;

        // Set the pixel output value based on pixel data coming in
        display_y_out <= pixel_data_value_in[9:6];
        display_cb_out <= pixel_data_value_in[5:3];
        display_cr_out <= pixel_data_value_in[2:0];

    end

end

endmodule