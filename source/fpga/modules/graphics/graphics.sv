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

// SPI domain
logic clear_buffer_flag_metastable;

logic assign_color_enable_flag_metastable;
logic [3:0] assign_color_index_reg_metastable;
logic [9:0] assign_color_value_reg_metastable;

logic sprite_enable_flag_metastable;
logic sprite_data_flag_metastable;
logic show_buffer_flag_metastable;
logic clear_flags_metastable;
logic data_valid_metastable;

logic [7:0] sprite_data_metastable;
logic [9:0] sprite_x_position_reg_metastable;
logic [9:0] sprite_y_position_reg_metastable;
logic [9:0] sprite_width_reg_metastable;
logic [4:0] sprite_total_colors_reg_metastable;
logic [3:0] sprite_palette_offset_reg_metastable;

// Registers to hold the current command operations
logic clear_buffer_flag;
logic clear_buffer_in_progress_flag;
logic [17:0] clear_buffer_address_reg;

logic assign_color_enable_flag;
logic [3:0] assign_color_index_reg;
logic [9:0] assign_color_value_reg;

logic sprite_enable_flag;
logic sprite_data_flag;
logic [7:0] sprite_data;

logic show_buffer_flag;
logic clear_flags;
logic data_valid;

// Sprite engine related registers
logic [9:0] sprite_x_position_reg; // 0 - 639
logic [9:0] sprite_y_position_reg; // 0 - 399
logic [9:0] sprite_width_reg; // 1 - 640
logic [4:0] sprite_total_colors_reg; // 1, 4 or 16 colors
logic [3:0] sprite_palette_offset_reg; // 0 - 15

// Handle op-codes as they come in
always_ff @(posedge spi_clock_in) begin
    
    // Always clear flags after the opcode has been handled
    if (op_code_valid_in == 0 || spi_reset_n_in == 0) begin
        clear_buffer_flag_metastable <= 0;
        assign_color_enable_flag_metastable <= 0;
        sprite_enable_flag_metastable <= 0;
        show_buffer_flag_metastable <= 0;
        clear_flags <= 1;
        data_valid_metastable <= 0;
    end

    else begin
        
        clear_flags <= 0;

        case (op_code_in)

            // Clear buffer
            'h10: begin
                clear_buffer_flag_metastable <= 1;
                data_valid_metastable <= 1;
            end

            // Assign color
            'h11: begin
                if (operand_valid_in) begin
                    case (operand_count_in)
                        1: assign_color_index_reg_metastable <= operand_in[3:0];
                        2: assign_color_value_reg_metastable[9:6] <= operand_in[7:4];
                        3: assign_color_value_reg_metastable[5:3] <= operand_in[7:5];
                        4: assign_color_value_reg_metastable[2:0] <= operand_in[7:5];
                    endcase

                    assign_color_enable_flag_metastable <= operand_count_in == 4 ? 1 : 0;

                    data_valid_metastable <= 1;
                end 
                
                else begin 
                    data_valid_metastable <= 0;
                end
            end

            // Draw sprite
            'h12: begin
                
                if (operand_valid_in) begin
                    case (operand_count_in)
                        0: begin /* Do nothing */ end
                        1: sprite_x_position_reg_metastable <= {operand_in[1:0], 8'b0};
                        2: sprite_x_position_reg_metastable <= {sprite_x_position_reg_metastable[9:8], operand_in};
                        3: sprite_y_position_reg_metastable <= {operand_in[1:0], 8'b0};
                        4: sprite_y_position_reg_metastable <= {sprite_y_position_reg_metastable[9:8], operand_in};
                        5: sprite_width_reg_metastable <= {operand_in[1:0], 8'b0};
                        6: sprite_width_reg_metastable <= {sprite_width_reg_metastable[9:8], operand_in};
                        7: sprite_total_colors_reg_metastable <= operand_in[4:0];
                        8: sprite_palette_offset_reg_metastable <= operand_in[3:0];
                        default begin
                            sprite_enable_flag_metastable <= 1;
                            data_valid_metastable <= 1;
                            sprite_data_metastable <= operand_in;        
                        end
                    endcase
                    data_valid_metastable <= 1;
                end

                else begin
                    data_valid_metastable <= 0;
                end

            end

            // Show buffer
            'h14: begin
                show_buffer_flag_metastable <= 1;
                data_valid_metastable <= 1;
            end

            default: data_valid_metastable <= 0;

        endcase

    end
end

logic [2:0] data_valid_edge_monitor;

// SPI to display clock CDC
always_ff @(posedge display_clock_in) begin
    data_valid_edge_monitor = {data_valid_edge_monitor[1:0], data_valid_metastable};

    sprite_enable_flag <= sprite_enable_flag_metastable;
    // rising data valid, set data
    if (data_valid_edge_monitor[2:1] == 2'b01) begin
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
    if (data_valid_edge_monitor[2:1] == 2'b10) begin
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
    if (clear_buffer_in_progress_flag) begin
        pixel_write_enable_mux_to_buffer_wire = 1'b1;
        pixel_write_address_mux_to_buffer_wire = clear_buffer_address_reg;
        pixel_write_data_mux_to_buffer_wire = 4'b0;
    end

    else if (pixel_write_enable_sprite_to_mux_wire) begin
        pixel_write_enable_mux_to_buffer_wire = 1'b1;
        pixel_write_address_mux_to_buffer_wire = pixel_write_address_sprite_to_mux_wire;
        pixel_write_data_mux_to_buffer_wire = pixel_write_data_sprite_to_mux_wire;
    end

    else if (pixel_write_enable_vector_to_mux_wire) begin
        pixel_write_enable_mux_to_buffer_wire = 1'b1;
        pixel_write_address_mux_to_buffer_wire = pixel_write_address_vector_to_mux_wire;
        pixel_write_data_mux_to_buffer_wire = pixel_write_data_vector_to_mux_wire;
    end

    else begin
        pixel_write_enable_mux_to_buffer_wire = 1'b0;
        pixel_write_address_mux_to_buffer_wire = 18'b0;
        pixel_write_data_mux_to_buffer_wire = 4'b0;
    end
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