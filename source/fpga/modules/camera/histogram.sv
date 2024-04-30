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

localparam BIN_SIZE = 256 / NUM_BINS;

logic previous_frame_valid;
logic previous_line_valid;

logic [7:0] red_histogram [0:NUM_BINS-1];
logic [7:0] green_histogram [0:NUM_BINS-1];
logic [7:0] blue_histogram [0:NUM_BINS-1];

logic [7:0] red_data;
logic [7:0] green_data;
logic [7:0] blue_data;

always_comb begin
    red_data = red_data_in[9:2];
    green_data = green_data_in[9:2];
    blue_data = blue_data_in[9:2];
end

logic [3:0] red_index;
logic [3:0] green_index;
logic [3:0] blue_index;

logic [7:0] red_previous_value;
logic [7:0] green_previous_value;
logic [7:0] blue_previous_value;

always_ff @(posedge clock_in) begin

    previous_frame_valid <= frame_valid_in;
    previous_line_valid <= line_valid_in;

    if (frame_valid_in == 0 || reset_n_in == 0) begin

        if (previous_frame_valid) begin
            histogram_ready_out <= 0;

            for (integer i=0; i<NUM_BINS; i++) begin
                red_histogram_out[i] <= red_histogram[i];
                green_histogram_out[i] <= green_histogram[i];
                blue_histogram_out[i] <= blue_histogram[i];

                red_histogram[i] <= 0;
                green_histogram[i] <= 0;
                blue_histogram[i] <= 0;
            end

            red_index <= 0;
            green_index <= 0;
            blue_index <= 0;
        end

        else begin

            histogram_ready_out <= 1;

        end
    end

    else begin
        histogram_ready_out <= 0;

        if (frame_valid_in && line_valid_in) begin

            // Increment corresponding bin
            for (integer i=0; i<NUM_BINS; i++) begin
                if (red_data >= BIN_SIZE*i && red_data <= BIN_SIZE*(i+1)) begin
                    red_index <= i;
                    red_previous_value <= red_histogram[i];
                end
                if (green_data >= BIN_SIZE*i && green_data <= BIN_SIZE*(i+1)) begin
                    green_index <= i;
                    green_previous_value <= green_histogram[i];
                end
                if (blue_data >= BIN_SIZE*i && blue_data <= BIN_SIZE*(i+1)) begin
                    blue_index <= i;
                    blue_previous_value <= blue_histogram[i];
                end
            end

        end

        if (frame_valid_in && previous_line_valid) begin
            
            if (red_previous_value < 'hff)
                red_histogram[red_index] <= red_previous_value + 1;
            
            if (green_previous_value < 'hff)
                green_histogram[green_index] <= green_previous_value + 1;

            if (blue_previous_value < 'hff)
                blue_histogram[blue_index] <= blue_previous_value + 1;

        end
		
    end

end

endmodule