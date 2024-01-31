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
 *   ├────╄━━━━╋━━━━╅────┼────┤
 *   │ B  │ Gb ┃ B  ┃ Gb │ B  │ .. B is being read
 *   ├────┼────╄━━━━╃────┼────┤
 *   │ Gr │ R  │ Gr │ R  │ Gr │ ← 1 pixel dummy ending row
 *   └────┴────┴────┴────┴────┘
 *      ↑    ↑    ↑     ↖____↖ 
 *      │    │    │           2 pixel dummy ending column
 *      │    │    previous_pixel
 *      │    previous_previous_pixel
 *      previous_previous_previous_pixel
 *   
 */

module debayer_buffer (
    input logic clock_in,
    input logic reset_n_in,

    // Writes one 10bit word at the address
    input logic [10:0] pixel_write_address_in,
    input logic [9:0] pixel_write_data_in,

    // Reads three last three 10bit words from the address
    input logic [10:0] pixel_read_address_in,
    output logic [29:0] pixel_read_data_out
);

logic [8:0] mem [2048:0]; 

logic [8:0] previous_read_data;
logic [8:0] previous_previous_read_data;

always_ff @(posedge clock_in) begin
    
    if(reset_n_in == 0) begin
        
    end

    else begin

        // Output the last three words
        pixel_read_data_out <= {previous_previous_read_data, 
                                1'b0,
                                previous_read_data,
                                1'b0,
                                mem[pixel_read_address_in], 
                                1'b0};
        
        // Buffer last words
        previous_previous_read_data <= previous_read_data;
        previous_read_data <= mem[pixel_read_address_in];

        // Save the input word (dropping the last bit)
        mem[pixel_write_address_in] <= pixel_write_data_in[9:1];

    end

end

endmodule

module debayer #(
    X_RESOLUTION_IN = 78, // Include 1 left padding and 2 right padding
    Y_RESOLUTION_IN = 76 // Include 1 top padding and 1 bottom padding
)(
    input logic pixel_clock_in,
    input logic reset_n_in,

    input logic [9:0] pixel_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [11:0] pixel_red_data_out,
    output logic [11:0] pixel_green_data_out,
    output logic [11:0] pixel_blue_data_out,
    output logic line_valid_out,
    output logic frame_valid_out
);

// Allows max 2048 x 2048 pixel input
logic [10:0] x_counter;
logic [10:0] y_counter;

logic last_line_valid_in;

logic [9:0] previous_pixel;
logic [9:0] previous_previous_pixel;
logic [9:0] previous_previous_previous_pixel;

logic [10:0] line_buffer_a_read_address;
logic [29:0] line_buffer_a_read_data;
logic [10:0] line_buffer_a_write_address;
logic [9:0] line_buffer_a_write_data;

logic [10:0] line_buffer_b_read_address;
logic [29:0] line_buffer_b_read_data;
logic [10:0] line_buffer_b_write_address;
logic [9:0] line_buffer_b_write_data;

debayer_buffer line_buffer_a (
    .clock_in(pixel_clock_in),
    .reset_n_in(reset_n_in),

    .pixel_write_address_in(line_buffer_a_write_address),
    .pixel_write_data_in(line_buffer_a_write_data),

    .pixel_read_address_in(line_buffer_a_read_address),
    .pixel_read_data_out(line_buffer_a_read_data)
);

debayer_buffer line_buffer_b (
    .clock_in(pixel_clock_in),
    .reset_n_in(reset_n_in),

    .pixel_write_address_in(line_buffer_b_write_address),
    .pixel_write_data_in(line_buffer_b_write_data),

    .pixel_read_address_in(line_buffer_b_read_address),
    .pixel_read_data_out(line_buffer_b_read_data)
);

always_ff @(posedge pixel_clock_in) begin

    if(reset_n_in == 0 || frame_valid_in == 0) begin

        line_valid_out <= 0;
        frame_valid_out <= 0;

        x_counter <= 0;
        y_counter <= 0;

    end
    
    else begin

        last_line_valid_in <= line_valid_in;
        
        // Always buffer the last 2 pixels
        previous_previous_pixel <= previous_pixel;
        previous_pixel <= pixel_data_in;

        // Write the pixel into the line buffer 2 pixels behind
        if (x_counter > 1) begin
            if (y_counter[0]) begin
                line_buffer_b_write_address <= x_counter - 2;
                line_buffer_b_write_data <= previous_previous_pixel;
            end
            else begin
                line_buffer_a_write_address <= x_counter - 2;
                line_buffer_a_write_data <= previous_previous_pixel;
            end
        end

        // Increment counters and output whenever line valid is high
        if (line_valid_in) begin

            x_counter <= x_counter + 1;

            line_buffer_a_read_address <= x_counter;
            line_buffer_b_read_address <= x_counter;

            // Valid window for outputting pixels
            if (x_counter > 1 && 
                x_counter < (X_RESOLUTION_IN - 1) && 
                y_counter > 1) begin
            
                // Debayer the pixel at x-1, y-1
                case ({x_counter[0], y_counter[0]})

                    // When input is B, output R
                    'b00: begin
                        pixel_red_data_out <= line_buffer_b_read_data[19:10];     // Middle R

                        pixel_green_data_out <= (line_buffer_a_read_data[19:10] + // Top Gb
                                                 line_buffer_b_read_data[29:20] + // Left Gr
                                                 line_buffer_b_read_data[9:0] +   // Right Gr
                                                 previous_pixel) >> 2;            // Bottom Gb

                        pixel_blue_data_out <= (line_buffer_a_read_data[29:20] +  // Top left B
                                                line_buffer_a_read_data[9:0] +    // Top right B
                                                previous_previous_pixel +         // Bottom left B
                                                pixel_data_in) >> 2;              // Bottom right B
                    end

                    // When input is Gb, output Gr
                    'b10: begin
                        pixel_red_data_out <= (line_buffer_b_read_data[29:20] +    // Left R
                                               line_buffer_b_read_data[9:0]) >> 1; // right R

                        pixel_green_data_out <= line_buffer_b_read_data[19:10];    // Middle Gr

                        pixel_blue_data_out <= (line_buffer_a_read_data[19:10] +   // Top B
                                                previous_pixel) >> 1;              // Bottom B
                    end

                    // When input is Gr, output Gb
                    'b01: begin
                        pixel_red_data_out <= (line_buffer_b_read_data[19:10] +     // Top R
                                               previous_pixel) >> 1;                // Bottom R

                        pixel_green_data_out <= line_buffer_a_read_data[19:10];     // Middle Gb

                        pixel_blue_data_out <= (line_buffer_a_read_data[29:20]+     // Left B
                                                line_buffer_a_read_data[9:0]) >> 1; // Right B
                    end
                    
                    // When input is R, output B
                    'b11: begin
                        pixel_red_data_out <= (line_buffer_b_read_data[29:20] +   // Top left R
                                               line_buffer_b_read_data[9:0] +     // Top righ R
                                               previous_previous_pixel +          // Bottom left R
                                               pixel_data_in) >> 1;               // Bottom right R

                        pixel_green_data_out <= (line_buffer_b_read_data[19:10] + // Top Gr
                                                 line_buffer_a_read_data[29:20] + // Left Gb
                                                 line_buffer_a_read_data[9:0] +   // Right Gb
                                                 previous_pixel) >> 2;            // Bottom Gr

                        pixel_blue_data_out <= line_buffer_a_read_data[19:10];    // Middle B
                    end

                endcase

                line_valid_out <= 1;
                frame_valid_out <= 1;

            end

            else begin
                line_valid_out <= 0;
            end

        end

        else begin
            x_counter <= 0;

            // Increment y at the falling edge of each line_valid
            if (last_line_valid_in) begin
                y_counter <= y_counter + 1;
            end
        end

    end

end

endmodule