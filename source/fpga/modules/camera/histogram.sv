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

module histogram #(
    NUM_BINS = 8
)(
    input logic clock_in,
    input logic reset_n_in,

    input logic [9:0] red_data_in,
    input logic [9:0] green_data_in,
    input logic [9:0] blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [7:0] red_histogram_out [0:NUM_BINS-1],
    output logic [7:0] green_histogram_out [0:NUM_BINS-1],
    output logic [7:0] blue_histogram_out [0:NUM_BINS-1],
    output logic histogram_ready_out
);

localparam BIN_SIZE = 1024 / NUM_BINS;

logic previous_frame_valid;

logic [15:0] red_histogram [0:NUM_BINS-1];
logic [15:0] green_histogram [0:NUM_BINS-1];
logic [15:0] blue_histogram [0:NUM_BINS-1];

always_ff @(posedge clock_in) begin

    previous_frame_valid <= frame_valid_in;

    if (frame_valid_in == 0 || reset_n_in == 0) begin

        if (previous_frame_valid) begin
            histogram_ready_out <= 0;

            for (integer i=0; i<NUM_BINS; i++) begin
                red_histogram_out[i] <= red_histogram[i][15:8];
                green_histogram_out[i] <= green_histogram[i][15:8];
                blue_histogram_out[i] <= blue_histogram[i][15:8];

                red_histogram[i] <= 0;
                green_histogram[i] <= 0;
                blue_histogram[i] <= 0;
            end
        end

        else begin

            histogram_ready_out <= 1;

        end
    end

    else begin

        if (frame_valid_in && line_valid_in) begin

            histogram_ready_out <= 0;
            
            // Increment corresponding bin count

            for (integer i=0; i<NUM_BINS; i++) begin
                if (red_data_in >= BIN_SIZE*i && red_data_in <= BIN_SIZE*(i+1)) begin
                    red_histogram[i] <= red_histogram[i] + 1;
                end
                if (green_data_in >= BIN_SIZE*i && green_data_in <= BIN_SIZE*(i+1)) begin
                    green_histogram[i] <= green_histogram[i] + 1;
                end
                if (blue_data_in >= BIN_SIZE*i && blue_data_in <= BIN_SIZE*(i+1)) begin
                    blue_histogram[i] <= blue_histogram[i] + 1;
                end
            end
        end
		
    end

end

endmodule