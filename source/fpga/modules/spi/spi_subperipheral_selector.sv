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

module spi_subperipheral_selector (
    input logic [7:0] address_in,
    input logic address_in_valid,

    output logic [7:0] peripheral_data_out,
    output logic peripheral_data_out_valid,

    output logic subperipheral_1_enable_out,
    input logic [7:0] subperipheral_1_data_in,
    input logic subperipheral_1_data_in_valid,

    output logic subperipheral_2_enable_out,
    input logic [7:0] subperipheral_2_data_in,
    input logic subperipheral_2_data_in_valid
);
    
    always_comb begin
        
        if (address_in_valid) begin
            case (address_in)
            'hDB: begin
                peripheral_data_out = subperipheral_1_data_in;
                peripheral_data_out_valid = subperipheral_1_data_in_valid;
                subperipheral_1_enable_out = 1;
                subperipheral_2_enable_out = 0;
            end 

            'hDC: begin
                peripheral_data_out = subperipheral_2_data_in;
                peripheral_data_out_valid = subperipheral_2_data_in_valid;
                subperipheral_1_enable_out = 0;
                subperipheral_2_enable_out = 1;
            end 

            default: begin
                peripheral_data_out = 0;
                peripheral_data_out_valid = 0;
                subperipheral_1_enable_out = 0;
                subperipheral_2_enable_out = 0;
            end
            endcase
        end

        else begin
            peripheral_data_out = 0;
            peripheral_data_out_valid = 0;
            subperipheral_1_enable_out = 0;
            subperipheral_2_enable_out = 0;
        end

    end

endmodule