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

module metering #(
    // 512x512 window in the center of a 720x720 image
    X_WINDOW_START = 104, 
    X_WINDOW_END = 616,
    Y_WINDOW_START = 104,
    Y_WINDOW_END = 616
)(
    input logic clock_in,
    input logic reset_n_in,

    input logic [9:0] red_data_in,
    input logic [9:0] green_data_in,
    input logic [9:0] blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [7:0] red_metering_out,
    output logic [7:0] green_metering_out,
    output logic [7:0] blue_metering_out
);

logic [11:0] x_counter;
logic [11:0] y_counter;

logic previous_line_valid;
logic previous_frame_valid;

logic [27:0] average_red_metering;
logic [27:0] average_green_metering;
logic [27:0] average_blue_metering;

always_ff @(posedge clock_in) begin

    previous_frame_valid <= frame_valid_in;

    if (frame_valid_in == 0 || reset_n_in == 0) begin

        x_counter <= 0;
        y_counter <= 0;
        previous_line_valid <= 0;

        if (previous_frame_valid) begin
            red_metering_out <= average_red_metering[27:20];
            green_metering_out <= average_green_metering[27:20];
            blue_metering_out <= average_blue_metering[27:20];
        end

        average_red_metering <= 0;
        average_green_metering <= 0;
        average_blue_metering <= 0;

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

        // Calculate metering only for the window
        if(line_valid_in &&
           x_counter >= X_WINDOW_START &&
           x_counter < X_WINDOW_END &&
           y_counter >= Y_WINDOW_START &&
           y_counter < Y_WINDOW_END) begin

            average_red_metering <= average_red_metering + red_data_in;
            average_green_metering <= average_green_metering + green_data_in;
            average_blue_metering <= average_blue_metering + blue_data_in;

        end

    end

end

endmodule