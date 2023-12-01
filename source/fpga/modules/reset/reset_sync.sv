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

module reset_sync (
	input logic clock,
	input logic async_reset_n,
	output logic sync_reset_n
);

	logic metastable_reset_n;
	
	always @(posedge clock or negedge async_reset_n) begin
		if (~async_reset_n) begin
			sync_reset_n <= 0;
			metastable_reset_n <= 0;
		end else begin
			metastable_reset_n <= async_reset_n;
			sync_reset_n <= metastable_reset_n;
		end
	end

endmodule