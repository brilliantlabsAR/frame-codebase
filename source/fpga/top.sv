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
logic clock_72MHz;
logic clock_50MHz;
logic clock_36MHz;
logic clock_24MHz;
logic pll_locked;

`ifndef RADIANT // TODO remove this section once gatecat/prjoxide#44 is solved

logic [31:0] clock_osc_counter;

initial begin
    clock_72MHz = 0;
    clock_50MHz = 0;
    clock_24MHz = 0;
    clock_osc_counter = 0; 
    pll_locked = 0;
end

OSCA #(
    .HF_CLK_DIV("2"), 
    .HF_OSC_EN("ENABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(clock_osc) // f = (450 / (HF_CLK_DIV + 1)) ± 7%
);

always_ff @(posedge clock_osc) begin

    // clock_osc_counter increments at half the clock_osc frequency
    clock_osc_counter <= clock_osc_counter + 1;

    // 75MHz
    if (clock_osc_counter[0]) clock_72MHz <= 1;
    else                      clock_72MHz <= 0;
    
    // 37.5MHz
    if (clock_osc_counter[1]) clock_50MHz <= 1;
    else                      clock_50MHz <= 0;

    // 25MHz
    if (clock_osc_counter[2]) clock_24MHz <= 1;
    else                      clock_24MHz <= 0;

    // Release reset after some time
    if (clock_osc_counter[3]) pll_locked <= 1;

end

`else

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
    .clkop_o(clock_24MHz),
    .clkos_o(clock_36MHz),
    .clkos2_o(clock_72MHz),
    .clkos3_o(clock_50MHz),
    .lock_o(pll_locked)
);

`endif // TODO remove this line once gatecat/prjoxide#44 is solved

// Reset
logic global_reset_n;
logic reset_n_clock_72MHz;
logic reset_n_clock_50MHz;
logic reset_n_clock_24MHz;

reset_global reset_global (
    .clock_in(clock_osc),
    .pll_locked_in(pll_locked),
    .global_reset_n_out(global_reset_n)
);

reset_sync reset_sync_clock_72MHz (
    .clock_in(clock_72MHz),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(reset_n_clock_72MHz)
);

reset_sync reset_sync_clock_50MHz (
    .clock_in(clock_50MHz),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(reset_n_clock_50MHz)
);

reset_sync reset_sync_clock_24MHz (
    .clock_in(clock_24MHz),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(reset_n_clock_24MHz)
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
    .clock_in(clock_72MHz),
    .reset_n_in(reset_n_clock_72MHz),

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
    .clock_in(clock_50MHz),
    .reset_n_in(reset_n_clock_50MHz),

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
assign camera_clock = clock_24MHz;

// Chip ID register
spi_register #(
    .REGISTER_ADDRESS('hDB),
    .REGISTER_VALUE('h81)
) chip_id_1 (
    .clock_in(clock_72MHz),
    .reset_n_in(reset_n_clock_72MHz),

    .opcode_in(opcode),
    .opcode_valid_in(opcode_valid),
    .response_out(response_3),
    .response_valid_out(response_3_valid)
);

endmodule