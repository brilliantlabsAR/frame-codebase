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
    input logic clock_in,
    input logic async_reset_n_in,
    output logic sync_reset_n_out
);

    logic metastable_reset_n;
    
    always @(posedge clock_in or negedge async_reset_n_in) begin

        if (async_reset_n_in == 0) begin
            sync_reset_n_out <= 0;
            metastable_reset_n <= 0;
        end

        else begin
            metastable_reset_n <= 1;
            sync_reset_n_out <= metastable_reset_n;
        end
        
    end

endmodule