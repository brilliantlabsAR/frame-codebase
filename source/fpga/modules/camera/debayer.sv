/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

/*
 *   
 *     +-- 1 pixel dummy starting column
 *     |
 *     v
 *   +----+----+----+----+
 *   | B  | Gb | B  | Gb | <-- 1 pixel dummy starting row    This row is buffered in line_buffer[line_toggle]
 *   +----+----+----+----+
 *   | Gr | R* | Gr | R  | R is calculated when..          This row is buffered in line_buffer[!line_toggle]
 *   +----+----+----+----+
 *   | B  | Gb | B* | Gb | .. B is being read
 *   +----+----+----+----+
 *   | Gr | R  | Gr | R  | <-- 1 pixel dummy ending row
 *   +----+----+----+----+
 *      ^    ^    ^    ^ 
 *      |    |    |    |
 *      |    |    |    +-- 1 pixel dummy ending column
 *      |    |    previous_pixel
 *      |    previous_previous_pixel
 *      previous_previous_previous_pixel
 *   
 */

module debayer_buffer (
    input logic pixel_clock_in,

    // Reads 2 10bit word at the address
    input logic [10:0] x_counter,
    input logic [10:0] y_counter, // = line index
    input logic line_valid_in,
    output logic [9:0] line_buffer_read_data[1:0],

    // Writes one 10bit word at the address
    input logic [10:0] previous_x_counter,
    input logic [10:0] previous_y_counter, // = line index
    input logic we,
    input logic [9:0] previous_pixel
);

logic [17:0] mem [0:727] /* synthesis ram_style = "Block_RAM" */;

// Read
always_ff @(posedge pixel_clock_in) if (line_valid_in) begin
    line_buffer_read_data[0] <= mem[x_counter][17:9] << 1;
    line_buffer_read_data[1] <= mem[x_counter][8:0] << 1;
end

// Write
always_ff @(posedge pixel_clock_in) if (we) begin
    if (previous_y_counter[0] == 0)
        mem[previous_x_counter] <= {previous_pixel[9:1], line_buffer_read_data[1][9:1]};
    else
        mem[previous_x_counter] <= {line_buffer_read_data[0][9:1], previous_pixel[9:1]};
end

endmodule

module debayer (
    input logic pixel_clock_in,
    input logic pixel_reset_n_in,

    input logic x_crop_start_lsb, // Just the LSB to allow odd/even start addresses
    input logic y_crop_start_lsb, // Just the LSB to allow odd/even start addresses

    input logic [9:0] bayer_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [9:0] red_data_out,
    output logic [9:0] green_data_out,
    output logic [9:0] blue_data_out,
    output logic line_valid_out,
    output logic frame_valid_out
);

// Allows max 2048 x 2048 pixel input
logic [10:0] x_counter;
logic [10:0] y_counter;
logic [10:0] previous_x_counter;
logic [10:0] previous_y_counter;

logic last_line_valid_in;
logic we;
logic last_frame_valid_in;

logic [9:0] previous_pixel;
logic [9:0] previous_previous_pixel;
logic [9:0] previous_previous_previous_pixel;

logic [9:0] line_buffer_read_data[1:0];
logic [9:0] previous_line_buffer_read_data[1:0];
logic [9:0] previous_previous_line_buffer_read_data[1:0];


logic [10:0] line_buffer_read_address;
logic line_index;
logic [10:0] line_buffer_write_address;
logic [9:0] line_buffer_write_data;

logic [11:0] pixel_red_data;
logic [11:0] pixel_green_data;
logic [11:0] pixel_blue_data;

assign red_data_out = pixel_red_data[9:0];
assign green_data_out = pixel_green_data[9:0];
assign blue_data_out = pixel_blue_data[9:0];

debayer_buffer debayer_buffer (.*);

always_ff @(posedge pixel_clock_in) begin

    // 1st stage: Count pixels/lines (read + write stage)
    if(pixel_reset_n_in == 0) begin
        last_frame_valid_in <= 0;
        last_line_valid_in <= 0;
        we <= 0;
        x_counter <= 0;
        y_counter <= 0;
    end
    else begin
        last_frame_valid_in <= (y_counter > (1 + y_crop_start_lsb)) & frame_valid_in;
        if(frame_valid_in == 0) begin
            last_line_valid_in <= 0;
            we <= 0;
            x_counter <= x_crop_start_lsb;
            y_counter <= y_crop_start_lsb;
        end
        else begin
            last_line_valid_in <= (x_counter > (1 + x_crop_start_lsb)) & line_valid_in;
            we <= line_valid_in;
            if (line_valid_in) begin
                x_counter <= x_counter + 1;
                previous_x_counter <= x_counter;
                previous_y_counter <= y_counter;

                // Always buffer the last 3 input pixels
                previous_previous_previous_pixel <= previous_previous_pixel;
                previous_previous_pixel <= previous_pixel;
                previous_pixel <= bayer_data_in[9:1] << 1; // truncate to 9 bits right away

                // Always buffer the last 2 line buffer pixels
                previous_previous_line_buffer_read_data[1] <= previous_line_buffer_read_data[1];
                previous_previous_line_buffer_read_data[0] <= previous_line_buffer_read_data[0];
                previous_line_buffer_read_data[1] <= line_buffer_read_data[1];
                previous_line_buffer_read_data[0] <= line_buffer_read_data[0];
            end
            else begin
                x_counter <= x_crop_start_lsb;

                // Increment y at the falling edge of each line_valid
                if (last_line_valid_in) begin
                    y_counter <= y_counter + 1;
                end
            end
        end
    end
    
    // 2nd stage: Calculate RGB with data from memory and input
    if(pixel_reset_n_in == 0)
        frame_valid_out <= 0;
    else
        frame_valid_out <= last_frame_valid_in;

    if(pixel_reset_n_in == 0 || last_frame_valid_in == 0)
        line_valid_out <= 0;
    else begin
        line_valid_out <= last_line_valid_in;
        if (last_line_valid_in) begin
            case ({previous_x_counter[0], previous_y_counter[0]})
                // When input is B, output R
                'b00: begin
                    pixel_red_data  <= previous_line_buffer_read_data[1];                   // Middle R

                    pixel_green_data <= (previous_line_buffer_read_data[0] +                // Top Gb
                                            previous_previous_line_buffer_read_data[1] +    // Left Gr
                                            line_buffer_read_data[1] +                      // Right Gr
                                            previous_previous_pixel) >> 2;                  // Bottom Gb

                    pixel_blue_data <= (previous_previous_line_buffer_read_data[0] +        // Top left B
                                            line_buffer_read_data[0] +                      // Top right B
                                            previous_previous_previous_pixel +              // Bottom left B
                                            previous_pixel) >> 2;                           // Bottom right B
                end

                // When input is Gb, output Gr
                'b10: begin
                    pixel_red_data <= (previous_previous_line_buffer_read_data[1] +         // Left R
                                           line_buffer_read_data[1]) >> 1;                  // Right R

                    pixel_green_data <= previous_line_buffer_read_data[1];                  // Middle Gr

                    pixel_blue_data <= (previous_line_buffer_read_data[0] +                 // Top B
                                            previous_previous_pixel) >> 1;                  // Bottom B
                end

                // When input is Gr, output Gb
                'b01: begin
                    pixel_red_data <= (previous_line_buffer_read_data[1] +                  // Top R
                                            previous_previous_pixel) >> 1;                  // Bottom R

                    pixel_green_data <= previous_line_buffer_read_data[0];                  // Middle Gb

                    pixel_blue_data <= (previous_previous_line_buffer_read_data[0] +        // Left B
                                            line_buffer_read_data[0]) >> 1;                 // Right B
                end
                
                // When input is R, output B
                'b11: begin
                    pixel_red_data <= (previous_previous_line_buffer_read_data[1] +         // Top left R
                                            line_buffer_read_data[1] +                      // Top righ R
                                            previous_previous_previous_pixel +              // Bottom left R
                                            previous_pixel) >> 2;                           // Bottom right R

                    pixel_green_data <= (previous_line_buffer_read_data[1] +                // Top Gr
                                            previous_previous_line_buffer_read_data[0] +    // Left Gb
                                            line_buffer_read_data[0] +                      // Right Gb
                                            previous_previous_pixel) >> 2;                  // Bottom Gr

                    pixel_blue_data <= previous_line_buffer_read_data[0];                   // Middle B
                end
            endcase
        end
    end

end

endmodule
