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
`include "modules/graphics/graphics.sv"
`include "modules/pll/pll_wrapper.sv"
`include "modules/reset/reset_global.sv"
`include "modules/reset/reset_sync.sv"
`include "modules/spi/spi_peripheral.sv"
`include "modules/spi/spi_register.sv"
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

// Clocking
logic clock_osc;
logic clock_spi;
logic clock_display;
logic clock_byte_to_pixel;
logic clock_camera;
logic clock_camera_buffer;
logic pll_locked;

OSCA #(
    .HF_CLK_DIV("24"),
    .HF_OSC_EN("ENABLED"),
    .LF_OUTPUT_EN("DISABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(clock_osc) // f = (450 / (HF_CLK_DIV + 1)) ± 7%
);

pll_wrapper pll_wrapper (
    .clki_i(clock_osc),
    .clkop_o(clock_camera),
    .clkos_o(clock_byte_to_pixel),
    .clkos2_o(clock_display),
    .clkos3_o(clock_spi),
	.clkos4_o(clock_camera_buffer),
    .lock_o(pll_locked)
);

// Reset
logic global_reset_n;
logic reset_n_clock_spi;
logic reset_n_clock_display;

reset_global reset_global (
    .clock_in(clock_osc),
    .pll_locked_in(pll_locked),
    .global_reset_n_out(global_reset_n)
);

reset_sync reset_sync_clock_spi (
    .clock_in(clock_spi),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(reset_n_clock_spi)
);

reset_sync reset_sync_clock_display (
    .clock_in(clock_display),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(reset_n_clock_display)
);

// SPI
logic [7:0] opcode;
logic opcode_valid;
logic [7:0] operand;
logic operand_valid;
integer operand_count;

logic [7:0] response_1;
logic response_1_valid = 0;

logic [7:0] response_2;
logic response_2_valid = 0;

logic [7:0] response_3;
logic response_3_valid;

spi_peripheral spi_peripheral (
    .clock_in(clock_spi),
    .reset_n_in(reset_n_clock_spi),

    .spi_select_in(spi_select_in),
    .spi_clock_in(spi_clock_in),
    .spi_data_in(spi_data_in),
    .spi_data_out(spi_data_out),

    .opcode_out(opcode),
    .opcode_valid_out(opcode_valid),
    .operand_out(operand),
    .operand_valid_out(operand_valid),
    .operand_count_out(operand_count),

    .response_1_in(response_1),
    .response_2_in(response_2),
    .response_3_in(response_3),
    .response_1_valid_in(response_1_valid),
    .response_2_valid_in(response_2_valid),
    .response_3_valid_in(response_3_valid)
);

// Graphics
graphics graphics (
    .clock_in(clock_display),
    .reset_n_in(reset_n_clock_display),

    .op_code_in(opcode),
    .op_code_valid_in(opcode_valid),
    .operand_in(operand),
    .operand_valid_in(operand_valid),
    .operand_count_in(operand_count),

    .display_clock_out(display_clock),
    .display_hsync_out(display_hsync),
    .display_vsync_out(display_vsync),
    .display_y_out({display_y3, display_y2, display_y1, display_y0}),
    .display_cb_out({display_cb2, display_cb1, display_cb0}),
    .display_cr_out({display_cr2, display_cr1, display_cr0})
);

// Camera
assign camera_clock = clock_camera;

// Chip ID register
spi_register #(
    .REGISTER_ADDRESS('hDB),
    .REGISTER_VALUE('h81)
) chip_id_1 (
    .clock_in(clock_spi),
    .reset_n_in(reset_n_clock_spi),

    .opcode_in(opcode),
    .opcode_valid_in(opcode_valid),
    .response_out(response_3),
    .response_valid_out(response_3_valid)
);

endmodule