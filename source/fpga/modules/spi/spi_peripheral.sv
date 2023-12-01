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

module spi_peripheral (
    input logic system_clock,

    // External SPI signals
    input logic spi_select_in,
    input logic spi_clock_in,
    input logic spi_data_in,
    output logic spi_data_out,

    // External subperipheral interface signals
    output logic [7:0] subperipheral_address_out,
    output logic subperipheral_address_out_valid,
    output logic [7:0] subperipheral_data_out,
    output logic subperipheral_data_out_valid,
    input logic [7:0] subperipheral_data_in,
    input logic subperipheral_data_in_valid
);

logic metastable_spi_select_in;
logic metastable_spi_clock_in;
logic metastable_spi_data_in;
logic stable_spi_select_in;
logic stable_spi_clock_in;
logic stable_spi_data_in;
logic last_stable_spi_clock_in;

integer spi_bit_index;

always_ff @(posedge system_clock) begin

    // Synchronizer
    metastable_spi_select_in <= spi_select_in;
    metastable_spi_clock_in <= spi_clock_in;
    metastable_spi_data_in <= spi_data_in;
    stable_spi_select_in <= metastable_spi_select_in;
    stable_spi_clock_in <= metastable_spi_clock_in;
    stable_spi_data_in <= metastable_spi_data_in;

    // Edge detection
    last_stable_spi_clock_in <= stable_spi_clock_in;

    // Reset
    if (stable_spi_select_in == 1) begin
        spi_bit_index <= 15;
        subperipheral_address_out_valid <= 0;
        subperipheral_data_out_valid <= 0;
    end

    // Normal operation
    else begin

        // Set output whenever it's ready
        if (subperipheral_data_in_valid) begin
            spi_data_out <= subperipheral_data_in[spi_bit_index];
        end

        else begin
            spi_data_out <= 0;
        end
        
        // On rising SPI clock, buffer in data
        if (last_stable_spi_clock_in == 0 & stable_spi_clock_in == 1) begin

            // If address
            if (spi_bit_index > 7) begin
                subperipheral_address_out[spi_bit_index - 8] <= stable_spi_data_in;

                if (spi_bit_index == 8) begin
                    subperipheral_address_out_valid <= 1;
                end
            end 
            
            // Otherwise data
            else begin
                subperipheral_data_out[spi_bit_index] <= stable_spi_data_in;
                
                if (spi_bit_index == 0) begin
                    subperipheral_data_out_valid <= 1;
                end

                else begin
                    subperipheral_data_out_valid <= 0;
                end
            end

            // Roll underflows back over to read multiple bytes continiously
            if (spi_bit_index == 0) begin 
                spi_bit_index <= 7;
            end

            else begin
                spi_bit_index <= spi_bit_index - 1;
            end

        end
    end
end

endmodule