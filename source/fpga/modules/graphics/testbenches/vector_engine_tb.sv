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

`include "../vector_engine.sv"

module vector_engine_tb;

logic clock = 1;
logic reset_n = 0;
logic enable = 0;
logic ready;
logic write_enable;

logic [9:0] x0;
logic [9:0] y0;
logic [9:0] x1;
logic [9:0] y1;

logic [17:0] address;

initial begin
    #10
    reset_n <= 1;
    #10

    x0 <= 10;
    y0 <= 10;
    x1 <= 0;
    y1 <= 0;
    enable <= 1;
    #2;
    enable <= 0;

    // @(posedge ready);
    #800;
    #4;
    $finish;
end

vector_engine vector_engine (
    .clock_in(clock),
    .reset_n_in(reset_n),
    .enable_in(enable),
    .x0_in(x0),
    .x1_in(x1),
    .y0_in(y0),
    .y1_in(y1),
    .address_out(address),
    .write_enable_out(write_enable),
    .ready_out(ready)
);


initial begin
    forever #1 clock <= ~clock;
end

initial begin
    $dumpfile("simulation/vector_engine_tb.fst");
    $dumpvars(0, vector_engine_tb);
end

endmodule