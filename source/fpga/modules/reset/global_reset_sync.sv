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

module global_reset_sync (
    input logic clock_in,
    input logic pll_locked_in,
    output logic pll_reset_out,
    output logic global_reset_n_out
);

    logic [7:0] global_reset_counter /* synthesis syn_keep=1 nomerge=""*/;
    logic [7:0] pll_reset_counter = 0 /* synthesis syn_keep=1 nomerge=""*/;

    always_ff @(posedge clock_in) begin

        if (!pll_reset_counter[7]) begin
            pll_reset_counter <= pll_reset_counter + 1;
            global_reset_n_out <= 0;
            global_reset_counter <= 0;
            pll_reset_out <= 1;
        end

        else begin

            if (pll_locked_in & !global_reset_counter[7]) begin
                global_reset_counter <= global_reset_counter + 1;
            end

            if (!pll_locked_in) begin
                global_reset_counter <= 0;
            end

            global_reset_n_out <= pll_locked_in && global_reset_counter[7];
            pll_reset_out <= 0;

        end

    end

endmodule