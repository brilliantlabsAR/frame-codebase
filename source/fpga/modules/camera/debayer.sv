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
    HSIZE = 'd1288,
    ONELINE = 0 // debug output oneline (640p)
)(
    input logic clock_72MHz,
    input logic clock_36MHz,
    input logic reset_n,
    input logic [9:0] x_offset,
    input logic [8:0] y_offset,
    input logic [9:0] x_size,
    input logic [8:0] y_size,
    input logic [9:0] pixel_data,
    input logic line_valid,
    input logic frame_valid,
    output logic [29:0] rgb30,
	output logic [9:0] rgb10,
	output logic [7:0] rgb8,
	output logic [3:0] gray4,
    output logic camera_fifo_write_enable,
	output logic frame_valid_o
);

// TODO: do we need 2 extra pixels to prevent weird
// overflow issues with array indexing ? 
logic [9:0] line0 [HSIZE:0];
logic [9:0] line1 [HSIZE:0];

logic [15:0] rd_pix_counter;
logic [15:0] wr_pix_counter;
logic [15:0] line_counter;

logic [9:0] r;
logic [9:0] g;
logic [9:0] b;

assign rgb30 = camera_fifo_write_enable ? {r, g, b} : 'b0;
assign rgb10 = camera_fifo_write_enable ? {r[9:7], g[9:6], b[9:7]} : 'b0; // rgb343
assign rgb8 = camera_fifo_write_enable ? {r[9:7], g[9:7], b[9:8]} : 'b0; // rgb332
assign gray4 = camera_fifo_write_enable ? g[2:0] + r[1:0] + b[1:0] : 'b0; // g/2 + r/4 + B/4

logic line_valid_d, pending;
logic [1:0] clock_36MHz_reg;

always @(posedge clock_72MHz) begin
    if (!reset_n | !frame_valid) begin
        rd_pix_counter <= 0;
        wr_pix_counter <= 0;
        line_counter <= 0;
        camera_fifo_write_enable <= 0;
        r <= 0;
        g <= 0;
        b <= 0;
		pending <= 0;
		frame_valid_o <= 0;
    end 

    else begin
		frame_valid_o <= 1;
        // track last line_valid val
        line_valid_d <= line_valid; 
		clock_36MHz_reg <= {clock_36MHz_reg[0], clock_36MHz};

        // on line_valid write to alternating row buffers
        if (line_valid && clock_36MHz_reg == 'b01) begin
            if (line_counter[0]) line1[rd_pix_counter] <= pixel_data;
            else line0[rd_pix_counter] <= pixel_data;
            rd_pix_counter <= rd_pix_counter +1;
			camera_fifo_write_enable <= 0;
        end

        // demosaic and write to ram when not recieving pixels
        if (!line_valid && pending) begin
            if (wr_pix_counter < HSIZE) begin
                r <= line1[wr_pix_counter+1];
                g <= (line0[wr_pix_counter+1]>>1) + (line1[wr_pix_counter]>>1);
                b <= line0[wr_pix_counter];
                wr_pix_counter <= wr_pix_counter + 'd2;
				if (
					(wr_pix_counter >= x_offset) && (wr_pix_counter < x_size+x_offset) &&
					(line_counter >= y_offset) && (line_counter <= y_size+y_offset)
				) begin
					camera_fifo_write_enable <= 1;
				end else begin
					camera_fifo_write_enable <= 0;
				end
            end
            // done with all pixels, stop writing
            else begin
                camera_fifo_write_enable <= 0;
            end
        end

        // on falling edge of line_valid - switch line
        if (line_valid_d & !line_valid & clock_36MHz) begin
            rd_pix_counter <= 0;
			wr_pix_counter <= 0;
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