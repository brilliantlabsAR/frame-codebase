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
 
module crop (
    input logic pixel_clock_in,
    input logic reset_n_in,

    input logic [9:0] pixel_red_data_in,
    input logic [9:0] pixel_green_data_in,
    input logic [9:0] pixel_blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    input logic [7:0] pan_level,
    input logic [7:0] zoom_level,

    output logic [9:0] pixel_red_data_out,
    output logic [9:0] pixel_green_data_out,
    output logic [9:0] pixel_blue_data_out,
    output logic line_valid_out,
    output logic frame_valid_out
);

// Allows max 2048 x 2048 pixel input
logic [11:0] x_counter;
logic [11:0] y_counter;

logic [11:0] x_crop_start;
logic [11:0] x_crop_end;
logic [11:0] y_crop_start;
logic [11:0] y_crop_end;
logic [11:0] window_size;

localparam PAN_STEP = 'd28;

logic previous_line_valid_in;

always_comb begin
    case (zoom_level)
        1 : begin
            window_size = 720;
            y_crop_start = 0;
            y_crop_end = 720;
        end
        2 : begin
            window_size = 360;
            y_crop_start = 180;
            y_crop_end = 540;
        end
        3 : begin
            window_size = 240;
            y_crop_start = 240;
            y_crop_end = 480;
        end
        4 : begin
            window_size = 180;
            y_crop_start = 270;
            y_crop_end = 450;
        end
        default : begin
            window_size = 180;
            y_crop_start = 270;
            y_crop_end = 450;
        end
    endcase

    case (pan_level)
        -10 : x_crop_start = 0 * PAN_STEP;
        -9 : x_crop_start = 1 * PAN_STEP;
        -8 : x_crop_start = 2 * PAN_STEP;
        -7 : x_crop_start = 3 * PAN_STEP;
        -6 : x_crop_start = 4 * PAN_STEP;
        -5 : x_crop_start = 5 * PAN_STEP;
        -4 : x_crop_start = 6 * PAN_STEP;
        -3 : x_crop_start = 7 * PAN_STEP;
        -2 : x_crop_start = 8 * PAN_STEP;
        -1 : x_crop_start = 9 * PAN_STEP;
        0 : x_crop_start = 10 * PAN_STEP;
        1 : x_crop_start = 11 * PAN_STEP;
        2 : x_crop_start = 12 * PAN_STEP;
        3 : x_crop_start = 13 * PAN_STEP;
        4 : x_crop_start = 14 * PAN_STEP;
        5 : x_crop_start = 15 * PAN_STEP;
        6 : x_crop_start = 16 * PAN_STEP;
        7 : x_crop_start = 17 * PAN_STEP;
        8 : x_crop_start = 18 * PAN_STEP;
        9 : x_crop_start = 19 * PAN_STEP;
        10 : x_crop_start = 20 * PAN_STEP;
    endcase

    x_crop_end = x_crop_start + window_size;
end

always_ff @(posedge pixel_clock_in) begin

    if(reset_n_in == 0 || frame_valid_in == 0) begin

        line_valid_out <= 0;
        frame_valid_out <= 0;

        x_counter <= 0;
        y_counter <= 0;
        
        previous_line_valid_in <= 0;

    end
    
    else begin
        
        previous_line_valid_in <= line_valid_in;

        // Increment counters
        if (line_valid_in) begin
            x_counter <= x_counter + 1;
        end

        else begin
            x_counter <= 0;

            if (previous_line_valid_in) begin
                y_counter <= y_counter + 1;
            end
        end

        // Output cropped version
        if(line_valid_in &&
           x_counter >= x_crop_start &&
           x_counter < x_crop_end &&
           y_counter >= y_crop_start &&
           y_counter < y_crop_end) begin

            line_valid_out <= 1;
            pixel_red_data_out <= pixel_red_data_in;
            pixel_green_data_out <= pixel_green_data_in;
            pixel_blue_data_out <= pixel_blue_data_in;

        end

        else begin
            
            line_valid_out <= 0;
            pixel_red_data_out <= 0;
            pixel_green_data_out <= 0;
            pixel_blue_data_out <= 0;

        end

        frame_valid_out <= frame_valid_in;

    end
   
end
    
endmodule