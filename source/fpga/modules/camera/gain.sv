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

module gain #(
    THRESHOLD = 51
) (
    input logic pixel_clock_in,
    input logic reset_n_in,

    input logic [7:0] Y,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [15:0] pixel_count_above_threshold_out
);

logic [15:0] pixel_count_above_threshold;
logic last_frame_valid;

always_ff @(posedge pixel_clock_in) begin

    last_frame_valid <= frame_valid_in;

    if (!frame_valid_in || !reset_n_in) begin
        pixel_count_above_threshold <= 0;
        if (last_frame_valid) begin
            pixel_count_above_threshold_out <= pixel_count_above_threshold;
        end
    end

    else begin
        if (line_valid_in && Y > THRESHOLD) begin
            pixel_count_above_threshold <= pixel_count_above_threshold + 1;
        end
    end
end

endmodule