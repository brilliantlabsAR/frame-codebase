/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

`ifndef RADIANT
`include "modules/camera/camera.sv"
`include "modules/graphics/graphics.sv"
`include "modules/pll/pll_wrapper.sv"
`include "modules/reset/global_reset_sync.sv"
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

    `ifdef NO_MIPI_IP_SIM
    input logic byte_to_pixel_frame_valid /* synthesis syn_keep=1 nomerge=""*/,
    input logic byte_to_pixel_line_valid /* synthesis syn_keep=1 nomerge=""*/,
    input logic [9:0] byte_to_pixel_data /* synthesis syn_keep=1 nomerge=""*/,
    input logic camera_pixel_clock,
    `else
    `ifdef RADIANT
    inout wire mipi_clock_p_in,
    inout wire mipi_clock_n_in,
    inout wire mipi_data_p_in,
    inout wire mipi_data_n_in,
    `endif
    `endif //NO_MIPI_IP_SIM

    output logic camera_clock_out
);

// Clocking
logic osc_clock;
logic camera_clock;
logic display_clock;
logic spi_peripheral_clock;
logic pll_locked;
logic pll_reset;
logic jpeg_clock;               // Raw JPEG clock - generated or divided down from pixel clock - goes to clock switch
logic jpeg_buffer_clock;        // 2x JPEG clock for transpose/zig-zag buffer overclocking -  goes to JPEG
logic jpeg_slow_clock;          // Raw JPEG clock muxed with SPI clock - goes to JPEG
logic spi_clock /* synthesis syn_keep=1 nomerge=""*/; // locally routed clock

logic pllpowerdown_n;
logic image_buffer_read_en;

/* JPEG slow clock: 36, 24, 18, 12 MHz:

                |   JPEG_CLOCK_SOURCE
    ------------+--_------------------------------------------------------
    DIV_PCLKDIV |   camera_pixel_clock (36 MHz)     camera_clock (24 MHz)
    "X1"        |   36 MHz                          24 MHz
    "X2"        |   18 MHz                          12 MHz

    NOTE:
    When divider is "X2", jpeg_buffer_clock can be set to `JPEG_CLOCK_SOURCE!
*/

//`define JPEG_CLOCK_SOURCE camera_clock          /* 24 MHz -> 12 or 24 MHz */
`define JPEG_CLOCK_SOURCE camera_pixel_clock    /* 36 MHz -> 18 or 36 MHz */
`define JPEG_CLOCK_DIV "X1"                     /* "X2" or "X1" */

`ifdef NO_PLL_SIM
initial osc_clock = 0;
initial camera_clock = 0;
initial display_clock = 0;
initial spi_peripheral_clock = 0;
initial jpeg_buffer_clock = 0;
initial jpeg_clock = 0;
initial forever #(27777.778) osc_clock = ~osc_clock;
initial forever #(20833.333) camera_clock = pll_locked ? ~camera_clock : 0;
initial forever #(13999.889) display_clock = pll_locked ? ~display_clock : 0;
initial forever #( 6944.444) spi_peripheral_clock = pll_locked ? ~spi_peripheral_clock : 0;
initial forever #( 6410.256) jpeg_buffer_clock = pll_locked ? ~jpeg_buffer_clock : 0;
// Divide 36 MHz clock by 2
generate
if (`JPEG_CLOCK_DIV == "X2")
always @(posedge `JPEG_CLOCK_SOURCE or posedge pll_reset) jpeg_clock = !pll_reset ? ~jpeg_clock : 0;
else
always_comb jpeg_clock = `JPEG_CLOCK_SOURCE;
endgenerate
always_comb pll_locked = ~pll_reset & pllpowerdown_n;
`else
OSCA #(
    .HF_CLK_DIV("24"),
    .HF_OSC_EN("ENABLED"),
    .LF_OUTPUT_EN("DISABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(osc_clock) // f = (450 / (HF_CLK_DIV + 1)) ± 7%
);

logic camera_pixel_clock;

pll_wrapper pll_wrapper (
    .clki_i(osc_clock),                 // 18MHz
    .rstn_i(pll_reset),
    .pllpowerdown_n(pllpowerdown_n),
    .clkop_o(camera_clock),             // 24MHz
    .clkos_o(camera_pixel_clock),       // 36MHz
    .clkos2_o(display_clock),           // 36MHz
    .clkos3_o(spi_peripheral_clock),    // 72MHz - remove
    .clkos4_o(jpeg_buffer_clock),       // 78MHz - remove
    .lock_o(pll_locked)
);

// Divide 36 MHz clock by 2 or 1
PCLKDIVSP #(
    .DIV_PCLKDIV(`JPEG_CLOCK_DIV),
    .GSR("DISABLED")
) div (
    .CLKIN(`JPEG_CLOCK_SOURCE),
    .LSRPDIV(pll_reset),
    .CLKOUT(jpeg_clock)
);

`endif //NO_PLL_SIM

// Reset
logic global_reset_n;
logic camera_pixel_reset_n;
logic display_reset_n;
logic spi_peripheral_reset_n;
logic jpeg_buffer_reset_n;
logic jpeg_slow_reset_n;

global_reset_sync global_reset_sync (
    .clock_in(osc_clock),
    .pll_locked_in(pll_locked),
    .pll_reset_out(pll_reset),
    .global_reset_n_out(/*global_reset_n*/)  // FIXME - Raj/Robert to review - with PLL powerdown + no lock, this will reset all FPGA, which we don't want
);
always_comb global_reset_n = ~pll_reset;

reset_sync camera_pixel_clock_reset_sync (
    .clock_in(camera_pixel_clock),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(camera_pixel_reset_n)
);

reset_sync display_clock_reset_sync (
    .clock_in(display_clock),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(display_reset_n)
);

reset_sync spi_peripheral_clock_reset_sync (
    .clock_in(spi_clock),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(spi_peripheral_reset_n)
);

reset_sync jpeg_buffer_clock_reset_sync (
    .clock_in(jpeg_buffer_clock),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(jpeg_buffer_reset_n)
);

reset_sync jpeg_slow_reset_n_sync (
    .clock_in(jpeg_slow_clock),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(jpeg_slow_reset_n)
);

`ifdef NO_PLL_SIM
clkswitch clkswitch(
    .i_clk_a (jpeg_clock), 
    .i_clk_b (spi_clock), 
    .i_areset_n (global_reset_n), 
    .i_sel (image_buffer_read_en), 
    .o_clk (jpeg_slow_clock)
);
`else
// Dynamic clock select for jpeg and Image buffer
DCS #(.DCSMODE("DCS")) DCSInst0 (
    .CLK0 (jpeg_clock),
    .CLK1 (spi_clock),
    .SEL (image_buffer_read_en),
    .SELFORCE (1'b0),
    .DCSOUT (jpeg_slow_clock)
);
`endif //NO_PLL_SIM

// SPI
logic [7:0] opcode;
logic [7:0] operand;
logic operand_rd_en;
logic operand_wr_en;
logic [31:0] rd_operand_count;
logic [31:0] wr_operand_count;

logic [7:0] response_1;  //  Graphics debug
logic [7:0] response_2;  // Camera
logic [7:0] response_3;  // Chip ID
logic [7:0] response_4;  // PLL CSR

/*
6.1. Primary Clock Sources
The primary clock network has multiple inputs, called primary clock sources, which can be routed directly to the
primary clock routing to clock the FPGA fabric.
The primary clock sources that can connect to the primary clock routing are:
- Dedicated Clock Input Pins
- PLL Outputs
- PCLKDIVSP/ECLKDIV Outputs
- Internal FPGA Fabric Entries (with minimum general routing)       <<====== AND with spi_clock_en = ~spi_select_in
- SGMII-CDR, SerDes/PCS clocks
- OSC Clock
*/
//logic spi_clock_gate_en /* synthesis syn_keep=1 nomerge="" */;
//always_comb spi_clock_gate_en = 1;
logic spi_clock_gate_en;
always_comb spi_clock_gate_en = ~spi_select_in;
always_comb spi_clock = spi_clock_in & spi_clock_gate_en;

spi_peripheral spi_peripheral (
    //.clock_in(spi_peripheral_clock),      // This 72 MHz clock is no longer used
    .reset_n_in(1'b1),	                    // De-couple SPI reset from PLL status 
                                            // SPI uses ONLY spi_select_in to reset
    .spi_select_in(spi_select_in),          // note: CS is active low
    .spi_clock_in(spi_clock),
    .spi_data_in(spi_data_in),
    .spi_data_out(spi_data_out),

    .address_out(opcode),
    .wr_data(operand),
    .rd_byte_count(rd_operand_count),
    .wr_byte_count(wr_operand_count),
    .data_rd_en(operand_rd_en),
    .data_wr_en(operand_wr_en),

    .response_1_in(response_1), // Graphics debug
    .response_2_in(response_2),
    .response_3_in(response_3),
    .response_4_in(response_4)
);

// Graphics
graphics graphics (
    .spi_clock_in(spi_clock),               // external SPI clock
    .spi_reset_n_in(spi_peripheral_reset_n),// synchronized external SPI CS

    .display_clock_in(display_clock),
    .display_reset_n_in(display_reset_n),

    .op_code_in(opcode),
    .operand_in(operand),
    .operand_valid_in(operand_wr_en),
    .operand_count_in(wr_operand_count),
    .operand_read(operand_rd_en),
    .rd_operand_count_in(rd_operand_count),
    .response_out(response_1),

    .display_clock_out(display_clock_out),
    .display_hsync_out(display_hsync_out),
    .display_vsync_out(display_vsync_out),
    .display_y_out({display_y3_out, display_y2_out, display_y1_out, display_y0_out}),
    .display_cb_out({display_cb2_out, display_cb1_out, display_cb0_out}),
    .display_cr_out({display_cr2_out, display_cr1_out, display_cr0_out})
);

// Camera
assign camera_clock_out = camera_clock;

camera camera (
    .global_reset_n_in(global_reset_n),

    .spi_clock_in(spi_clock),
    .spi_reset_n_in(spi_peripheral_reset_n),

    .pixel_clock_in(camera_pixel_clock),
    .pixel_reset_n_in(camera_pixel_reset_n),

    .jpeg_buffer_clock_in(jpeg_buffer_clock),
    .jpeg_buffer_reset_n_in(jpeg_buffer_reset_n),

    .jpeg_slow_clock_in(jpeg_slow_clock),
    .jpeg_slow_reset_n_in(jpeg_slow_reset_n),
    
    `ifdef NO_MIPI_IP_SIM
    .byte_to_pixel_frame_valid,
    .byte_to_pixel_line_valid,
    .byte_to_pixel_data,
    `else
    `ifdef RADIANT
    .mipi_clock_p_in(mipi_clock_p_in),
    .mipi_clock_n_in(mipi_clock_n_in),
    .mipi_data_p_in(mipi_data_p_in),
    .mipi_data_n_in(mipi_data_n_in),
    `endif
    `endif //NO_MIPI_IP_SIM
    
    // SPI interface
    .opcode_in(opcode),
    .operand_in(operand),
    .rd_operand_count_in(rd_operand_count),
    //.wr_operand_count_in(wr_operand_count),
    .operand_read(operand_rd_en),
    .operand_valid_in(operand_wr_en),

    .response_out(response_2)
);

// Chip ID register
spi_register #(
    .REGISTER_ADDRESS('hDB),
    .REGISTER_VALUE('h81)
) chip_id_1 (
    .opcode_in(opcode),
    .response_out(response_3)
);

// PLL control and status register
pll_csr pll_csr (
    // SPI clock
    .spi_clock_in(spi_clock),                   // external SPI clock
    .spi_reset_n_in(spi_peripheral_reset_n),    // async external SPI CS

    // SPI interface
    .opcode_in(opcode),
    .operand_in(operand),
    .operand_valid_in(operand_wr_en),
    .response_out(response_4),

    .pllpowerdown_n(pllpowerdown_n),                // pll power down control
    .image_buffer_read_en(image_buffer_read_en),    // seletcs SPI clock to read image buffer when PLL is off
    .pll_locked(pll_locked)                         // PLL lock status - needed in order to safely switch image buffer clocks
);
endmodule
