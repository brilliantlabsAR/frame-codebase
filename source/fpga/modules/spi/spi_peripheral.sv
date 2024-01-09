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
    input logic clock_in,
    input logic reset_n_in,

    // External SPI signals
    input logic spi_select_in,
    input logic spi_clock_in,
    input logic spi_data_in,
    output logic spi_data_out,

    // Sub-peripheral interface
    output logic [7:0] opcode_out,
    output logic [7:0] operand_out,
    output logic opcode_valid_out,
    output logic operand_valid_out,
    output integer operand_count_out,

    input logic [7:0] response_1_in,
    input logic [7:0] response_2_in,
    input logic [7:0] response_3_in,
    input logic response_1_valid_in,
    input logic response_2_valid_in,
    input logic response_3_valid_in
);

logic metastable_spi_select_in;
logic metastable_spi_clock_in;
logic metastable_spi_data_in;
logic stable_spi_select_in;
logic stable_spi_clock_in;
logic stable_spi_data_in;
logic last_stable_spi_clock_in;
logic [7:0] response_reg;

integer spi_bit_index;

always_ff @(posedge clock_in) begin

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
    if (stable_spi_select_in == 1 | reset_n_in == 0) begin
        spi_bit_index <= 15;
        opcode_valid_out <= 0;
        operand_valid_out <= 0;
        operand_count_out <= 0;
        response_reg <= 0;
    end

    // Normal operation
    else begin

        // Choose output data based on valid response
        case ({response_1_valid_in, response_2_valid_in, response_3_valid_in})
            'b100: response_reg <= response_1_in;
            'b010: response_reg <= response_2_in;
            'b001: response_reg <= response_3_in;
            default: response_reg <= 'h0;
        endcase

        // Output data
        if (spi_bit_index < 8) begin
            spi_data_out <= response_reg[spi_bit_index];
        end

        else begin
            spi_data_out <= 0;
        end

        // On rising SPI clock, buffer in data
        if (last_stable_spi_clock_in == 0 & stable_spi_clock_in == 1) begin

            // If address
            if (spi_bit_index > 7) begin
                opcode_out[spi_bit_index - 8] <= stable_spi_data_in;

                if (spi_bit_index == 8) begin
                    opcode_valid_out <= 1;
                end
            end 
            
            // Otherwise data
            else begin
                operand_out[spi_bit_index] <= stable_spi_data_in;
                
                if (spi_bit_index == 0) begin
                    operand_valid_out <= 1;
                end

                else begin
                    operand_valid_out <= 0;
                end
            end

            // Roll underflows back over to read multiple bytes continiously
            if (spi_bit_index == 0) begin 
                spi_bit_index <= 7;
                operand_count_out <= operand_count_out + 1;
            end

            else begin
                spi_bit_index <= spi_bit_index - 1;
            end

        end
    end
end

endmodule