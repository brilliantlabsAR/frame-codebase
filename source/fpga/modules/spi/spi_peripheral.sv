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
    // External SPI signals
    input logic spi_clock,
    input logic spi_select,
    input logic spi_data_in,
    output logic spi_data_out,

    // External subperipheral interface signals
    output logic [7:0] subperipheral_address_out,
    output logic subperipheral_address_valid,
    output logic [7:0] subperipheral_data_out,
    output logic subperipheral_data_out_valid,
    input logic [7:0] subperipheral_data_in,
    input logic subperipheral_data_in_valid
);

// Internal signals
integer spi_bit_index;
bit spi_initial_data_read;

// Sample incoming SPI bits on rising clock
always_ff @(posedge spi_clock) begin

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
always_ff @(negedge spi_clock, posedge spi_select) begin

    // Reset on a rising SPI select
    if (spi_select == 1) begin
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
                                      spi_select == 0 & 
                                      spi_initial_data_read 
                                    ? 1 
                                    : 0;

assign subperipheral_address_valid = spi_bit_index < 8 & 
                                     spi_select == 0
                                   ? 1 
                                   : 0;

// Directly assign the output data received from the periphiral
assign spi_data_out = subperipheral_data_in_valid & 
                      spi_bit_index < 7 
                    ? subperipheral_data_in[spi_bit_index] 
                    : 0;

endmodule