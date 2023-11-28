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

module spi_controller (
    // External SPI signals
    input logic spi_clock,
    input logic spi_select,
    input logic spi_data_in,
    output logic spi_data_out,

    // External perhipheral interface signals
    output logic [7:0] peripheral_address_out,
    output logic [7:0] peripheral_data_out,
    input logic [7:0] peripheral_data_in,
    output logic peripheral_address_valid,
    output logic peripheral_data_out_valid,
    input logic peripheral_data_in_valid
);

// Internal signals
logic [7:0] spi_address_buffer;
logic [7:0] spi_data_in_buffer;
integer spi_bit_index;
bit spi_address_valid;
bit spi_data_in_valid;

// Reset SPI on falling select line
always_ff @(negedge spi_select) begin
    
    // Decrement from 15 because we want MSB first
    spi_bit_index <= 15;

end

// Sample incoming SPI bits on rising clock
always_ff @(posedge spi_clock) begin

    // If address
    if (spi_bit_index > 7) begin

        spi_address_buffer[spi_bit_index - 8] <= spi_data_in;

        if (spi_bit_index == 8) begin
            spi_address_valid <= 1;
        end 
        
        else begin
            spi_address_valid <= 0;
        end

    end 
    
    // Otherwise data
    else begin

        spi_data_in_buffer[spi_bit_index] <= spi_data_in;

        if (spi_bit_index == 0) begin
            spi_data_in_valid <= 1;
        end 
        
        else begin
            spi_data_in_valid <= 0;
        end

    end

end

// On falling SPI clock, decrement inbound counter and push out SPI data
always_ff @(negedge spi_clock) begin

    // Decrement because we are working in MSB mode
    spi_bit_index--;

    // Roll underflows back over to read multiple bytes continiously
    if (spi_bit_index == -1) begin 
        spi_bit_index <= 7;
    end

    // Flag if address output to peripheral is ready
    if (spi_address_valid) begin
        peripheral_address_valid <= 1;
    end

    else begin
        peripheral_address_valid <= 0;
    end

    // Flag if data output to peripheral is ready
    if (spi_data_in_valid) begin
        peripheral_data_out_valid <= 1;
    end

    else begin
        peripheral_data_out_valid <= 0;
    end

end

// Once address and data is valid, buffer them to the output
always_ff @(posedge spi_address_valid) begin
    peripheral_address_out <= spi_address_buffer;
end

always_ff @(posedge spi_data_in_valid) begin
    peripheral_data_out <= spi_data_in_buffer;
end

// Directly assign the output data received from the periphiral
assign spi_data_out = 
    peripheral_data_in_valid ? peripheral_data_in[spi_bit_index] 
                             : 0;

endmodule