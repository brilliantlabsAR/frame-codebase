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

module image_gen #(
    parameter X_RESOLUTION = 5,
    parameter Y_RESOLUTION = 4,
    parameter H_FRONT_PORCH = 10, // 2x X_RESOLUTION
    parameter H_BACK_PORCH = 11, // ~ 2.2x X_RESOLUTION
    parameter V_FRONT_PORCH = 1,
    parameter V_BACK_PORCH = 2,
    parameter H_SYNC_PULSE_WIDTH = 44,
    parameter V_SYNC_PULSE_WIDTH = 5
) (
    input logic pixel_clock_in,
    input logic reset_n_in,

    output logic [9:0] pixel_data_out,
    output logic line_valid,
    output logic frame_valid
);

logic [31:0] x_counter;
logic [31:0] y_counter;
logic [31:0] pixel_counter;

logic [9:0] mem[19:0];

always @(posedge pixel_clock_in) begin

    if(!reset_n_in) begin

        pixel_data_out <= 0;
        line_valid <= 0;
        frame_valid <= 0;

        x_counter <= 0;
        y_counter <= 0;
        pixel_counter <= 0;

    end 

    else begin
            
        // Increment counters
        if (x_counter <= (H_SYNC_PULSE_WIDTH + H_BACK_PORCH + X_RESOLUTION + H_FRONT_PORCH)) begin
            x_counter <= x_counter + 1;
        end

        else begin
            x_counter <= 0;

            if (y_counter <= (V_SYNC_PULSE_WIDTH + V_BACK_PORCH + Y_RESOLUTION + V_FRONT_PORCH)) begin
                y_counter <= y_counter + 1;
            end

            else begin
                y_counter <= 0;
            end 

        end

        // Output line valud
        if ((x_counter >= (H_SYNC_PULSE_WIDTH + H_BACK_PORCH)) &&
            (x_counter < (H_SYNC_PULSE_WIDTH + H_BACK_PORCH + X_RESOLUTION)) &&
            (y_counter >= (V_SYNC_PULSE_WIDTH + V_BACK_PORCH)) &&
            (y_counter < (V_SYNC_PULSE_WIDTH + V_BACK_PORCH + Y_RESOLUTION))) begin
                
            line_valid <= 1;

            pixel_counter <= pixel_counter + 1;
        end

        else begin
            line_valid <= 0;
        end

        // Output frame valid
        if (y_counter >= 0 &&
            y_counter < V_SYNC_PULSE_WIDTH) begin

            frame_valid <= 0;
            pixel_counter <= 0;

        end

        else begin
            frame_valid <= 1;
        end
        
        // Output pixel
        pixel_data_out <= mem[pixel_counter];

    end

end

initial begin
    
    mem[0] = 1023;
    mem[1] = 0;
    mem[2] = 1023;
    mem[3] = 0;
    mem[4] = 0;
    mem[5] = 0;
    mem[6] = 0;
    mem[7] = 0;
    mem[8] = 0;
    mem[9] = 0;
    mem[10] = 1023;
    mem[11] = 0;
    mem[12] = 1023;
    mem[13] = 0;
    mem[14] = 0;
    mem[15] = 0;
    mem[16] = 0;
    mem[17] = 0;
    mem[18] = 0;
    mem[19] = 0;

end

endmodule