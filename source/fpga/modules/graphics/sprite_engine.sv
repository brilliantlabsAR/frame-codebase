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

 module sprite_engine (
    input logic clock_in,
    input logic reset_n_in,

    input logic [9:0] cursor_start_x_position_in,
    input logic [9:0] cursor_start_y_position_in,
    input logic [9:0] draw_width_in,
    input logic [1:0] color_mode_in,
    input logic [3:0] color_pallet_offset_in,

    input logic sprite_draw_enable_in,
    input logic sprite_draw_data_valid_in,
    input logic [7:0] sprite_draw_data_in,

    output logic pixel_write_enable_out,
    output logic [17:0] pixel_write_address_out,
    output logic [3:0] pixel_write_data_out,

    output logic cursor_end_position_valid_out,
    output logic [9:0] cursor_end_x_position_out,
    output logic [9:0] cursor_end_y_position_out
 );

// TODO implement cursor output
initial begin
    cursor_end_position_valid_out = 0;
    cursor_end_x_position_out = 0;
    cursor_end_y_position_out = 0;
end

logic [1:0] data_valid_edge_monitor;
logic [17:0] draw_address;
logic [4:0] pixels_remaining;

always_ff @(posedge clock_in) begin

    data_valid_edge_monitor <= {data_valid_edge_monitor[0], 
                                sprite_draw_data_valid_in};

    if (sprite_draw_enable_in == 0 || reset_n_in == 0) begin
        pixel_write_enable_out <= 0;
        cursor_end_position_valid_out <= 0;

        data_valid_edge_monitor <= 0;
        draw_address <= 0;
        pixels_remaining <= 0;
    end

    else begin

        // On a new data byte
        if (data_valid_edge_monitor == 'b01) begin

            draw_address <= cursor_start_x_position_in + 
                            (cursor_start_y_position_in * 640);

            case (color_mode_in)
                'b00: pixels_remaining = 8;
                'b01: pixels_remaining = 8;
                'b10: pixels_remaining = 4;
                'b11: pixels_remaining = 2;
            endcase
        
        end

        else if (pixels_remaining > 0) begin
            
            pixels_remaining <= pixels_remaining - 1;

            // TODO width
            draw_address <= draw_address + 1;

            // TODO color mode and color offset
            pixel_write_enable_out <= 1;
            pixel_write_address_out <= draw_address;
            pixel_write_data_out <= sprite_draw_data_in[3:0];

        end

    end

end
    
endmodule