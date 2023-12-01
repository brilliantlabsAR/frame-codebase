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
    input logic clock,
    input logic reset_n,
    input logic enable,
    input logic data_in_valid,
    
    output logic [7:0] data_out,
    output logic data_out_valid
);

    logic [7:0] byte_counter;
    logic last_data_in_valid;

    always_ff @(posedge clock) begin

        last_data_in_valid <= data_in_valid;

        if (enable == 0 | reset_n == 0) begin
            data_out_valid <= 0;
            byte_counter <= 0;
        end

        else begin

            if (last_data_in_valid == 0 & data_in_valid) begin
                byte_counter <= byte_counter + 1;
            end

            case (byte_counter)
                0: data_out <= "T";
                1: data_out <= "e";
                2: data_out <= "s";
                3: data_out <= "t";
                default: data_out <= 0;
            endcase

            data_out_valid <= 1;
        end
    end

endmodule