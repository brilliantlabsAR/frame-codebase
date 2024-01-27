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

/*
 *   
 *       ↙ 1 pixel dummy starting column
 *   ┌────┬────┬────┬────┬────┐
 *   │ B  │ Gb │ B  │ Gb │ B  │ ← 1 pixel dummy starting row    This row is buffered in line_buffer[line_toggle]
 *   ├────╆━━━━╅────┼────┼────┤
 *   │ Gr ┃ R  ┃ Gr │ R  │ Gr │ R is calculated when..          This row is buffered in line_buffer[!line_toggle]
 *   ├────╄━━━━╃────╆━━━━╅────┤
 *   │ B  │ Gb │ B  ┃ Gb ┃ B  │ .. Gb is being read
 *   ├────┼────┼────╄━━━━╃────┤
 *   │ Gr │ R  │ Gr │ R  │ Gr │ ← 1 pixel dummy ending row
 *   └────┴────┴────┴────┴────┘
 *      ↑    ↑    ↑     ↖____↖ 
 *      │    │    │           2 pixel dummy ending column
 *      │    │    previous_pixel
 *      │    previous_previous_pixel
 *      previous_previous_previous_pixel
 *   
 */

module debayer #(
    X_RESOLUTION_IN = 'd15, // Include 1 left padding and 2 right padding
    Y_RESOLUTION_IN = 'd8 // Include 1 top padding and 1 bottom padding
)(
    input logic pixel_clock_in,
    input logic reset_n_in,

    input logic [9:0] pixel_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [9:0] pixel_red_data_out,
    output logic [9:0] pixel_green_data_out,
    output logic [9:0] pixel_blue_data_out,
    output logic line_valid_out,
	output logic frame_valid_out,

    output logic [29:0] average_brightness_out
);

// Allows max 2048 x 2048 pixel input.
logic [11:0] x_counter;
logic [11:0] y_counter;

logic line_toggle;
logic [9:0] line_buffer [0:1][0:X_RESOLUTION_IN - 1];
logic [9:0] previous_pixel;
logic [9:0] previous_previous_pixel;
logic [9:0] previous_previous_previous_pixel;

always_ff @(posedge pixel_clock_in) begin

    if(reset_n_in || frame_valid_in == 0) begin

        line_valid_out <= 0;
        frame_valid_out <= 0;

        x_counter <= 0;
        y_counter <= 0;
        
        line_toggle <= 0;

    end
    
    else begin
        
        if (line_valid_in) begin
            
            // Increment x and y counters for the entire window
            if (x_counter < X_RESOLUTION_IN) begin
                x_counter <= x_counter + 1;
            end 
            
            else begin
                x_counter <= 0;
                line_toggle <= ~line_toggle;
                if (y_counter < Y_RESOLUTION_IN) begin
                    y_counter <= y_counter + 1;
                end 
                
                else begin
                    y_counter <= 0;
                end
            end

            // Write the pixel into the line buffer (ignore the last column)
            if (x_counter < X_RESOLUTION_IN - 1) begin
                line_buffer[line_toggle][x_counter] <= pixel_data_in;
            end

            // Always buffer the last 3 pixels
            previous_previous_previous_pixel <= previous_previous_pixel;
            previous_previous_pixel <= previous_pixel;
            previous_pixel <= pixel_data_in;

            // Valid window for outputting pixels. 
            if (x_counter > 2 && y_counter > 1) begin
            
                // Debayer the pixel at x-2, y-1
                case ({x_counter[0], y_counter[0]})

                    // When input is Gb, output R
                    'b10: begin
                        pixel_red_data_out <= line_buffer[!line_toggle][x_counter - 2]; // Middle R

                        pixel_green_data_out <= (line_buffer[line_toggle][x_counter - 2] +  // Top Gb
                                                 line_buffer[!line_toggle][x_counter - 3] + // Left Gr
                                                 line_buffer[!line_toggle][x_counter - 1] + // Right Gr
                                                 previous_previous_pixel) >> 2;             // Bottom Gb

                        pixel_blue_data_out <= (line_buffer[line_toggle][x_counter - 3] +  // Top left B
                                                 line_buffer[line_toggle][x_counter - 1] + // Top right B
                                                 previous_previous_previous_pixel +        // Bottom left B
                                                 previous_pixel) >> 2;                     // Bottom right B
                    end

                    // When input is B, output Gr
                    'b00: begin
                        pixel_red_data_out <= (line_buffer[!line_toggle][x_counter - 3] +      // Left R
                                               line_buffer[!line_toggle][x_counter - 1]) >> 1; // right R

                        pixel_green_data_out <= line_buffer[!line_toggle][x_counter - 2]; // Middle Gr

                        pixel_blue_data_out <= (line_buffer[line_toggle][x_counter - 2] + // Top B
                                                previous_previous_pixel) >> 1;            // Bottom B
                    end

                    // When input is R, output Gb
                    'b11: begin
                        pixel_red_data_out <= (line_buffer[line_toggle][x_counter - 2] + // Top R
                                               previous_previous_pixel) >> 1;            // Bottom R

                        pixel_green_data_out <= line_buffer[!line_toggle][x_counter - 2]; // Middle Gb

                        pixel_blue_data_out <= (line_buffer[!line_toggle][x_counter - 3]+       // Left B
                                                line_buffer[!line_toggle][x_counter - 1]) >> 1; // Right B
                    end

                    // When input is Gr, output B
                    'b01: begin
                        pixel_red_data_out <= (line_buffer[line_toggle][x_counter - 3] + // Top left R
                                               line_buffer[line_toggle][x_counter - 1] + // Top righ R
                                               previous_previous_previous_pixel +        // Bottom left R
                                               previous_pixel) >> 1;                     // Bottom right R

                        pixel_green_data_out <= (line_buffer[line_toggle][x_counter - 2] +  // Top Gr
                                                 line_buffer[!line_toggle][x_counter - 3] + // Left Gb
                                                 line_buffer[!line_toggle][x_counter - 1] + // Right Gb
                                                 previous_previous_pixel) >> 2;             // Bottom Gr

                        pixel_blue_data_out <= line_buffer[!line_toggle][x_counter - 2]; // Middle B
                    end

                endcase

                line_valid_out <= 1;
                frame_valid_out <= 1;

            end

            else begin
                line_valid_out <= 0;
            end

        end

    end

end

endmodule