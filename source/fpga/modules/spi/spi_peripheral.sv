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
        spi_data_out <= 0;
        subperipheral_address_out <= 0;
        subperipheral_address_out_valid <= 0;
        subperipheral_data_out <= 0;
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
                spi_bit_index--;
            end

        end
    end
end

/*
// Internal signals
integer spi_bit_index;
bit spi_initial_data_read;

// This is only needed for Radiant to not complain about a clock pin
logic spi_gated_clock;
assign spi_gated_clock = spi_select_in == 0 ? spi_clock_in : 0;

// Sample incoming SPI bits on rising clock
always_ff @(posedge spi_gated_clock) begin

    // If address
    if (spi_bit_index > 7) begin
        subperipheral_address_out[spi_bit_index - 8] <= spi_data_in;
    end 
    
    // Otherwise data
    else begin
        subperipheral_data_out[spi_bit_index] <= spi_data_in;
    end

end

// On falling SPI clock, decrement inbound counter and push out SPI data
always_ff @(negedge spi_gated_clock, posedge spi_select_in) begin

    // Reset on a rising SPI select
    if (spi_select_in == 1) begin
        spi_bit_index <= 15; // Starts at 15 in order to give MSB first
        spi_initial_data_read <= 0;
    end

    // Otherwise decrement the bit counter
    else begin
        spi_bit_index--;

        // Roll underflows back over to read multiple bytes continiously
        if (spi_bit_index == -1) begin 
            spi_bit_index <= 7;
            spi_initial_data_read <= 1;
        end
    end
end

// Set the ready flags based on index and SPI select status
assign subperipheral_data_out_valid = spi_bit_index == 7 & 
                                      spi_select_in == 0 & 
                                      spi_initial_data_read 
                                    ? 1 
                                    : 0;

assign subperipheral_address_out_valid = spi_bit_index < 8 & 
                                     spi_select_in == 0
                                   ? 1 
                                   : 0;

// Directly assign the output data received from the periphiral
assign spi_data_out = subperipheral_data_in_valid & 
                      spi_bit_index < 8 
                    ? subperipheral_data_in[spi_bit_index] 
                    : 0;
*/

endmodule