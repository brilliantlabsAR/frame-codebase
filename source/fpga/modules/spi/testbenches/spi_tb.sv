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

// Stimulating signals
logic spi_clock = 0;
logic spi_select = 0;
logic spi_data_in = 0;

// Stimulated and interface signals
logic spi_data_out;

logic [7:0] subperipheral_address;
logic subperipheral_address_valid;

logic [7:0] peripheral_copi;
logic peripheral_copi_valid;

logic [7:0] peripheral_cipo;
logic peripheral_cipo_valid;

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
    .spi_clock(spi_clock),
    .spi_select(spi_select),
    .spi_data_out(spi_data_out),
    .spi_data_in(spi_data_in),
    .subperipheral_address_out(subperipheral_address),
    .subperipheral_address_valid(subperipheral_address_valid),
    .subperipheral_data_out(peripheral_copi),
    .subperipheral_data_out_valid(peripheral_copi_valid),
    .subperipheral_data_in(peripheral_cipo),
    .subperipheral_data_in_valid(peripheral_cipo_valid)
);

spi_subperipheral_selector spi_subperipheral_selector (
    .address_in(subperipheral_address),
    .address_valid(subperipheral_address_valid),
    .peripheral_data_in(peripheral_copi),
    .peripheral_data_in_valid(peripheral_copi_valid),
    .peripheral_data_out(peripheral_cipo),
    .peripheral_data_out_valid(peripheral_cipo_valid),
    .subperipheral_1_enable(subperipheral_1_enable),
    .subperipheral_1_data_in(subperipheral_1_cipo),
    .subperipheral_1_data_in_valid(subperipheral_1_cipo_valid),
    .subperipheral_1_data_out(),
    .subperipheral_1_data_out_valid(),
    .subperipheral_2_enable(subperipheral_2_enable),
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
            #1;
            spi_clock <= ~spi_clock;
            #1;
            spi_clock <= ~spi_clock;
        end
        
        #1;
    end
endtask

initial begin
    $dumpfile("sim/spi_tb.fst");
    $dumpvars(0, spi_tb);
end

initial begin

    #1
    spi_select <= 1;    
    #1

    // Test chip ID
    #1
    spi_select <= 0;    
    send_byte('hA0);
    send_byte('h00);
    spi_select <= 1;    
    #1

    // Test version string
    #1
    spi_select <= 0;    
    send_byte('hB5);
    send_byte('h00);
    send_byte('h00);
    send_byte('h00);
    send_byte('h00);
    spi_select <= 1;    
    #1

    $finish;
end

endmodule
