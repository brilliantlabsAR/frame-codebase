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

module spi_register_version_string (
    input logic enable,
    input logic data_in_valid,
    output logic [7:0] data_out,
    output logic data_out_valid
);
    integer byte_counter;

    always_ff @(posedge enable, posedge data_in_valid) begin

        if (data_in_valid == 0) begin
            byte_counter <= 0;
        end

        else begin
            byte_counter++;
        end

    end

    assign data_out_valid = enable;

    always_comb begin
        
        case (byte_counter)
            0: data_out = "T";
            1: data_out = "e";
            2: data_out = "s";
            3: data_out = "t";
        endcase

    end

endmodule