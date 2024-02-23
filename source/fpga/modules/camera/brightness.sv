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

module brightness #(
    X_WINDOW_START = 82,
    X_WINDOW_END = 98,
    Y_WINDOW_START = 82,
    Y_WINDOW_END = 98
)(
    input logic pixel_clock_in,
    input logic reset_n_in,

    input logic [9:0] pixel_red_data_in,
    input logic [9:0] pixel_green_data_in,
    input logic [9:0] pixel_blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [7:0] red_brightness_out,
    output logic [7:0] green_brightness_out,
    output logic [7:0] blue_brightness_out
);

logic [11:0] x_counter;
logic [11:0] y_counter;

logic previous_line_valid;
logic previous_frame_valid;

logic [265:0] average_red_brightness;
logic [265:0] average_green_brightness;
logic [265:0] average_blue_brightness;

always_ff @(posedge pixel_clock_in) begin

    previous_frame_valid <= frame_valid_in;

    if (frame_valid_in == 0 || reset_n_in == 0) begin

        x_counter <= 0;
        y_counter <= 0;
        previous_line_valid <= 0;

        if (previous_frame_valid) begin
            red_brightness_out <= average_red_brightness[265:258];
            green_brightness_out <= average_green_brightness[265:258];
            blue_brightness_out <= average_blue_brightness[265:258];
        end

        average_red_brightness <= 0;
        average_green_brightness <= 0;
        average_blue_brightness <= 0;

    end

    else begin

        previous_line_valid <= line_valid_in;

        // Increment counters
        if (line_valid_in) begin
            x_counter <= x_counter + 1;
        end

        else begin
            x_counter <= 0;

            if (previous_line_valid) begin
                y_counter <= y_counter + 1;
            end
        end

        // Calculate brightness only for the window
        if(line_valid_in &&
           x_counter >= X_WINDOW_START &&
           x_counter < X_WINDOW_END &&
           y_counter >= Y_WINDOW_START &&
           y_counter < Y_WINDOW_END) begin

            average_red_brightness <= average_red_brightness + pixel_red_data_in;
            average_green_brightness <= average_green_brightness + pixel_green_data_in;
            average_blue_brightness <= average_blue_brightness + pixel_blue_data_in;

        end

    end

end

endmodule