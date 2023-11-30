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

`include "../spi_peripheral.sv"
`include "../spi_subperipheral_selector.sv"
`include "../registers/chip_id.sv"
`include "../registers/version_string.sv"

module spi_tb ();

logic system_clock = 0;
initial begin
    forever #1 system_clock <= ~system_clock;
end

// Stimulating signals
logic spi_select_in = 0;
logic spi_clock_in = 0;
logic spi_data_in = 0;

// Stimulated and interface signals
logic spi_data_out;

logic [7:0] subperipheral_address;
logic subperipheral_address_valid;
logic [7:0] subperipheral_copi;
logic subperipheral_copi_valid;
logic [7:0] subperipheral_cipo;
logic subperipheral_cipo_valid;

logic subperipheral_1_enable;
logic [7:0] subperipheral_1_copi;
logic subperipheral_1_copi_valid;
logic [7:0] subperipheral_1_cipo;
logic subperipheral_1_cipo_valid;

logic subperipheral_2_enable;
logic [7:0] subperipheral_2_copi;
logic subperipheral_2_copi_valid;
logic [7:0] subperipheral_2_cipo;
logic subperipheral_2_cipo_valid;

spi_peripheral spi_peripheral (
    .system_clock(system_clock),

    .spi_select_in(spi_select_in),
    .spi_clock_in(spi_clock_in),
    .spi_data_in(spi_data_in),
    .spi_data_out(spi_data_out),

    .subperipheral_address_out(subperipheral_address),
    .subperipheral_address_out_valid(subperipheral_address_valid),
    .subperipheral_data_out(subperipheral_copi),
    .subperipheral_data_out_valid(subperipheral_copi_valid),
    .subperipheral_data_in(subperipheral_cipo),
    .subperipheral_data_in_valid(subperipheral_cipo_valid)
);

spi_subperipheral_selector spi_subperipheral_selector (
    .address_in(subperipheral_address),
    .address_in_valid(subperipheral_address_valid),
    .peripheral_data_in(subperipheral_copi),
    .peripheral_data_in_valid(subperipheral_copi_valid),
    .peripheral_data_out(subperipheral_cipo),
    .peripheral_data_out_valid(subperipheral_cipo_valid),

    .subperipheral_1_enable_out(subperipheral_1_enable),
    .subperipheral_1_data_in(subperipheral_1_cipo),
    .subperipheral_1_data_in_valid(subperipheral_1_cipo_valid),
    .subperipheral_1_data_out(),
    .subperipheral_1_data_out_valid(),

    .subperipheral_2_enable_out(subperipheral_2_enable),
    .subperipheral_2_data_in(subperipheral_2_cipo),
    .subperipheral_2_data_in_valid(subperipheral_2_cipo_valid),
    .subperipheral_2_data_out(),
    .subperipheral_2_data_out_valid(subperipheral_2_copi_valid)
);

spi_register_chip_id spi_register_chip_id (
    .enable(subperipheral_1_enable),

    .data_out(subperipheral_1_cipo),
    .data_out_valid(subperipheral_1_cipo_valid)
);

spi_register_version_string spi_register_version_string (
    .system_clock(system_clock),

    .enable(subperipheral_2_enable),
    .data_in_valid(subperipheral_2_copi_valid),

    .data_out(subperipheral_2_cipo),
    .data_out_valid(subperipheral_2_cipo_valid)
);

task send_byte(
    input logic [7:0] data
);
    begin
        for (integer i = 7; i >= 0; i--) begin
            spi_data_in <= data[i];
            #4;
            spi_clock_in <= ~spi_clock_in;
            #4;
            spi_clock_in <= ~spi_clock_in;
        end
        
        #4;
    end
endtask

initial begin
    $dumpfile("simulation/spi_tb.fst");
    $dumpvars(0, spi_tb);
end

initial begin

    #8
    spi_select_in <= 1;    
    #8

    // Test chip ID
    #8
    spi_select_in <= 0;    
    send_byte('hA0);
    send_byte('hFF);
    spi_select_in <= 1;    
    #8

    // Test version string
    #8
    spi_select_in <= 0;    
    send_byte('hB5);
    send_byte('hFF);
    send_byte('h00);
    send_byte('h00);
    send_byte('h00);
    spi_select_in <= 1;    
    #8

    $finish;
end

endmodule
