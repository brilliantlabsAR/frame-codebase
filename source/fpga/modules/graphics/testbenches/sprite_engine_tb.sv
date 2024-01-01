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

`timescale 10ns / 10ns

`include "../sprite_engine.sv"

module sprite_engine_tb;

logic clock = 0;
logic reset_n = 0;

logic starting_cursor_valid = 0;
logic [9:0] starting_cursor_x = 50;
logic [9:0] starting_cursor_y = 100;

logic [9:0] cursor_x;
logic [9:0] cursor_y ;
logic [9:0] draw_width = 25;
logic [1:0] color_mode = 'b11;
logic [3:0] pallet_offset = 0;

logic enable = 0;
logic input_data_valid = 0;
logic [7:0] input_data = 0;

logic output_valid;
logic [17:0] output_address;
logic [3:0] output_data;

logic updated_cursor_valid;
logic [9:0] updated_cursor_x;
logic [9:0] updated_cursor_y;

initial begin
    #20
    reset_n <= 1;
    #10

    // Set cursor
    starting_cursor_valid <= 1;
    #4
    starting_cursor_valid <= 0;
    #10

    // Enable
    enable <= 1;
    #50

    // Send two pixels
    input_data <= 'h83;
    input_data_valid <= 1;
    #10
    input_data_valid <= 0;
    #100

    // Send two pixels
    input_data <= 'h56;
    input_data_valid <= 1;
    #10
    input_data_valid <= 0;
    #100

    // Disable
    enable <= 0;
    #10

    reset_n <= 0;
    #20
    $finish;
end

// State machine to move and update the cursor from opcode, or draw operations
always_ff @(posedge clock) begin

    if (reset_n == 0) begin
        cursor_x <= 0;
        cursor_y <= 0;
    end

    else begin
        if (starting_cursor_valid) begin
            cursor_x <= starting_cursor_x;
            cursor_y <= starting_cursor_y;
        end

        else if (updated_cursor_valid) begin
            cursor_x <= updated_cursor_x;
            cursor_y <= updated_cursor_y;
        end
    end

end

sprite_engine sprite_engine (
    .clock_in(clock),
    .reset_n_in(reset_n),

    .cursor_start_x_position_in(cursor_x),
    .cursor_start_y_position_in(cursor_y),
    .draw_width_in(draw_width),
    .color_mode_in(color_mode),
    .color_pallet_offset_in(pallet_offset),

    .sprite_draw_enable_in(enable),
    .sprite_draw_data_valid_in(input_data_valid),
    .sprite_draw_data_in(input_data),

    .pixel_write_enable_out(output_valid),
    .pixel_write_address_out(output_address),
    .pixel_write_data_out(output_data),

    .cursor_end_position_valid_out(updated_cursor_valid),
    .cursor_end_x_position_out(updated_cursor_x),
    .cursor_end_y_position_out(updated_cursor_y)
);

initial begin
    forever #2 clock <= ~clock;
end

initial begin
    $dumpfile("simulation/sprite_engine_tb.fst");
    $dumpvars(0, sprite_engine_tb);
end

endmodule