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

module color_palette (
    input logic clock_in,
    input logic reset_n_in,

    input logic [3:0] pixel_index_in,
    output logic [9:0] yuv_color_out,

    input logic assign_color_enable_in,
    input logic [3:0] assign_color_index_in,
    input logic [9:0] assign_color_value_in
);

    parameter VOID       = 10'b0000_100_100;
    parameter WHITE      = 10'b1111_100_100;

    logic [9:0] color_table [0:15];
    
    always_ff @(posedge clock_in) begin
        
        // Default color palette is all white
        if (reset_n_in == 0) begin

            color_table[0]  <= VOID;
            color_table[1]  <= WHITE;
            color_table[2]  <= WHITE;
            color_table[3]  <= WHITE;
            color_table[4]  <= WHITE;
            color_table[5]  <= WHITE;
            color_table[6]  <= WHITE;
            color_table[7]  <= WHITE;
            color_table[8]  <= WHITE;
            color_table[9]  <= WHITE;
            color_table[10] <= WHITE;
            color_table[11] <= WHITE;
            color_table[12] <= WHITE;
            color_table[13] <= WHITE;
            color_table[14] <= WHITE;
            color_table[15] <= WHITE;
        
            yuv_color_out <= VOID;
        end

        else begin

            if (assign_color_enable_in) begin

                color_table[assign_color_index_in] <= assign_color_value_in;
            
            end

            yuv_color_out <= color_table[pixel_index_in];
            
        end

    end

endmodule