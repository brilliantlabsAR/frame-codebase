/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-fpga
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

`include "modules/camera/camera.sv"
`include "modules/graphics/graphics.sv"
`include "modules/spi/spi.sv"

module top (
    input logic button,
    output logic led_1,
    output logic led_2
);
    logic clk;

	OSC_CORE #(
		.HF_CLK_DIV("2") // 150MHz clock
	) hf_osc (
		.HFOUTEN(1'b1),
		.HFCLKOUT(clk)
	);

    logic [31:0] sub_clk_counter;

    always_ff @(posedge clk) begin
        sub_clk_counter <= sub_clk_counter + 1;
    end

    always_ff @(posedge sub_clk_counter[21]) begin
        led_1 <= ~led_1;
    end   

endmodule