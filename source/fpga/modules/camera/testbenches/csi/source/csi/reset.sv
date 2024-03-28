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
    output logic pll_reset_n_out,
    output logic global_reset_n_out
);

    logic [7:0] global_reset_counter /* synthesis syn_keep=1 nomerge=""*/;
    logic [7:0] pll_reset_counter /* synthesis syn_keep=1 nomerge=""*/;

    initial pll_reset_counter = 0;

    always_ff @(posedge clock_in) begin

        if (!pll_reset_counter[3]) begin
            pll_reset_counter <= pll_reset_counter + 1;
            global_reset_n_out <= 0;
            global_reset_counter <= 0;
            pll_reset_n_out <= 0;
        end

        else begin

            if (pll_locked_in & !global_reset_counter[3]) begin
                global_reset_counter <= global_reset_counter + 1;
            end

            if (!pll_locked_in) begin
                global_reset_counter <= 0;
            end

            global_reset_n_out <= pll_locked_in && global_reset_counter[3];
            pll_reset_n_out <= 1;

        end

    end

endmodule

module reset_sync (
    input logic clock_in,
    input logic async_reset_n_in,
    output logic sync_reset_n_out
);

    logic metastable_reset_n;

    always @(posedge clock_in or negedge async_reset_n_in) begin

        if (~async_reset_n_in) begin
            sync_reset_n_out <= 0;
            metastable_reset_n <= 0;
        end else begin
            metastable_reset_n <= 1;
            sync_reset_n_out <= metastable_reset_n;
        end

    end

endmodule