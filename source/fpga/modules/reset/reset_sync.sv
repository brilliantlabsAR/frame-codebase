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

    logic metastable1_reset_n;
    logic metastable2_reset_n;
    
    always @(posedge clock_in) begin

        metastable1_reset_n <= async_reset_n_in;
        metastable2_reset_n <= metastable1_reset_n;
        sync_reset_n_out <= metastable2_reset_n;
        
    end

endmodule