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

`include "../camera.sv"

module camera_spi_tb;

logic clock_spi = 0;
logic clock_camera_pixel = 0;
logic reset_spi_n = 0;
logic reset_camera_pixel_n = 0;

logic [7:0] opcode;
logic opcode_valid = 0;
logic [7:0] operand;
logic operand_valid = 0;
integer operand_count = 0;
logic [7:0] response;
logic response_valid;

initial begin
    #100
    reset_spi_n <= 1;
    reset_camera_pixel_n <= 1;
    #200

    // Capture
    send_opcode('h20);
    done();
    #200

    // Bytes available
    send_opcode('h21);
    send_operand('h00);
    done();
    #200

    // Read data
    send_opcode('h22);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    done();
    #200

    // Bytes available
    send_opcode('h21);
    send_operand('h00);
    done();
    #200

    // Read data
    send_opcode('h22);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    done();
    #200

    // Bytes available
    send_opcode('h21);
    send_operand('h00);
    done();
    #200
    
    // Read data
    send_opcode('h22);
    send_operand('h00);
    send_operand('h00);
    send_operand('h00);
    done();
    #200

    // Bytes available
    send_opcode('h21);
    send_operand('h00);
    done();
    #200

    reset_spi_n <= 0;
    reset_camera_pixel_n <= 0;
    #100
    $finish;
end

camera #(
    .CAPTURE_X_RESOLUTION(5),
    .CAPTURE_Y_RESOLUTION(5)
) camera (
    .clock_spi_in(clock_spi),
    .reset_spi_n_in(reset_spi_n),

    .clock_pixel_in(clock_camera_pixel),
    .reset_pixel_n_in(reset_camera_pixel_n),

    .op_code_in(opcode),
    .op_code_valid_in(opcode_valid),
    .operand_in(operand),
    .operand_valid_in(operand_valid),
    .operand_count_in(operand_count),
    .response_out(response),
    .response_valid_out(response_valid)
);

initial begin
    forever #1 clock_spi <= ~clock_spi;
end

initial begin
    forever #2 clock_camera_pixel <= ~clock_camera_pixel;
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
    $dumpfile("simulation/camera_spi_tb.fst");
    $dumpvars(0, camera_spi_tb);
end

endmodule