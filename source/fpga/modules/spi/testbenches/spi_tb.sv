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

`include "../spi.sv"

module spi_tb (
    output logic spi_data_out
);

initial begin
    $dumpfile("sim/spi_tb.fst");
    $dumpvars(0, spi_tb);
end

logic spi_clock = 0;
logic spi_select = 1;
logic spi_data_in = 1;

initial begin
    #1
    spi_select <= 0;
    #1
    spi_clock <= 1;
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
    spi_select <= 1;
    #1
    $finish;
end

spi spi (
    .spi_clock(spi_clock),
    .spi_select(spi_select),
    .spi_data_out(spi_data_out),
    .spi_data_in(spi_data_in)
);

endmodule