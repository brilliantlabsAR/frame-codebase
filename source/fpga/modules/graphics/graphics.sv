/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
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
    input logic spi_clock_in,
    input logic spi_reset_n_in,

    input logic display_clock_in,
    input logic display_reset_n_in,

    input logic [7:0] op_code_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    input logic [31:0] operand_count_in,

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

logic switch_buffer_spi_domain;
logic switch_buffer;

logic spi_operand_edge_monitor;
logic spi_operand_edge_monitor_z;

// SPI registers
always_ff @(negedge spi_clock_in) begin
    
    // Always clear flags after the opcode has been handled
    if (operand_valid_in == 0 || spi_reset_n_in == 0) begin
        assign_color_enable_spi_domain <= 0;
        sprite_enable_spi_domain <= 0;
        switch_buffer_spi_domain <= 0;
    end

    else begin
        
        case (op_code_in)

            // Assign color
            'h11: begin
                if (operand_valid_in) begin
                    case (operand_count_in)
                        0: assign_color_index_spi_domain <= operand_in[3:0];
                        1: assign_color_value_spi_domain[9:6] <= operand_in[3:0];
                        2: assign_color_value_spi_domain[5:3] <= operand_in[2:0];
                        3: begin
                            assign_color_value_spi_domain[2:0] <= operand_in[2:0];
                            assign_color_enable_spi_domain <= 1;
                        end
                    endcase
                end
                
                else begin
                     assign_color_enable_spi_domain <= 0;
                end
            end

            // Draw sprite
            'h12: begin
                if (operand_valid_in) begin
                    case (operand_count_in)
                        0: sprite_x_position_spi_domain <= {operand_in[1:0], 8'b0};
                        1: sprite_x_position_spi_domain <= {sprite_x_position_spi_domain[9:8], operand_in};
                        2: sprite_y_position_spi_domain <= {operand_in[1:0], 8'b0};
                        3: sprite_y_position_spi_domain <= {sprite_y_position_spi_domain[9:8], operand_in};
                        4: sprite_width_spi_domain <= {operand_in[1:0], 8'b0};
                        5: sprite_width_spi_domain <= {sprite_width_spi_domain[9:8], operand_in};
                        6: sprite_color_count_spi_domain <= operand_in[4:0];
                        7: sprite_palette_offset_spi_domain <= operand_in[3:0];
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

            // Switch buffer
            'h14: begin
                switch_buffer_spi_domain <= 1;
            end

        endcase

    end

end

// SPI to display pulse sync
psync1 psync1_operand_valid_in (
        .in             (operand_valid_in),
        .in_clk         (~spi_clock_in),
        .in_reset_n     (spi_reset_n_in),
        .out            (spi_operand_edge_monitor),
        .out_clk        (display_clock_in),
        .out_reset_n    (display_reset_n_in)
);

// SPI to display CDC
always_ff @(posedge display_clock_in) begin
    
    // Always clear flags after the opcode has been handled
    if (display_reset_n_in == 0) begin
        spi_operand_edge_monitor_z <= 0;

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

        switch_buffer <= 0;
    end

    else begin
        spi_operand_edge_monitor_z <= spi_operand_edge_monitor;

        if (spi_operand_edge_monitor) begin
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

            switch_buffer <= switch_buffer_spi_domain;
        end

        if (spi_operand_edge_monitor_z) begin
            sprite_data_valid <= sprite_data_valid_spi_domain;
        end
    end

end

// Feed display buffer from either sprite or vector engine
logic pixel_write_enable_sprite_to_mux_wire;
logic [17:0] pixel_write_address_sprite_to_mux_wire;
logic [3:0] pixel_write_data_sprite_to_mux_wire;

logic pixel_write_enable_vector_to_mux_wire = 0; // TODO wire this up
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
// TODO

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
