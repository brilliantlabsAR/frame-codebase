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

module spi_register_chip_id (
    input logic [7:0] address_in,
    input logic address_valid,
    output logic [7:0] data_out,
    output logic data_out_valid
);
    always_ff @(posedge address_valid) begin

        if (address_in == 'h0A) begin
            data_out <= 'hF1;
            data_out_valid <= 1;
        end

        else begin
            data_out <= 'h00;
            data_out_valid <= 0;
        end
    end

endmodule