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

module metering (
    input logic clock_in,
    input logic reset_n_in,

    input logic [9:0] red_data_in,
    input logic [9:0] green_data_in,
    input logic [9:0] blue_data_in,
    input logic line_valid_in,
    input logic frame_valid_in,

    output logic [23:0] red_metering_out [4:0],
    output logic [23:0] green_metering_out [4:0],
    output logic [23:0] blue_metering_out [4:0],
    output logic metering_ready_out
);

logic previous_frame_valid;

logic [23:0] red_counter [4:0];
logic [23:0] green_counter [4:0];
logic [23:0] blue_counter [4:0];

always_ff @(posedge clock_in) begin

    previous_frame_valid <= frame_valid_in;

    if (frame_valid_in == 0 || reset_n_in == 0) begin

        if (previous_frame_valid) begin
            metering_ready_out <= 0;

            red_metering_out[0] <= red_counter[0];
            red_metering_out[1] <= red_counter[1];
            red_metering_out[2] <= red_counter[2];
            red_metering_out[3] <= red_counter[3];
            red_metering_out[4] <= red_counter[4];

            green_metering_out[0] <= green_counter[0];
            green_metering_out[1] <= green_counter[1];
            green_metering_out[2] <= green_counter[2];
            green_metering_out[3] <= green_counter[3];
            green_metering_out[4] <= green_counter[4];

            blue_metering_out[0] <= blue_counter[0];
            blue_metering_out[1] <= blue_counter[1];
            blue_metering_out[2] <= blue_counter[2];
            blue_metering_out[3] <= blue_counter[3];
            blue_metering_out[4] <= blue_counter[4];
        end

        else begin
            metering_ready_out <= 1;

            red_counter[0] <= 0;
            red_counter[1] <= 0;
            red_counter[2] <= 0;
            red_counter[3] <= 0;
            red_counter[4] <= 0;

            green_counter[0] <= 0;
            green_counter[1] <= 0;
            green_counter[2] <= 0;
            green_counter[3] <= 0;
            green_counter[4] <= 0;

            blue_counter[0] <= 0;
            blue_counter[1] <= 0;
            blue_counter[2] <= 0;
            blue_counter[3] <= 0;
            blue_counter[4] <= 0;
        end

    end

    else begin

        metering_ready_out <= 0;

        if (line_valid_in) begin
            if (red_data_in < 204)      red_counter[0] <= red_counter[0] + 1;
            else if (red_data_in < 409) red_counter[1] <= red_counter[1] + 1;
            else if (red_data_in < 613) red_counter[2] <= red_counter[2] + 1;
            else if (red_data_in < 818) red_counter[3] <= red_counter[3] + 1;
            else                        red_counter[4] <= red_counter[4] + 1;

            if (green_data_in < 204)      green_counter[0] <= green_counter[0] + 1;
            else if (green_data_in < 409) green_counter[1] <= green_counter[1] + 1;
            else if (green_data_in < 613) green_counter[2] <= green_counter[2] + 1;
            else if (green_data_in < 818) green_counter[3] <= green_counter[3] + 1;
            else                          green_counter[4] <= green_counter[4] + 1;

            if (blue_data_in < 204)      blue_counter[0] <= blue_counter[0] + 1;
            else if (blue_data_in < 409) blue_counter[1] <= blue_counter[1] + 1;
            else if (blue_data_in < 613) blue_counter[2] <= blue_counter[2] + 1;
            else if (blue_data_in < 818) blue_counter[3] <= blue_counter[3] + 1;
            else                         blue_counter[4] <= blue_counter[4] + 1;
        end

    end

end

endmodule