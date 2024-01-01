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

`include "../display_driver.sv"

module display_driver_tb (
    output logic display_clock,
    output logic display_hsync,
    output logic display_vsync,
    output logic display_y0,
    output logic display_y1,
    output logic display_y2,
    output logic display_y3,
    output logic display_cr0,
    output logic display_cr1,
    output logic display_cr2,
    output logic display_cb0,
    output logic display_cb1,
    output logic display_cb2
);

logic clock = 0;
logic reset_n = 0;
logic [17:0] address;

initial begin : clock_25MHz
    forever #2 clock <= ~clock;
end

initial begin
    $dumpfile("simulation/display_driver_tb.fst");
    $dumpvars(0, display_driver_tb);
end

initial begin
    #10
    reset_n <= 1;
    #10000000
    reset_n <= 0;
    #10
    $finish;
end

display_driver display_driver (
    .clock_in(clock),
    .reset_n_in(reset_n),

    .pixel_data_address_out(address),
    .pixel_data_value_in(10'b1010011111),

    .display_clock_out(display_clock),
    .display_hsync_out(display_hsync),
    .display_vsync_out(display_vsync),
    .display_y_out({display_y0, display_y1, display_y2, display_y3}),
    .display_cb_out({display_cr0, display_cr1, display_cr2}),
    .display_cr_out({display_cb0, display_cb1, display_cb2})
);

endmodule