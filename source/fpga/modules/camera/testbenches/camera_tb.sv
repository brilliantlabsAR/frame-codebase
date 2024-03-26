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

`timescale 1ps / 1ps

`include "modules/camera/camera.sv"

module camera_tb;

logic global_reset_n = 0;
logic clock_spi = 0;
logic clock_camera_pixel = 0;
logic reset_spi_n = 0;
logic reset_camera_pixel_n = 0;

logic [7:0] opcode;
logic opcode_valid = 0;
logic [7:0] operand;
logic operand_valid = 0;
integer operand_count = 0;
logic [7:0] response_2;
logic response_2_valid;

initial begin
    delay_us(10);
    global_reset_n <= 1;
    delay_us(10);
    reset_spi_n <= 1;
    reset_camera_pixel_n <= 1;
    delay_us(400);

    // Capture
    received_opcode_and_operand('h20);
    done();
    delay_us(800);

    // Bytes available
    received_opcode_and_operand('h21);
    received_operand('h00);
    done();
    delay_us(100);

    // Read data
    received_opcode_and_operand('h22);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    done();
    delay_us(100);

    // Bytes available
    received_opcode_and_operand('h21);
    received_operand('h00);
    done();
    delay_us(100);

    // Read data
    received_opcode_and_operand('h22);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    received_operand('h00);
    done();
    delay_us(100);

    // end
    reset_spi_n <= 0;
    reset_camera_pixel_n <= 0;
    global_reset_n <= 0;
    delay_us(10);
    $finish;
end

initial begin
    forever #13889 clock_spi <= ~clock_spi;
end

initial begin
    forever #6944 clock_camera_pixel <= ~clock_camera_pixel;
end

camera camera (
    .global_reset_n_in(global_reset_n),

    .clock_spi_in(clock_spi),
    .reset_spi_n_in(reset_spi_n),

    .clock_pixel_in(clock_camera_pixel),
    .reset_pixel_n_in(reset_camera_pixel_n),
    
    `ifdef RADIANT
    .mipi_clock_p_in(mipi_clock_p_in),
    .mipi_clock_n_in(mipi_clock_n_in),
    .mipi_data_p_in(mipi_data_p_in),
    .mipi_data_n_in(mipi_data_n_in),
    `endif
    
    .op_code_in(opcode),
    .op_code_valid_in(opcode_valid),
    .operand_in(operand),
    .operand_valid_in(operand_valid),
    .operand_count_in(operand_count),
    .response_out(response_2),
    .response_valid_out(response_2_valid)
);

task delay_us(
    input logic [31:0] us
);
    begin
        for (integer i = 0; i < us; i++) begin
            #1000000;
        end
    end
endtask

task received_opcode_and_operand(
    input logic [7:0] data
);
    begin
        opcode <= data;
        opcode_valid <= 1;
        #888896;
        operand_valid <= 1;
    end
endtask

task received_operand(
    input logic [7:0] data
);
    begin
        #111112;
        operand_valid <= 0;
        #888896;
        operand <= data;
        operand_valid <= 1;
        operand_count <= operand_count + 1;
    end
endtask

task done;
    begin
        #888896;
        opcode_valid <= 0;
        operand_valid <= 0;
        operand_count <= 0;
    end
endtask

integer i;
initial begin
    $dumpfile("simulation/camera_tb.fst");
    $dumpvars(0, camera_tb);

    for (i = 0; i < 8; i = i + 1)
        $dumpvars(1, camera.image_buffer.inferred_lram.mem[i]);
end

endmodule