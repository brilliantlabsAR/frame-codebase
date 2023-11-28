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

module spi_tb ();

initial begin
    $dumpfile("sim/spi_tb.fst");
    $dumpvars(0, spi_tb);
end

// Stimulating signals
logic spi_clock = 0;
logic spi_select = 1;
logic spi_data_in = 0;

initial begin
    // Start
    #1
    spi_select <= 0;
    #1
    spi_clock <= 1;
    #1

    // Push address
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    spi_data_in <= 1;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    spi_data_in <= 0;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    spi_data_in <= 1;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    spi_data_in <= 0;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    spi_data_in <= 1;
    
    // Read byte
    #2
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;

    // Read byte
    #2
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1
    spi_clock <= ~spi_clock;
    #1

    // Done
    spi_select <= 1;
    spi_data_in <= 0;
    #1
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

spi_register_chip_id spi_register_chip_id (
    .address_in(peripheral_bus_address),
    .address_valid(peripheral_bus_address_valid),
    .data_out(peripheral_bus_cipo),
    .data_valid(peripheral_bus_cipo_valid)
);

endmodule
