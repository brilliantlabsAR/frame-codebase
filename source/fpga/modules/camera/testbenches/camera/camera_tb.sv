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
logic spi_clock = 0;
logic pixel_clock = 0;
logic spi_reset_n = 0;
logic pixel_reset_n = 0;

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
    spi_reset_n <= 1;
    pixel_reset_n <= 1;
    delay_us(400);

    // Capture
    received_opcode_and_operand('h20);
    done();
    delay_us(2000);

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
    spi_reset_n <= 0;
    pixel_reset_n <= 0;
    global_reset_n <= 0;
    delay_us(10);
    $finish;
end

initial begin
    forever #6944 spi_clock <= ~spi_clock;
end

initial begin
    forever #13889 pixel_clock <= ~pixel_clock;
end

camera camera (
    .global_reset_n_in(global_reset_n),

    .spi_clock_in(spi_clock),
    .spi_reset_n_in(spi_reset_n),

    .pixel_clock_in(pixel_clock),
    .pixel_reset_n_in(pixel_reset_n),
    
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