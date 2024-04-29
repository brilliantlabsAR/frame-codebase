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
    NUM_BINS = 8,
    RESOLUTION = 16
)(
    input logic pixel_clock_in,
    input logic pixel_reset_n_in,

    input logic spi_clock_in,
    input logic spi_reset_n_in,

    input logic [9:0] red_data_in,
    input logic [9:0] green_data_in,
    input logic [9:0] blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    input logic read_enable_in,
    output logic [RESOLUTION-1:0] histogram_data_out,
    output logic histogram_ready_out
);

localparam BIN_SIZE = 1024 / NUM_BINS;

logic previous_frame_valid;

logic [RESOLUTION-1:0] red_histogram [0:NUM_BINS-1];
logic [RESOLUTION-1:0] green_histogram [0:NUM_BINS-1];
logic [RESOLUTION-1:0] blue_histogram [0:NUM_BINS-1];

logic write_enable;
logic [7:0] write_data;

afifo #(.DSIZE(8), .ASIZE(4)) afifo(
    .i_wclk(pixel_clock_in),
    .i_wrst_n(pixel_reset_n_in), 
    .i_wr(write_enable),
    .i_wdata(write_data),
    .o_wfull(),
    .i_rclk(spi_clock_in),
    .i_rrst_n(spi_reset_n_in),
    .i_rd(read_enable_in),
    .o_rdata(histogram_data_out),
    .o_rempty()
);

logic [7:0] bin_count;
logic [2:0] state;
localparam IDLE = 0;
localparam COPY_TO_FIFO = 1;
localparam DONE_COPYING = 2;

always_ff @(posedge pixel_clock_in) begin

    previous_frame_valid <= frame_valid_in;

    if (frame_valid_in == 0 || pixel_reset_n_in == 0) begin

        if (previous_frame_valid) begin
            state <= COPY_TO_FIFO;
        end

        else begin

            case (state)

            IDLE: begin
                write_enable <= 0;
                histogram_ready_out <= 1;
                bin_count <= 0;
            end

            COPY_TO_FIFO: begin
                for (integer i=0; i<NUM_BINS; i++) begin
                    case (bin_count)
                    2*i +0 : write_data <= red_histogram[i][15:8];
                    2*i +1 : write_data <= red_histogram[i][7:0];
                    2*i +16: write_data <= green_histogram[i][15:8];
                    2*i +17: write_data <= green_histogram[i][7:0];
                    2*i +32: write_data <= blue_histogram[i][15:8];
                    2*i +33: write_data <= blue_histogram[i][7:0];
                    endcase
                end

                if (bin_count < 23) begin
                    bin_count <= bin_count + 1;
                    write_enable <= 1;
                end
                else begin
                    state <= DONE_COPYING;
                    write_enable <= 0;
                end

                histogram_ready_out <= 0;
            end

            DONE_COPYING: begin
                // Clear bin array values
                for (integer i=0; i<NUM_BINS; i++) begin
                    red_histogram[i] <= 'b0; 
                    green_histogram[i] <= 'b0; 
                    blue_histogram[i] <= 'b0; 
                end
                write_enable <= 0;
                histogram_ready_out <= 1;
            end

            endcase

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