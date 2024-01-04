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

// Handle op-codes as they come in
always_ff @(posedge clock_in) begin
    
    // Always clear flags after the opcode has been handled
    if (op_code_valid_in == 0 || reset_n_in == 0) begin
        clear_buffer_flag <= 0;
        assign_color_enable_flag <= 0;
        sprite_enable_flag <= 0;
        sprite_data_flag <= 0;
        show_buffer_flag <= 0;
    end

    else begin
        
        case (op_code_in)

            // Clear buffer
            'h10: begin
                clear_buffer_flag <= 1;
            end

            // Assign color
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

            // Draw sprite
            'h12: begin
                
                if (operand_valid_in) begin
                    case (operand_count_in)
                        0: begin /* Do nothing */ end
                        1: sprite_x_position_reg <= {operand_in[1:0], 8'b0};
                        2: sprite_x_position_reg <= {sprite_x_position_reg[9:8], operand_in};
                        3: sprite_y_position_reg <= {operand_in[1:0], 8'b0};
                        4: sprite_y_position_reg <= {sprite_y_position_reg[9:8], operand_in};
                        5: sprite_width_reg <= {operand_in[1:0], 8'b0};
                        6: sprite_width_reg <= {sprite_width_reg[9:8], operand_in};
                        7: sprite_total_colors_reg <= 16;
                        8: sprite_pallet_offset_reg <= 0;
                        default begin
                            sprite_enable_flag <= 1;
                            sprite_data_flag <= 1;
                            sprite_data <= operand_in;        
                        end
                    endcase
                end

                else begin
                    sprite_data_flag <= 0;
                end

            end

            // Show buffer
            'h14: begin
                show_buffer_flag <= 1;
            end

        endcase

    end

end

// State machine to clear the screen
logic [1:0] pixel_pulse_counter;

always_ff @(posedge clock_in) begin
    
    if (reset_n_in == 0) begin
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
logic [9:0] sprite_x_position_reg; // 0 - 639
logic [9:0] sprite_y_position_reg; // 0 - 399
logic [9:0] sprite_width_reg; // 1 - 640
logic [4:0] sprite_total_colors_reg; // 1, 4 or 16 colors
logic [3:0] sprite_pallet_offset_reg; // 0 - 15

sprite_engine sprite_engine (
    .clock_in(clock_in),
    .reset_n_in(reset_n_in),
    .enable_in(sprite_enable_flag),

    .x_position_in(sprite_x_position_reg),
    .y_position_in(sprite_y_position_reg),
    .width_in(sprite_width_reg),
    .total_colors_in(sprite_total_colors_reg),
    .color_pallet_offset_in(sprite_pallet_offset_reg),

    .data_valid_in(sprite_data_flag),
    .data_in(sprite_data),

    .pixel_write_enable_out(pixel_write_enable_sprite_to_mux_wire),
    .pixel_write_address_out(pixel_write_address_sprite_to_mux_wire),
    .pixel_write_data_out(pixel_write_data_sprite_to_mux_wire)
);

// Vector engine
// TODO

endmodule