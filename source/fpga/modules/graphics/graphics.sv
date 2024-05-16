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

`ifndef RADIANT
`include "modules/graphics/spi_interface.sv"
`include "modules/graphics/color_palette.sv"
`include "modules/graphics/display_buffers.sv"
`include "modules/graphics/display_driver.sv"
`include "modules/graphics/sprite_engine.sv"
`endif

module graphics (
    input logic spi_clock_in, // 72MHz
    input logic spi_reset_n_in,

    input logic display_clock_in, // 36MHz
    input logic display_reset_n_in,

    input logic [7:0] op_code_in,
    input logic op_code_valid_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    input integer operand_count_in,

    output logic display_clock_out,
    output logic display_hsync_out,
    output logic display_vsync_out,
    output logic [3:0] display_y_out,
    output logic [2:0] display_cb_out,
    output logic [2:0] display_cr_out
);

// Registers to hold the current command operations
logic clear_buffer_flag_metastable;
logic clear_buffer_in_progress_flag_metastable;
logic [17:0] clear_buffer_address_reg_metastable;
logic clear_buffer_flag;
logic clear_buffer_in_progress_flag;
logic [17:0] clear_buffer_address_reg;

logic assign_color_enable_flag_metastable;
logic [3:0] assign_color_index_reg_metastable;
logic [9:0] assign_color_value_reg_metastable;
logic assign_color_enable_flag;
logic [3:0] assign_color_index_reg;
logic [9:0] assign_color_value_reg;

logic sprite_enable_flag_metastable;
logic sprite_data_flag_metastable;
logic [7:0] sprite_data_metastable;
logic sprite_enable_flag;
logic sprite_data_flag;
logic [7:0] sprite_data;

logic show_buffer_flag_metastable;
logic show_buffer_flag;

logic clear_flags_metastable;
logic clear_flags;

logic data_valid_metastable;
logic data_valid;

// Sprite engine related registers
logic [9:0] sprite_x_position_reg_metastable; // 0 - 639
logic [9:0] sprite_y_position_reg_metastable; // 0 - 399
logic [9:0] sprite_width_reg_metastable; // 1 - 640
logic [4:0] sprite_total_colors_reg_metastable; // 1, 4 or 16 colors
logic [3:0] sprite_palette_offset_reg_metastable; // 0 - 15
logic [9:0] sprite_x_position_reg;
logic [9:0] sprite_y_position_reg;
logic [9:0] sprite_width_reg;
logic [4:0] sprite_total_colors_reg;
logic [3:0] sprite_palette_offset_reg;

spi_interface spi_interface (
    .clock_in(spi_clock_in),
    .reset_n_in(spi_reset_n_in),

    .op_code_in(op_code_in),
    .op_code_valid_in(op_code_valid_in),
    .operand_in(operand_in),
    .operand_valid_in(operand_valid_in),
    .operand_count_in(operand_count_in),

    .clear_buffer_flag_out(clear_buffer_flag_metastable),

    .assign_color_enable_flag_out(assign_color_enable_flag_metastable),
    .assign_color_index_reg_out(assign_color_index_reg_metastable),
    .assign_color_value_reg_out(assign_color_value_reg_metastable),

    .sprite_enable_flag_out(sprite_enable_flag_metastable),
    .sprite_data_out(sprite_data_metastable),
    .sprite_x_position_reg_out(sprite_x_position_reg_metastable),
    .sprite_y_position_reg_out(sprite_y_position_reg_metastable),
    .sprite_width_reg_out(sprite_width_reg_metastable),
    .sprite_total_colors_reg_out(sprite_total_colors_reg_metastable),
    .sprite_palette_offset_reg_out(sprite_palette_offset_reg_metastable),
    
    .show_buffer_flag_out(show_buffer_flag_metastable),

    .clear_flags_out(clear_flags),

    .data_valid_out(data_valid_metastable)
);

logic [2:0] data_valid_cdc;

// SPI to display clock CDC
always_ff @(posedge display_clock_in) begin
    data_valid_cdc = {data_valid_cdc[1:0], data_valid_metastable};

    sprite_enable_flag <= sprite_enable_flag_metastable;
    // rising data valid, set data
    if (data_valid_cdc[2:1] == 2'b01) begin
        data_valid <= 1;
    
        clear_buffer_flag <= clear_buffer_flag_metastable;

        assign_color_enable_flag <= assign_color_enable_flag_metastable;
        assign_color_index_reg <= assign_color_index_reg_metastable;
        assign_color_value_reg <= assign_color_value_reg_metastable;

        sprite_data <= sprite_data_metastable;
        sprite_x_position_reg <= sprite_x_position_reg_metastable;
        sprite_y_position_reg <= sprite_y_position_reg_metastable;
        sprite_width_reg <= sprite_width_reg_metastable;
        sprite_total_colors_reg <= sprite_total_colors_reg_metastable;
        sprite_palette_offset_reg <= sprite_palette_offset_reg_metastable;
        
        show_buffer_flag <= show_buffer_flag_metastable;
    end

    // falling data valid, clear flags
    if (data_valid_cdc[2:1] == 2'b10) begin
        data_valid <= 0;
        
        if (clear_flags) begin
            clear_buffer_flag <= 0;
            assign_color_enable_flag <= 0;
            sprite_enable_flag <= 0;
            show_buffer_flag <= 0;
        end
    end
end

// State machine to clear the screen
logic [1:0] pixel_pulse_counter;

always_ff @(posedge display_clock_in) begin
    
    if (display_reset_n_in == 0) begin
        clear_buffer_in_progress_flag <= 0;
        clear_buffer_address_reg <= 0;
        pixel_pulse_counter <= 0;
    end

    else begin

        pixel_pulse_counter <= pixel_pulse_counter + 1;

        if (clear_buffer_flag) begin

            clear_buffer_in_progress_flag <= 1;
            clear_buffer_address_reg <= 0;

        end

        else if (clear_buffer_in_progress_flag && 
                 pixel_pulse_counter == 'b01) begin

            pixel_pulse_counter <= 0;
            clear_buffer_address_reg <= clear_buffer_address_reg + 1;

            if (clear_buffer_address_reg == 'd256000) begin
                clear_buffer_in_progress_flag <= 0;
            end

        end
        
    end

end

// Feed display buffer based on active input
logic pixel_write_enable_sprite_to_mux_wire;
logic [17:0] pixel_write_address_sprite_to_mux_wire;
logic [3:0] pixel_write_data_sprite_to_mux_wire;

logic pixel_write_enable_vector_to_mux_wire = 0; // TODO clean this up
logic [17:0] pixel_write_address_vector_to_mux_wire;
logic [3:0] pixel_write_data_vector_to_mux_wire;

logic pixel_write_enable_mux_to_buffer_wire;
logic [17:0] pixel_write_address_mux_to_buffer_wire;
logic [3:0] pixel_write_data_mux_to_buffer_wire;

always_comb begin
    case ({
        clear_buffer_in_progress_flag,
        pixel_write_enable_sprite_to_mux_wire,
        pixel_write_enable_vector_to_mux_wire
    })
    3'b100: begin
        pixel_write_enable_mux_to_buffer_wire = 1'b1;
        pixel_write_address_mux_to_buffer_wire = clear_buffer_address_reg;
        pixel_write_data_mux_to_buffer_wire = 4'b0;
    end

    3'b010: begin
        pixel_write_enable_mux_to_buffer_wire = 1'b1;
        pixel_write_address_mux_to_buffer_wire = pixel_write_address_sprite_to_mux_wire;
        pixel_write_data_mux_to_buffer_wire = pixel_write_data_sprite_to_mux_wire;
    end

    3'b001: begin
        pixel_write_enable_mux_to_buffer_wire = 1'b1;
        pixel_write_address_mux_to_buffer_wire = pixel_write_address_vector_to_mux_wire;
        pixel_write_data_mux_to_buffer_wire = pixel_write_data_vector_to_mux_wire;
    end

    default: begin
        pixel_write_enable_mux_to_buffer_wire = 1'b0;
        pixel_write_address_mux_to_buffer_wire = 18'b0;
        pixel_write_data_mux_to_buffer_wire = 4'b0;
    end
    endcase
end

// Wire address from driver to buffer, with return data going through the palette
logic [17:0] read_address_driver_to_buffer_wire;
logic [3:0] color_data_buffer_to_palette_wire;
logic [9:0] color_data_palette_to_driver_wire;

display_buffers display_buffers (
    .clock_in(display_clock_in),
    .reset_n_in(display_reset_n_in),

    .pixel_write_enable_in(pixel_write_enable_mux_to_buffer_wire),
    .pixel_write_address_in(pixel_write_address_mux_to_buffer_wire),
    .pixel_write_data_in(pixel_write_data_mux_to_buffer_wire),

    .pixel_read_address_in(read_address_driver_to_buffer_wire),
    .pixel_read_data_out(color_data_buffer_to_palette_wire),

    .switch_write_buffer_in(show_buffer_flag)
);

color_palette color_palette (
    .clock_in(display_clock_in),
    .reset_n_in(display_reset_n_in),

    .pixel_index_in(color_data_buffer_to_palette_wire),
    .yuv_color_out(color_data_palette_to_driver_wire),

    .assign_color_enable_in(assign_color_enable_flag),
    .assign_color_index_in(assign_color_index_reg),
    .assign_color_value_in(assign_color_value_reg)
);

display_driver display_driver (
    .clock_in(display_clock_in),
    .reset_n_in(display_reset_n_in),

    .pixel_data_address_out(read_address_driver_to_buffer_wire),
    .pixel_data_value_in(color_data_palette_to_driver_wire),

    .display_clock_out(display_clock_out),
    .display_hsync_out(display_hsync_out),
    .display_vsync_out(display_vsync_out),
    .display_y_out(display_y_out),
    .display_cb_out(display_cb_out),
    .display_cr_out(display_cr_out)
);

sprite_engine sprite_engine (
    .clock_in(display_clock_in),
    .reset_n_in(display_reset_n_in),
    .enable_in(sprite_enable_flag),

    .x_position_in(sprite_x_position_reg),
    .y_position_in(sprite_y_position_reg),
    .width_in(sprite_width_reg),
    .total_colors_in(sprite_total_colors_reg),
    .color_palette_offset_in(sprite_palette_offset_reg),

    .data_valid_in(data_valid),
    .data_in(sprite_data),

    .pixel_write_enable_out(pixel_write_enable_sprite_to_mux_wire),
    .pixel_write_address_out(pixel_write_address_sprite_to_mux_wire),
    .pixel_write_data_out(pixel_write_data_sprite_to_mux_wire)
);

// Vector engine
// TODO

endmodule