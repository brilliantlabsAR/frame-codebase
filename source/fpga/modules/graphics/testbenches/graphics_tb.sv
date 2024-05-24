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

logic spi_clock = 0;
logic spi_reset_n = 0;
logic display_clock = 0;
logic display_reset_n = 0;

logic [7:0] opcode;
logic opcode_valid = 0;
logic [7:0] operand;
logic operand_valid = 0;
integer operand_count = 0;

initial begin
    #20000
    spi_reset_n <= 1;
    display_reset_n <= 1;
    #10000

    // Clear command
    send_opcode('h10);
    done();
    #2100000

    // Draw pixels
    send_opcode('h12);
    send_operand('h00); // X pos
    send_operand('h32);
    send_operand('h00); // Y pos
    send_operand('h64);
    send_operand('h00); // Width
    send_operand('h14);
    send_operand('h10); // Total colors
    send_operand('h00); // palette offset
    send_operand('h12); // Data
    send_operand('h34);
    send_operand('h56);
    send_operand('h78);
    send_operand('h9A);
    send_operand('hBC);
    send_operand('hDE);
    send_operand('hF0);
    done();
    #30000

    // Show command
    send_opcode('h14);
    done();
    #2000000

    $writememh("simulation/image_buffer.txt", graphics.display_buffers.buffer_b.mem);
    $finish;
end

graphics graphics (
    .spi_clock_in(spi_clock),
    .spi_reset_n_in(spi_reset_n),

    .display_clock_in(display_clock),
    .display_reset_n_in(display_reset_n),

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
    forever #1 spi_clock <= ~spi_clock;
end

initial begin
    forever #2 display_clock <= ~display_clock;
end

task send_opcode(
    input logic [7:0] data
);
    begin
        opcode <= data;
        opcode_valid <= 1;
        #64;
    end
endtask

task send_operand(
    input logic [7:0] data
);
    begin
        operand <= data;
        operand_valid <= 1;
        operand_count <= operand_count + 1;
        #64;
        operand_valid <= 0;
        #8;
    end
endtask

task done;
    begin
        opcode_valid <= 0;
        operand_valid <= 0;
        operand_count <= 0;
        #8;
    end
endtask

initial begin
    $dumpfile("simulation/graphics_tb.fst");
    $dumpvars(0, graphics_tb);
end

endmodule