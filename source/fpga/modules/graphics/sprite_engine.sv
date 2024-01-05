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
    input logic enable_in,

    input logic [9:0] x_position_in,
    input logic [9:0] y_position_in,
    input logic [9:0] width_in,
    input logic [4:0] total_colors_in,
    input logic [3:0] color_palette_offset_in,

    input logic data_valid_in,
    input logic [7:0] data_in,

    output logic pixel_write_enable_out,
    output logic [17:0] pixel_write_address_out,
    output logic [3:0] pixel_write_data_out
 );

logic [1:0] pixel_pulse_counter;
logic [1:0] enable_edge_monitor;
logic [1:0] data_valid_edge_monitor;

logic [4:0] pixels_remaining;

logic [9:0] current_x_pen_position;
logic [9:0] current_y_pen_position;

always_ff @(posedge clock_in) begin

    if (reset_n_in == 0 || enable_in == 0) begin
        pixel_write_enable_out <= 0;

        pixel_pulse_counter <= 0;
        enable_edge_monitor <= 0;
        data_valid_edge_monitor <= 0;
        
        pixels_remaining <= 0;
    end

    else begin

        pixel_pulse_counter <= pixel_pulse_counter + 1;

        // Every 2 clocks
        if (pixel_pulse_counter == 'b01) begin

            pixel_pulse_counter <= 0;

            enable_edge_monitor <= {enable_edge_monitor[0], 
                                    enable_in};

            data_valid_edge_monitor <= {data_valid_edge_monitor[0], 
                                        data_valid_in};

            // On a new draw sequence
            if (enable_edge_monitor == 'b01) begin
                current_x_pen_position <= x_position_in;
                current_y_pen_position <= y_position_in;
            end

            // On a new data byte
            if (data_valid_edge_monitor == 'b01) begin
                case (total_colors_in)
                    1: pixels_remaining <= 8;
                    4: pixels_remaining <= 4;
                    16: pixels_remaining <= 2;
                endcase
            end

            // Draw pixels
            if (pixels_remaining > 0) begin
                    
                pixels_remaining <= pixels_remaining - 1;

                // Calculate the cursor position and width wrapping
                if (current_x_pen_position < x_position_in + width_in) begin
                    current_x_pen_position <= current_x_pen_position + 1;
                end

                else begin
                    current_x_pen_position <= x_position_in;
                    current_y_pen_position <= current_y_pen_position + 1;
                end

                // Output the pixel write address
                pixel_write_address_out <= current_x_pen_position + 
                                        (current_y_pen_position * 640);

                // Draw the pixel TODO color mode and color offset
                pixel_write_data_out <= data_in[3:0];

                pixel_write_enable_out <= 1;

            end

            else begin
                pixel_write_enable_out <= 0;
            end

        end

    end

end
    
endmodule