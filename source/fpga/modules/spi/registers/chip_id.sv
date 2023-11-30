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

module spi_register_chip_id #(
    parameter CHIP_ID = 'hF1
)(
    input logic system_clock,
    input logic enable,
    
    output logic [7:0] data_out,
    output logic data_out_valid
);

    always_ff @(posedge system_clock) begin
        
        if (enable == 0) begin
            data_out_valid <= 0;
        end

        else begin
            data_out <= CHIP_ID;
            data_out_valid <= 1;
        end

    end

endmodule