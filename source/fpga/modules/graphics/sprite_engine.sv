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

    input logic sprite_draw_enable_in,
    input logic sprite_draw_data_valid_in,
    input logic [7:0] sprite_draw_data_in,

    output logic pixel_write_enable_out,
    output logic [17:0] pixel_write_address_out,
    output logic [3:0] pixel_write_data_out,

    output logic cursor_end_position_valid_out,
    output logic [9:0] cursor_end_x_position_out,
    output logic [9:0] cursor_end_y_position_out
 );

logic [1:0] data_valid_edge_monitor;
logic [4:0] pixels_remaining;
logic done_flag;

logic [9:0] cursor_current_x_position;
logic [9:0] cursor_current_y_position;

logic [9:0] cursor_left_boundary;
logic [9:0] cursor_right_boundary;

always_ff @(posedge clock_in) begin

    data_valid_edge_monitor <= {data_valid_edge_monitor[0], 
                                sprite_draw_data_valid_in};

    if (sprite_draw_enable_in == 0 || reset_n_in == 0) begin
        pixel_write_enable_out <= 0;
        cursor_end_position_valid_out <= 0;
        
        data_valid_edge_monitor <= 0;
        pixels_remaining <= 0;
        done_flag <= 0; 
    end

    else begin

        // On a new data byte
        if (data_valid_edge_monitor == 'b01) begin

            cursor_current_x_position <= cursor_start_x_position_in;
            cursor_current_y_position <= cursor_start_y_position_in;

            cursor_left_boundary <= cursor_start_x_position_in;
            cursor_right_boundary <= cursor_start_x_position_in + draw_width_in;

            case (color_mode_in)
                'b00: pixels_remaining <= 8;
                'b01: pixels_remaining <= 8;
                'b10: pixels_remaining <= 4;
                'b11: pixels_remaining <= 2;
            endcase
        
        end

        if (pixels_remaining > 0) begin
                
            pixels_remaining <= pixels_remaining - 1;

            // Calculate the cursor position and width wrapping
            if (cursor_current_x_position < cursor_right_boundary) begin
                cursor_current_x_position <= cursor_current_x_position + 1;
            end

            else begin
                cursor_current_x_position <= cursor_left_boundary;
                cursor_current_y_position <= cursor_current_y_position + 1;
            end

            // Output the new cursor value when we reach the last pixel
            if (pixels_remaining == 1) begin
                done_flag <= 1;
            end

            // Output the pixel write address
            pixel_write_address_out <= cursor_current_x_position + 
                                    (cursor_current_y_position * 640);

            // Draw the pixel TODO color mode and color offset
            pixel_write_data_out <= sprite_draw_data_in[3:0];

            // Enable the output
            pixel_write_enable_out <= 1;

        end

        // Disable output once done and update new cursor value
        if (done_flag) begin

            done_flag <= 0;
            
            pixel_write_enable_out <= 0;

            cursor_end_x_position_out <= cursor_current_x_position;
            cursor_end_y_position_out <= cursor_current_y_position;
            cursor_end_position_valid_out <= 1;

        end

        else begin
            cursor_end_position_valid_out <= 0;
        end

    end

end
    
endmodule