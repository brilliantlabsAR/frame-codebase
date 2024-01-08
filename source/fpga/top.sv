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

    output logic display_clock_out,
    output logic display_hsync_out,
    output logic display_vsync_out,
    output logic display_y0_out,
    output logic display_y1_out,
    output logic display_y2_out,
    output logic display_y3_out,
    output logic display_cr0_out,
    output logic display_cr1_out,
    output logic display_cr2_out,
    output logic display_cb0_out,
    output logic display_cb1_out,
    output logic display_cb2_out,

    // inout wire mipi_clock_in,
    // inout wire mipi_clock_in,
    // inout wire mipi_data_in,
    // inout wire mipi_data_in,

    output logic camera_clock_out
);

// Clocking
logic clock_osc;
logic clock_camera;
logic clock_camera_pixel;
logic clock_display;
logic clock_spi;
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
    .clkos_o(clock_camera_pixel),
    .clkos2_o(clock_display),
    .clkos3_o(clock_spi),
	.clkos4_o(),
    .lock_o(pll_locked)
);

// Reset
logic global_reset_n;
logic reset_spi_n;
logic reset_display_n;
logic reset_camera_pixel_n;

reset_global reset_global (
    .clock_in(clock_osc),
    .pll_locked_in(pll_locked),
    .global_reset_n_out(global_reset_n)
);

reset_sync reset_sync_clock_camera_pixel (
    .clock_in(clock_camera_pixel),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(reset_camera_pixel_n)
);

reset_sync reset_sync_clock_display (
    .clock_in(clock_display),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(reset_display_n)
);

reset_sync reset_sync_clock_spi (
    .clock_in(clock_spi),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(reset_spi_n)
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
logic response_2_valid;

logic [7:0] response_3;
logic response_3_valid;

spi_peripheral spi_peripheral (
    .clock_in(clock_spi),
    .reset_n_in(reset_spi_n),

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
    .reset_n_in(reset_display_n),

    .op_code_in(opcode),
    .op_code_valid_in(opcode_valid),
    .operand_in(operand),
    .operand_valid_in(operand_valid),
    .operand_count_in(operand_count),

    .display_clock_out(display_clock_out),
    .display_hsync_out(display_hsync_out),
    .display_vsync_out(display_vsync_out),
    .display_y_out({display_y3_out, display_y2_out, display_y1_out, display_y0_out}),
    .display_cb_out({display_cb2_out, display_cb1_out, display_cb0_out}),
    .display_cr_out({display_cr2_out, display_cr1_out, display_cr0_out})
);

// Camera
assign camera_clock_out = clock_camera;

camera camera (
    .clock_spi_in(clock_spi),
    .reset_spi_n_in(reset_spi_n),

    .clock_pixel_in(clock_camera_pixel),
    .reset_pixel_n_in(reset_camera_pixel_n),

    // .mipi_clock_p_in(mipi_clock_p_in),
    // .mipi_clock_n_in(mipi_clock_n_in),
    // .mipi_data_p_in(mipi_data_p_in),
    // .mipi_data_n_in(mipi_data_n_in),

    .op_code_in(opcode),
    .op_code_valid_in(opcode_valid),
    .operand_in(operand),
    .operand_valid_in(operand_valid),
    .operand_count_in(operand_count),
    .response_out(response_2),
    .response_valid_out(response_2_valid)
);

// Chip ID register
spi_register #(
    .REGISTER_ADDRESS('hDB),
    .REGISTER_VALUE('h81)
) chip_id_1 (
    .clock_in(clock_spi),
    .reset_n_in(reset_spi_n),

    .opcode_in(opcode),
    .opcode_valid_in(opcode_valid),
    .response_out(response_3),
    .response_valid_out(response_3_valid)
);

endmodule