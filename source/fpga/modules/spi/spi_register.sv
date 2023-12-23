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

module spi_register #(
    parameter REGISTER_ADDRESS = 'h00,
    parameter REGISTER_VALUE = 'h00
)(
    input logic clock_in,
    input logic reset_n_in,

    input logic [7:0] opcode_in,
    input logic opcode_valid_in,
    
    output logic [7:0] response_out,
    output logic response_valid_out
);

    always_ff @(posedge clock_in) begin
        
        if (reset_n_in == 0) begin
            response_out <= 0;
            response_valid_out <= 0;
        end

        else begin
            if (opcode_in == REGISTER_ADDRESS) begin
                response_out <= REGISTER_VALUE;
                response_valid_out <= 1;
            end
        end

    end

endmodule