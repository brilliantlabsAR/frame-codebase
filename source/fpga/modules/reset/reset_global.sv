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

module reset_global (
	input logic clock_in,
	input logic pll_locked_in,
	output logic global_reset_n_out
);

    logic [7:0] reset_counter /* synthesis syn_keep=1 nomerge=""*/;

    always_ff @(posedge clock_in) begin

        if (pll_locked_in & !reset_counter[7]) begin
            reset_counter <= reset_counter + 1;
        end

       if (!pll_locked_in) reset_counter <= 0;
        
    end

    assign global_reset_n_out = pll_locked_in & reset_counter[7] ? 1:0;

endmodule