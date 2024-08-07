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

`timescale 1ns / 1ns

`include "../spi_peripheral.sv"
`include "../spi_register.sv"

module spi_tb ();

logic system_clock = 0;

initial begin
    forever #1 system_clock <= ~system_clock;
end

logic reset = 0;

// Stimulating signals
logic spi_select_in = 1;
logic spi_clock_in = 0;
logic spi_data_in = 0;

// Stimulated and interface signals
logic spi_data_out;

logic [7:0] opcode;
logic opcode_valid;
logic [7:0] operand;
logic operand_valid;

logic [7:0] response_2;
logic response_2_valid;

logic [7:0] response_3;
logic response_3_valid;

spi_peripheral spi_peripheral (
    .clock_in(system_clock),
    .reset_n_in(reset),

    .spi_select_in(spi_select_in),
    .spi_clock_in(spi_clock_in),
    .spi_data_in(spi_data_in),
    .spi_data_out(spi_data_out),

    .opcode_out(opcode),
    .opcode_valid_out(opcode_valid),
    .operand_out(operand),
    .operand_valid_out(operand_valid),

    .response_1_in(8'b0),
    .response_2_in(response_2),
    .response_3_in(response_3),
    .response_1_valid_in(1'b0),
    .response_2_valid_in(response_2_valid),
    .response_3_valid_in(response_3_valid)
);

spi_register #(
    .REGISTER_ADDRESS('hDB),
    .REGISTER_VALUE('h81)
) chip_id_1 (
    .clock_in(system_clock),
    .reset_n_in(reset),

    .opcode_in(opcode),
    .opcode_valid_in(opcode_valid),
    .response_out(response_2),
    .response_valid_out(response_2_valid)
);

spi_register #(
    .REGISTER_ADDRESS('hF4),
    .REGISTER_VALUE('h27)
) chip_id_2 (
    .clock_in(system_clock),
    .reset_n_in(reset),

    .opcode_in(opcode),
    .opcode_valid_in(opcode_valid),
    .response_out(response_3),
    .response_valid_out(response_3_valid)
);

task send_byte(
    input logic [7:0] data
);
    begin
        for (integer i = 7; i >= 0; i--) begin
            spi_data_in <= data[i];
            #40;
            spi_clock_in <= ~spi_clock_in;
            #40;
            spi_clock_in <= ~spi_clock_in;
        end
        
        #40;
    end
endtask

initial begin
    $dumpfile("simulation/spi_tb.fst");
    $dumpvars(0, spi_tb);
end

initial begin

    #80
    reset <= 1;

    // Test chip ID 1
    #80
    spi_select_in <= 0;    
    send_byte('hDB);
    send_byte('hFF);
    spi_select_in <= 1;    
    #80

    // Test chip ID 2 with extra operands
    #80
    spi_select_in <= 0;    
    send_byte('hF4);
    send_byte('h12);
    send_byte('h43);
    send_byte('h65);
    spi_select_in <= 1;    
    #80

    reset <= 0;
    #80

    $finish;
end

endmodule
