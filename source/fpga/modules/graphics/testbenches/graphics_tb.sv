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

`include "../graphics.sv"

module graphics_tb;

logic clock = 0;
logic reset_n = 0;

logic [7:0] opcode;
logic opcode_valid = 0;
logic [7:0] operand;
logic operand_valid = 0;
integer operand_count = 0;

initial begin
    #20000
    reset_n <= 1;
    #10000

    // Clear command
    opcode <= 'h10;
    opcode_valid <= 1;
    #4
    opcode_valid <= 0;
    #600000

    // Move cursor command
    opcode <= 'h12;
    opcode_valid <= 1;
    #4
    operand <= 'h00;
    operand_valid <= 1;
    operand_count <= 1;
    #4
    operand <= 'h32;
    operand_count <= 2;
    #4
    operand <= 'h00;
    operand_count <= 3;
    #4
    operand <= 'h64;
    operand_count <= 4;
    #4
    opcode_valid <= 0;
    operand_valid <= 0;
    operand_count <= 0;
    #10000

    // Set draw width
    opcode <= 'h13;
    opcode_valid <= 1;
    #4
    operand <= 'h01;
    operand_valid <= 1;
    operand_count <= 1;
    #4
    operand <= 'h2C;
    operand_count <= 2;
    #4
    opcode_valid <= 0;
    operand_valid <= 0;
    operand_count <= 0;
    #10000

    // Draw pixels

    // Show command

    reset_n <= 0;
    #20000
    $finish;
end

graphics graphics (
    .clock_in(clock),
    .reset_n_in(reset_n),

    .op_code_in(opcode),
    .op_code_valid_in(opcode_valid),
    .operand_in(operand),
    .operand_valid_in(operand_valid),
    .operand_count_in(operand_count),

    .display_clock_out(),
    .display_hsync_out(),
    .display_vsync_out(),
    .display_y_out(),
    .display_cb_out(),
    .display_cr_out()
);

initial begin
    forever #1 clock <= ~clock;
end

initial begin
    $dumpfile("simulation/graphics_tb.fst");
    $dumpvars(0, graphics_tb);
end

endmodule