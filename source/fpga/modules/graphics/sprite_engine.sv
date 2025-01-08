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

enum {NEW_PIXELS, DRAW, HOLD_OUTPUT_DATA, WAIT_FOR_NEW_PIXELS} state;
logic [9:0] current_x_pen_position;
logic [9:0] current_y_pen_position;
logic [4:0] pixels_remaining;

always_ff @(posedge clock_in) begin

    if (reset_n_in == 0) begin
        pixel_write_enable_out <= 0;
        state <= NEW_PIXELS;
    end

    else begin

        case (state)
            NEW_PIXELS: if (data_valid_in) begin
                if (enable_in) begin 
                    current_x_pen_position <= x_position_in;
                    current_y_pen_position <= y_position_in;
                end
                case (total_colors_in)
                    2: pixels_remaining <= 8;
                    4: pixels_remaining <= 4;
                    16: pixels_remaining <= 2;
                endcase

                state <= DRAW;

            end

            DRAW: begin

                pixels_remaining <= pixels_remaining - 1;

                // Calculate the cursor position and width wrapping
                if (current_x_pen_position < x_position_in + width_in - 1) begin
                    current_x_pen_position <= current_x_pen_position + 1;
                end

                else begin
                    current_x_pen_position <= x_position_in;
                    current_y_pen_position <= current_y_pen_position + 1;
                end

                // Output the pixel write address
                pixel_write_address_out <= current_x_pen_position + 
                                           (current_y_pen_position * 640);

                // Draw pixel based on which color mode we are in
                case (total_colors_in)
                    2: begin
                        case (pixels_remaining[2:0])
                            'b001: pixel_write_data_out <= data_in[0] == 0 ? 0 : data_in[0] + color_palette_offset_in;
                            'b010: pixel_write_data_out <= data_in[1] == 0 ? 0 : data_in[1] + color_palette_offset_in;
                            'b011: pixel_write_data_out <= data_in[2] == 0 ? 0 : data_in[2] + color_palette_offset_in;
                            'b100: pixel_write_data_out <= data_in[3] == 0 ? 0 : data_in[3] + color_palette_offset_in;
                            'b101: pixel_write_data_out <= data_in[4] == 0 ? 0 : data_in[4] + color_palette_offset_in;
                            'b110: pixel_write_data_out <= data_in[5] == 0 ? 0 : data_in[5] + color_palette_offset_in;
                            'b111: pixel_write_data_out <= data_in[6] == 0 ? 0 : data_in[6] + color_palette_offset_in;
                            'b000: pixel_write_data_out <= data_in[7] == 0 ? 0 : data_in[7] + color_palette_offset_in;
                        endcase
                    end

                    4: begin
                        case (pixels_remaining[1:0])
                            'b01: pixel_write_data_out <= data_in[1:0] == 0 ? 0 : data_in[1:0] + color_palette_offset_in;
                            'b10: pixel_write_data_out <= data_in[3:2] == 0 ? 0 : data_in[3:2] + color_palette_offset_in;
                            'b11: pixel_write_data_out <= data_in[5:4] == 0 ? 0 : data_in[5:4] + color_palette_offset_in;
                            'b00: pixel_write_data_out <= data_in[7:6] == 0 ? 0 : data_in[7:6] + color_palette_offset_in;
                        endcase
                    end

                    16: begin
                        case (pixels_remaining[0])
                            'b1: pixel_write_data_out <= data_in[3:0] == 0 ? 0 : data_in[3:0] + color_palette_offset_in;
                            'b0: pixel_write_data_out <= data_in[7:4] == 0 ? 0 : data_in[7:4] + color_palette_offset_in;
                        endcase
                    end
                endcase

                pixel_write_enable_out <= 1;

                state <= HOLD_OUTPUT_DATA;

            end
        
            HOLD_OUTPUT_DATA: begin

                if (pixels_remaining == 0) begin
                    state <= WAIT_FOR_NEW_PIXELS;    
                end

                else begin
                    state <= DRAW;
                end

            end

            WAIT_FOR_NEW_PIXELS: begin
                pixel_write_enable_out <= 0;

                if (data_valid_in == 0) begin
                    state <= NEW_PIXELS;
                end
            end

        endcase

    end

end
    
endmodule
