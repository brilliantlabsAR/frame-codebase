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
`include "modules/graphics/vector_engine.sv"
`endif

module graphics (
    input logic spi_clock_in,
    input logic spi_reset_n_in,

    input logic display_clock_in,
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

logic [3:0] assign_color_index_spi_domain;
logic [9:0] assign_color_value_spi_domain;
logic assign_color_enable_spi_domain;

logic [3:0] assign_color_index;
logic [9:0] assign_color_value;
logic assign_color_enable;

logic [9:0] sprite_x_position_spi_domain;     // 0 - 639
logic [9:0] sprite_y_position_spi_domain;     // 0 - 399
logic [9:0] sprite_width_spi_domain;          // 1 - 640
logic [4:0] sprite_color_count_spi_domain;    // 1, 4 or 16 colors
logic [3:0] sprite_palette_offset_spi_domain; // 0 - 15
logic [7:0] sprite_data_spi_domain;
logic sprite_data_valid_spi_domain;
logic sprite_enable_spi_domain;

logic [9:0] sprite_x_position;
logic [9:0] sprite_y_position;
logic [9:0] sprite_width;
logic [4:0] sprite_color_count;
logic [3:0] sprite_palette_offset;
logic [7:0] sprite_data;
logic sprite_data_valid;
logic sprite_enable;

logic [1:0] spi_op_code_edge_monitor;
logic [1:0] spi_operand_edge_monitor;

logic [9:0] vector_x0_position_spi_domain;
logic [9:0] vector_x1_position_spi_domain;
logic [9:0] vector_y0_position_spi_domain;
logic [9:0] vector_y1_position_spi_domain;
logic [3:0] vector_pallete_index_spi_domain;
logic vector_enable_spi_domain;

logic [9:0] vector_x0_position;
logic [9:0] vector_x1_position;
logic [9:0] vector_y0_position;
logic [9:0] vector_y1_position;
logic [3:0] vector_pallete_index;
logic vector_enable;
logic vector_ready;

logic switch_buffer_spi_domain;
logic switch_buffer;

// SPI registers
always_ff @(posedge spi_clock_in) begin
    
    // Always clear flags after the opcode has been handled
    if (op_code_valid_in == 0 || spi_reset_n_in == 0) begin
        assign_color_enable_spi_domain <= 0;
        sprite_enable_spi_domain <= 0;
        switch_buffer_spi_domain <= 0;
        vector_enable_spi_domain <= 0;
    end

    else begin
        
        case (op_code_in)

            // Assign color
            'h11: begin
                if (operand_valid_in) begin
                    case (operand_count_in)
                        1: assign_color_index_spi_domain <= operand_in[3:0];
                        2: assign_color_value_spi_domain[9:6] <= operand_in[7:4];
                        3: assign_color_value_spi_domain[5:3] <= operand_in[7:5];
                        4: begin
                            assign_color_value_spi_domain[2:0] <= operand_in[7:5];
                            assign_color_enable_spi_domain <= 0;
                        end
                    endcase
                end
            end

            // Draw sprite
            'h12: begin
                if (operand_valid_in) begin
                    case (operand_count_in)
                        0: begin /* Do nothing */ end
                        1: sprite_x_position_spi_domain <= {operand_in[1:0], 8'b0};
                        2: sprite_x_position_spi_domain <= {sprite_x_position_spi_domain[9:8], operand_in};
                        3: sprite_y_position_spi_domain <= {operand_in[1:0], 8'b0};
                        4: sprite_y_position_spi_domain <= {sprite_y_position_spi_domain[9:8], operand_in};
                        5: sprite_width_spi_domain <= {operand_in[1:0], 8'b0};
                        6: sprite_width_spi_domain <= {sprite_width_spi_domain[9:8], operand_in};
                        7: sprite_color_count_spi_domain <= operand_in[4:0];
                        8: sprite_palette_offset_spi_domain <= operand_in[3:0];
                        default begin
                            sprite_data_spi_domain <= operand_in;        
                            sprite_data_valid_spi_domain <= 1;
                            sprite_enable_spi_domain <= 1;
                        end
                    endcase
                end

                else begin
                    sprite_data_valid_spi_domain <= 0;
                end
            end

            // Draw line
            'h13: begin

                if (operand_valid_in) begin
                    case (operand_count_in)
                        1: vector_x0_position_spi_domain[9:8] <= operand_in[1:0];
                        2: vector_x0_position_spi_domain[7:0] <= operand_in;
                        3: vector_y0_position_spi_domain[9:8] <= operand_in[1:0];
                        4: vector_y0_position_spi_domain[7:0] <= operand_in;
                        5: vector_x1_position_spi_domain[9:8] <= operand_in[1:0];
                        6: vector_x1_position_spi_domain[7:0] <= operand_in;
                        7: vector_y1_position_spi_domain[9:8] <= operand_in[1:0];
                        8: vector_y1_position_spi_domain[7:0] <= operand_in;
                        9: begin
                            vector_pallete_index_spi_domain <= operand_in[3:0];
                            // TODO: move this check to a queue fifo
                            // for consecutive lines / polygon
                            if (vector_ready) begin
                                vector_enable_spi_domain <= 1;
                            end
                        end
                    endcase
                end

                else begin
                    vector_enable_spi_domain <= 0;
                end

            end

            // Switch buffer
            'h14: begin
                switch_buffer_spi_domain <= 1;
            end

        endcase

    end

end

// SPI to display CDC
always_ff @(posedge display_clock_in) begin
    
    // Always clear flags after the opcode has been handled
    if (display_reset_n_in == 0) begin
        spi_op_code_edge_monitor <= 0;
        spi_operand_edge_monitor <= 0;

        assign_color_index <= 0;
        assign_color_value <= 0;
        assign_color_enable <= 0;

        sprite_x_position <= 0;
        sprite_y_position <= 0;
        sprite_width <= 0;
        sprite_color_count <= 0;
        sprite_palette_offset <= 0;
        sprite_data <= 0;
        sprite_data_valid <= 0;
        sprite_enable <= 0;

        vector_x0_position <= 0;
        vector_x1_position <= 0;
        vector_y0_position <= 0;
        vector_y1_position <= 0;
        vector_pallete_index <= 0;
        vector_enable_spi_domain <= 0;

        switch_buffer <= 0;
    end

    else begin
        spi_op_code_edge_monitor <= {spi_op_code_edge_monitor[0], op_code_valid_in};
        spi_operand_edge_monitor <= {spi_operand_edge_monitor[0], operand_valid_in};

        if (spi_op_code_edge_monitor == 2'b01 || 
            spi_operand_edge_monitor == 2'b01) begin // TODO do we need one more?
            assign_color_index <= assign_color_index_spi_domain;
            assign_color_value <= assign_color_value_spi_domain;
            assign_color_enable <= assign_color_enable_spi_domain;

            sprite_x_position <= sprite_x_position_spi_domain;
            sprite_y_position <= sprite_y_position_spi_domain;
            sprite_width <= sprite_width_spi_domain;
            sprite_color_count <= sprite_color_count_spi_domain;
            sprite_palette_offset <= sprite_palette_offset_spi_domain;
            sprite_data <= sprite_data_spi_domain;
            sprite_data_valid <= sprite_data_valid_spi_domain;
            sprite_enable <= sprite_enable_spi_domain;

            vector_x0_position <= vector_x0_position_spi_domain;
            vector_x1_position <= vector_x1_position_spi_domain;
            vector_y0_position <= vector_y0_position_spi_domain;
            vector_y1_position <= vector_y1_position_spi_domain;
            vector_pallete_index <= vector_pallete_index_spi_domain;
            vector_enable <= vector_enable_spi_domain;

            switch_buffer <= switch_buffer_spi_domain;
        end

        if (spi_operand_edge_monitor == 2'b10) begin
            sprite_data_valid <= sprite_data_valid_spi_domain;
        end
    end

end

// Feed display buffer from either sprite or vector engine
logic pixel_write_enable_sprite_to_mux_wire;
logic [17:0] pixel_write_address_sprite_to_mux_wire;
logic [3:0] pixel_write_data_sprite_to_mux_wire;

logic pixel_write_enable_vector_to_mux_wire;
logic [17:0] pixel_write_address_vector_to_mux_wire;
logic [3:0] pixel_write_data_vector_to_mux_wire;

logic pixel_write_enable_mux_to_buffer_wire;
logic [17:0] pixel_write_address_mux_to_buffer_wire;
logic [3:0] pixel_write_data_mux_to_buffer_wire;

always_comb begin
    if (pixel_write_enable_sprite_to_mux_wire) begin
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

sprite_engine sprite_engine (
    .clock_in(display_clock_in),
    .reset_n_in(display_reset_n_in),
    .enable_in(sprite_enable),

    .x_position_in(sprite_x_position),
    .y_position_in(sprite_y_position),
    .width_in(sprite_width),
    .total_colors_in(sprite_color_count),
    .color_palette_offset_in(sprite_palette_offset),

    .data_valid_in(sprite_data_valid),
    .data_in(sprite_data),

    .pixel_write_enable_out(pixel_write_enable_sprite_to_mux_wire),
    .pixel_write_address_out(pixel_write_address_sprite_to_mux_wire),
    .pixel_write_data_out(pixel_write_data_sprite_to_mux_wire)
);

// Vector engine
// TODO: Fix color logic
assign pixel_write_data_vector_to_mux_wire = vector_pallete_index_spi_domain;

vector_engine vector_engine (
    .clock_in(clock_in),
    .reset_n_in(reset_n_in),
    .enable_in(vector_enable),
    .x0_in(vector_x0_position),
    .y0_in(vector_y0_position),
    .x1_in(vector_x1_position),
    .y1_in(vector_y1_position),
    .address_out(pixel_write_address_vector_to_mux_wire),
    .write_enable_out(pixel_write_enable_vector_to_mux_wire),
    .ready_out(vector_ready)
);

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

    .switch_write_buffer_in(switch_buffer)
);

color_palette color_palette (
    .clock_in(display_clock_in),
    .reset_n_in(display_reset_n_in),

    .pixel_index_in(color_data_buffer_to_palette_wire),
    .yuv_color_out(color_data_palette_to_driver_wire),

    .assign_color_enable_in(assign_color_enable),
    .assign_color_index_in(assign_color_index),
    .assign_color_value_in(assign_color_value)
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


endmodule