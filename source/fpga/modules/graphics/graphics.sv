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
`include "modules/graphics/color_pallet.sv"
`include "modules/graphics/display_buffers.sv"
`include "modules/graphics/display_driver.sv"
`include "modules/graphics/sprite_engine.sv"
`endif

module graphics (
    input logic clock_in,
    input logic reset_n_in,

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

// TODO add buffers for metastability to inputs

// Global drawing variables
logic [9:0] cursor_x_position_reg; // 0 - 639
logic [9:0] cursor_y_position_reg; // 0 - 399

logic [9:0] sprite_draw_width_reg = 25; // 0 - 639
logic [1:0] sprite_color_mode_reg = 'b11; // 'b00 = 1 color, 'b01 = 2 color
                                   // 'b01 = 4 color, 'b11 = 16 color
logic [3:0] sprite_pallet_offset_reg = 0; // 0 - 15

// Registers to hold the current command operations
logic clear_buffer_flag;
logic assign_color_enable_flag;
logic move_cursor_flag;
logic sprite_enable_flag;
logic sprite_byte_flag;
logic show_buffer_flag;

logic clear_buffer_in_progress_flag;
logic [17:0] clear_buffer_address_reg;

logic [3:0] assign_color_index_reg;
logic [9:0] assign_color_value_reg;

logic [9:0] move_cursor_x_reg;
logic [9:0] move_cursor_y_reg;

logic [7:0] sprite_draw_data;

// Handle op-codes as they come in
always_ff @(posedge clock_in) begin
    
    if (op_code_valid_in == 0 || reset_n_in == 0) begin
        clear_buffer_flag <= 0;
        assign_color_enable_flag <= 0;
        move_cursor_flag <= 0;
        sprite_enable_flag <= 0;
        sprite_byte_flag <= 0;
        show_buffer_flag <= 0; 
    end

    else begin
        
        case (op_code_in)

            // Clear buffer
            'h10: begin
                clear_buffer_flag <= 1;
            end

            // Assign color pallet
            'h11: begin
                if (operand_valid_in) begin
                    case (operand_count_in)
                        1: assign_color_index_reg <= operand_in[3:0];
                        2: assign_color_value_reg[9:6] <= operand_in[7:4];
                        3: assign_color_value_reg[5:3] <= operand_in[7:5];
                        4: assign_color_value_reg[2:0] <= operand_in[7:5];
                    endcase

                    assign_color_enable_flag = operand_count_in == 4 ? 1 : 0;
                end
            end

            // Move cursor
            'h12: begin
                if (operand_valid_in) begin
                    case (operand_count_in)
                        1: move_cursor_x_reg <= {operand_in[1:0], 8'b0};
                        2: move_cursor_x_reg <= {move_cursor_x_reg[1:0], operand_in};
                        3: move_cursor_y_reg <= {operand_in[1:0], 8'b0};
                        4: move_cursor_y_reg <= {move_cursor_x_reg[1:0], operand_in};
                    endcase

                    move_cursor_flag = operand_count_in == 4 ? 1 : 0;
                end
            end

            // Set sprite draw width
            'h13: begin

            end

            // Set sprite color mode
            'h14: begin

            end

            // Set sprite color pallet offset
            'h15: begin

            end

            // Sprite draw pixels
            'h16: begin
                sprite_enable_flag <= 1;

                if (operand_valid_in) begin
                    sprite_byte_flag <= 1;
                    sprite_draw_data <= operand_in;
                end

                else begin
                    sprite_byte_flag <= 0;
                end
            end

            // Show buffer
            'h19: begin
                show_buffer_flag <= 1;
            end

        endcase

    end

end

// State machine to clear the screen
always_ff @(posedge clock_in) begin
    
    if (reset_n_in == 0) begin
        clear_buffer_in_progress_flag <= 0;
        clear_buffer_address_reg <= 0;
    end

    else begin
        if (clear_buffer_flag) begin
            clear_buffer_in_progress_flag <= 1;
            clear_buffer_address_reg <= 0;
        end

        else if (clear_buffer_in_progress_flag) begin
            clear_buffer_address_reg <= clear_buffer_address_reg + 1;

            if (clear_buffer_address_reg == 'd256000) begin
                clear_buffer_in_progress_flag <= 0;
            end
        end
    end

end

// State machine to move and update the cursor from opcode, or draw operations
always_ff @(posedge clock_in) begin

    if (reset_n_in == 0) begin
        cursor_x_position_reg <= 0;
        cursor_y_position_reg <= 0;
    end

    else begin
        if (move_cursor_flag) begin
            cursor_x_position_reg <= move_cursor_x_reg;
            cursor_y_position_reg <= move_cursor_y_reg;
        end

        else if (sprite_update_cursor_flag) begin
            cursor_x_position_reg <= sprite_update_cursor_x_reg;
            cursor_y_position_reg <= sprite_update_cursor_y_reg;
        end

        else if (vector_update_cursor_flag) begin
            cursor_x_position_reg <= vector_update_cursor_x_reg;
            cursor_y_position_reg <= vector_update_cursor_y_reg;
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

// Wire address from driver to buffer, with return data going through the pallet
logic [17:0] read_address_driver_to_buffer_wire;
logic [3:0] color_data_buffer_to_pallet_wire;
logic [9:0] color_data_pallet_to_driver_wire;

display_buffers display_buffers (
    .clock_in(clock_in),
    .reset_n_in(reset_n_in),

    .pixel_write_enable_in(pixel_write_enable_mux_to_buffer_wire),
    .pixel_write_address_in(pixel_write_address_mux_to_buffer_wire),
    .pixel_write_data_in(pixel_write_data_mux_to_buffer_wire),

    .pixel_read_address_in(read_address_driver_to_buffer_wire),
    .pixel_read_data_out(color_data_buffer_to_pallet_wire),

    .switch_write_buffer_in(show_buffer_flag)
);

color_pallet color_pallet (
    .clock_in(clock_in),
    .reset_n_in(reset_n_in),

    .pixel_index_in(color_data_buffer_to_pallet_wire),
    .yuv_color_out(color_data_pallet_to_driver_wire),

    .assign_color_enable_in(assign_color_enable_flag),
    .assign_color_index_in(assign_color_index_reg),
    .assign_color_value_in(assign_color_value_reg)
);

display_driver display_driver (
    .clock_in(clock_in),
    .reset_n_in(reset_n_in),

    .pixel_data_address_out(read_address_driver_to_buffer_wire),
    .pixel_data_value_in(color_data_pallet_to_driver_wire),

    .display_clock_out(display_clock_out),
    .display_hsync_out(display_hsync_out),
    .display_vsync_out(display_vsync_out),
    .display_y_out(display_y_out),
    .display_cb_out(display_cb_out),
    .display_cr_out(display_cr_out)
);

// Sprite engine
logic sprite_update_cursor_flag;
logic [9:0] sprite_update_cursor_x_reg;
logic [9:0] sprite_update_cursor_y_reg;

sprite_engine sprite_engine (
    .clock_in(clock_in),
    .reset_n_in(reset_n_in),

    .cursor_start_x_position_in(cursor_x_position_reg),
    .cursor_start_y_position_in(cursor_y_position_reg),
    .draw_width_in(sprite_draw_width_reg),
    .color_mode_in(sprite_color_mode_reg),
    .color_pallet_offset_in(sprite_pallet_offset_reg),

    .draw_enable_in(sprite_enable_flag),
    .draw_data_valid_in(sprite_byte_flag),
    .draw_data_in(sprite_draw_data),

    .pixel_write_enable_out(pixel_write_enable_sprite_to_mux_wire),
    .pixel_write_address_out(pixel_write_address_sprite_to_mux_wire),
    .pixel_write_data_out(pixel_write_data_sprite_to_mux_wire),

    .cursor_end_position_valid_out(sprite_update_cursor_flag),
    .cursor_end_x_position_out(sprite_update_cursor_x_reg),
    .cursor_end_y_position_out(sprite_update_cursor_y_reg)
);

// Vector engine
logic vector_update_cursor_flag = 0;
logic [9:0] vector_update_cursor_x_reg;
logic [9:0] vector_update_cursor_y_reg;

endmodule