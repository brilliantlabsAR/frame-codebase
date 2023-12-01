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
`ifndef RADIANT
`include "modules/camera/camera.sv"
`include "modules/graphics/display.sv"
`include "modules/spi/spi_peripheral.sv"
`include "modules/spi/spi_subperipheral_selector.sv"
`include "modules/spi/registers/chip_id.sv"
`include "modules/spi/registers/version_string.sv"
`endif

module top (
    input logic spi_select_in,
    input logic spi_clock_in,
    input logic spi_data_in,
    output logic spi_data_out,

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
    output logic display_cb2,

    output logic camera_clock
);

logic system_clock;

// Clocking
OSCA #(
    .HF_CLK_DIV("24"), // 18 MHz
    .HF_OSC_EN("ENABLED"),
    .LF_OUTPUT_EN("DISABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(oscillator_clock)
);

`ifdef RADIANT

logic camera_clock_24MHz;
logic pixel_clock_36MHz;
logic pixel_clock_72MHz;
logic display_clock_50MHz;
logic pll_locked;

pll_ip pll_ip (
    .clki_i(oscillator_clock),
    .clkop_o(camera_clock_24MHz),
    .clkos_o(pixel_clock_36MHz),
    .clkos2_o(pixel_clock_72MHz),
    .clkos3_o(display_clock_50MHz),
    .clkos4_o(),
    .clkos5_o(),
    .lock_o(pll_locked)
);

logic global_reset_n;

logic [7:0] reset_counter;
always_ff @(posedge oscillator_clock) begin
    if (pll_locked & !reset_counter[7]) begin
        reset_counter <= reset_counter + 1;
    end

    else begin
        reset_counter <= 0;
    end
end

assign global_reset_n = pll_locked & reset_counter[7];

logic reset_n_pixel_clock_72MHz;
logic reset_n_display_clock_50MHz;

reset_sync reset_sync_pixel_clock_72MHz (
    .clock(pixel_clock_72MHz),
    .async_reset_n(global_reset_n),
    .sync_reset_n(reset_n_pixel_clock_72MHz)
);

reset_sync reset_sync_display_clock_50MHz (
    .clock(display_clock_50MHz),
    .async_reset_n(global_reset_n),
    .sync_reset_n(reset_n_display_clock_50MHz)
);

`endif

// SPI
logic [7:0] subperipheral_address;
logic subperipheral_address_valid;
logic [7:0] subperipheral_copi;
logic subperipheral_copi_valid;
logic [7:0] subperipheral_cipo;
logic subperipheral_cipo_valid;

logic subperipheral_1_enable;
logic [7:0] subperipheral_1_cipo;
logic subperipheral_1_cipo_valid;

logic subperipheral_2_enable;
logic [7:0] subperipheral_2_cipo;
logic subperipheral_2_cipo_valid;

spi_peripheral spi_peripheral (
    .clock(pixel_clock_72MHz),
	.reset_n(reset_n_pixel_clock_72MHz),

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
    .peripheral_data_out(subperipheral_cipo),
    .peripheral_data_out_valid(subperipheral_cipo_valid),

    .subperipheral_1_enable_out(subperipheral_1_enable),
    .subperipheral_1_data_in(subperipheral_1_cipo),
    .subperipheral_1_data_in_valid(subperipheral_1_cipo_valid),

    .subperipheral_2_enable_out(subperipheral_2_enable),
    .subperipheral_2_data_in(subperipheral_2_cipo),
    .subperipheral_2_data_in_valid(subperipheral_2_cipo_valid)
);

spi_register_chip_id spi_register_chip_id (
    .clock(pixel_clock_72MHz),
	.reset_n(reset_n_pixel_clock_72MHz),
    .enable(subperipheral_1_enable),

    .data_out(subperipheral_1_cipo),
    .data_out_valid(subperipheral_1_cipo_valid)
);

spi_register_version_string spi_register_version_string (
    .clock(pixel_clock_72MHz),
	.reset_n(reset_n_pixel_clock_72MHz),
    .enable(subperipheral_2_enable),
    .data_in_valid(subperipheral_copi_valid),

    .data_out(subperipheral_2_cipo),
    .data_out_valid(subperipheral_2_cipo_valid)
);

// Graphics
// display display (
//     .clock_in(clock),
//     .clock_out(display_clock),
//     .hsync(display_hsync),
//     .vsync(display_vsync),
//     .y0(display_y0),
//     .y1(display_y1),
//     .y2(display_y2),
//     .y3(display_y3),
//     .cr0(display_cr0),
//     .cr1(display_cr1),
//     .cr2(display_cr2),
//     .cb0(display_cb0),
//     .cb1(display_cb1),
//     .cb2(display_cb2)
// );

always_ff @(posedge system_clock) begin
    camera_clock <= ~camera_clock; // 25MHz
end

endmodule