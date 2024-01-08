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

    logic [9:0] color_table [0:15];
    
    // https://androidarts.com/palette/16pal.htm
    parameter VOID       = 10'b0000_011_011;
    parameter GREY       = 10'b1001_100_100;
    parameter WHITE      = 10'b1111_011_011;
    parameter RED        = 10'b0101_011_110;
    parameter PINK       = 10'b1001_011_101;
    parameter DARKBROWN  = 10'b0011_011_100;
    parameter BROWN      = 10'b0110_010_101;
    parameter ORANGE     = 10'b1001_010_101;
    parameter YELLOW     = 10'b1101_010_100;
    parameter DARKGREEN  = 10'b0100_100_011;
    parameter GREEN      = 10'b0110_010_011;
    parameter LIGHTGREEN = 10'b1010_001_011;
    parameter NIGHTBLUE  = 10'b0010_100_011;
    parameter SEABLUE    = 10'b0100_101_010;
    parameter SKYBLUE    = 10'b1000_101_010;
    parameter CLOUDBLUE  = 10'b1101_100_011;

    initial begin

        color_table[0]  = VOID;
        color_table[1]  = GREY;
        color_table[2]  = WHITE;
        color_table[3]  = RED;
        color_table[4]  = PINK;
        color_table[5]  = DARKBROWN;
        color_table[6]  = BROWN;
        color_table[7]  = ORANGE;
        color_table[8]  = YELLOW;
        color_table[9]  = DARKGREEN;
        color_table[10] = GREEN;
        color_table[11] = LIGHTGREEN;
        color_table[12] = NIGHTBLUE;
        color_table[13] = SEABLUE;
        color_table[14] = SKYBLUE;
        color_table[15] = CLOUDBLUE;

    end

    always_ff @(posedge clock_in) begin
        
        // Default color palette
        if (reset_n_in == 0) begin

            color_table[0]  <= VOID;
            color_table[1]  <= GREY;
            color_table[2]  <= WHITE;
            color_table[3]  <= RED;
            color_table[4]  <= PINK;
            color_table[5]  <= DARKBROWN;
            color_table[6]  <= BROWN;
            color_table[7]  <= ORANGE;
            color_table[8]  <= YELLOW;
            color_table[9]  <= DARKGREEN;
            color_table[10] <= GREEN;
            color_table[11] <= LIGHTGREEN;
            color_table[12] <= NIGHTBLUE;
            color_table[13] <= SEABLUE;
            color_table[14] <= SKYBLUE;
            color_table[15] <= CLOUDBLUE;
        
            yuv_color_out <= VOID;
        end

        else begin

            if (assign_color_enable_in) begin

                color_table[assign_color_index_in] <= assign_color_value_in;
                yuv_color_out <= VOID;
            
            end

            else begin
            
                yuv_color_out <= color_table[pixel_index_in];
            
            end

        end

    end

endmodule