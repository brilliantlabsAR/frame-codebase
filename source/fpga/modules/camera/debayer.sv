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

module debayer #(
    IMAGE_X_SIZE = 'd1288
)(
    input logic clock_2x_in,
    input logic clock_in,
    input logic reset_n_in,
    input logic [9:0] x_offset_in,
    input logic [8:0] y_offset_in,
    input logic [9:0] x_size_in,
    input logic [8:0] y_size_in,
    input logic [9:0] pixel_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,
    output logic [29:0] rgb30_out,
	output logic [9:0] rgb10_out,
	output logic [7:0] rgb8_out,
	output logic [3:0] gray4_out,
    output logic fifo_write_enable_out,
	output logic frame_valid_out
);

logic [9:0] line0 [IMAGE_X_SIZE:0];
logic [9:0] line1 [IMAGE_X_SIZE:0];

logic [15:0] pixel_read_counter;
logic [15:0] pixel_write_counter;
logic [15:0] line_counter;

logic [9:0] r;
logic [9:0] g;
logic [9:0] b;

assign rgb30_out = fifo_write_enable_out ? {r, g, b} : 'b0;
assign rgb10_out = fifo_write_enable_out ? {r[9:7], g[9:6], b[9:7]} : 'b0; // rgb343
assign rgb8_out = fifo_write_enable_out ? {r[9:7], g[9:7], b[9:8]} : 'b0; // rgb332
assign gray4_out = fifo_write_enable_out ? g[2:0] + (r[1:0] + b[1:0]) : 'b0; // g/2 + r/4 + b/4

logic line_valid_in_d, pending;
logic [1:0] clock_in_reg;

always @(posedge clock_2x_in) begin
    if (!reset_n_in | !frame_valid_in) begin
        pixel_read_counter <= 0;
        pixel_write_counter <= 0;
        line_counter <= 0;
        fifo_write_enable_out <= 0;
        r <= 0;
        g <= 0;
        b <= 0;
		pending <= 0;
		frame_valid_out <= 0;
    end 

    else begin
		frame_valid_out <= 1;
        // track last line_valid_in val
        line_valid_in_d <= line_valid_in; 
		clock_in_reg <= {clock_in_reg[0], clock_in};

        // on line_valid_in write to alternating row buffers
        if (line_valid_in && clock_in_reg == 'b01) begin
            if (line_counter[0]) line1[pixel_read_counter] <= pixel_data_in;
            else line0[pixel_read_counter] <= pixel_data_in;
            pixel_read_counter <= pixel_read_counter +1;
			fifo_write_enable_out <= 0;
        end

        // demosaic and write to ram when not recieving pixels
        if (!line_valid_in && pending) begin
            if (pixel_write_counter < IMAGE_X_SIZE) begin
                r <= line1[pixel_write_counter+1];
                g <= (line0[pixel_write_counter+1]>>1) + (line1[pixel_write_counter]>>1);
                b <= line0[pixel_write_counter];
                pixel_write_counter <= pixel_write_counter + 'd2;
				if (
					(pixel_write_counter >= x_offset_in) && (pixel_write_counter < x_size_in+x_offset_in) &&
					(line_counter >= y_offset_in) && (line_counter <= y_size_in+y_offset_in)
				) begin
					fifo_write_enable_out <= 1;
				end else begin
					fifo_write_enable_out <= 0;
				end
            end
            // done with all pixels, stop writing
            else begin
                fifo_write_enable_out <= 0;
            end
        end

        // on falling edge of line_valid - switch line
        if (line_valid_in_d & !line_valid_in & clock_in) begin
            pixel_read_counter <= 0;
			pixel_write_counter <= 0;
            line_counter <= line_counter+1;
			
            // if line1 just filled, start demosaicing
            if (line_counter[0]) begin
				pending <= 1;
			end
            else begin 
                pending <= 0;
            end
        end
    end
end

endmodule