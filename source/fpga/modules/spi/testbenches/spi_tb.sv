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

`include "../spi_controller.sv"
`include "../registers/chip_id.sv"
`include "../registers/version_string.sv"

module spi_tb ();

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

// Stimulating signals
logic spi_clock = 0;
logic spi_select = 1;
logic spi_data_in = 0;

logic clock = 0;


initial begin

    // Test chip ID
    #1
    spi_select <= 0;    
    send_byte('hA0);
    send_byte('hA1);
    spi_select <= 1;    
    #1

    // Test version string
    #1
    // spi_select <= 0;    
    // send_byte('hB5);
    // send_byte('h00);
    // send_byte('h00);
    // send_byte('h00);
    // send_byte('h00);
    // spi_select <= 1;    
    // #1

    $finish;
end

// Stimulated and interface signals
logic spi_data_out;
logic [7:0] peripheral_bus_address;
logic [7:0] peripheral_bus_copi;
logic [7:0] peripheral_bus_cipo;
logic peripheral_bus_address_valid;
logic peripheral_bus_copi_valid;
logic peripheral_bus_cipo_valid;

spi_controller spi_controller (
    .spi_clock(spi_clock),
    .spi_select(spi_select),
    .spi_data_out(spi_data_out),
    .spi_data_in(spi_data_in),
    .peripheral_address_out(peripheral_bus_address),
    .peripheral_data_out(peripheral_bus_copi),
    .peripheral_data_in(peripheral_bus_cipo),
    .peripheral_address_valid(peripheral_bus_address_valid),
    .peripheral_data_out_valid(peripheral_bus_copi_valid),
    .peripheral_data_in_valid(peripheral_bus_cipo_valid)
);

// spi_register_chip_id spi_register_chip_id (
//     .address_in(peripheral_bus_address),
//     .address_valid(peripheral_bus_address_valid),
//     .data_out(peripheral_bus_cipo),
//     .data_out_valid(peripheral_bus_cipo_valid)
// );

spi_register_version_string spi_register_version_string (
    .address_in(peripheral_bus_address),
    .address_valid(peripheral_bus_address_valid),
    .data_in_valid(peripheral_bus_copi_valid),
    .data_out(peripheral_bus_cipo),
    .data_out_valid(peripheral_bus_cipo_valid)
);

endmodule
