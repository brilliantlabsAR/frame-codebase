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

integer bit_index = 15;
logic opcode_valid_metastable;
logic operand_valid_metastable;

logic local_reset_n;
always_comb local_reset_n = reset_n_in & ~spi_select_in;

// Workaround for error: The clock port is assigned to a non-clock pin
logic spi_local_clock;
always_comb spi_local_clock = spi_clock_in | spi_select_in;

// SPI input logic and bit counting
always_ff @(posedge spi_local_clock or negedge local_reset_n) begin

    if (local_reset_n == 0) begin
        bit_index <= 15;
        opcode_valid_metastable <= 0;
        operand_valid_metastable <= 0;
        operand_count_out <= 0;
    end

    else begin

        // Count down bit_index from 15 - 0 for first opcode and operand. 
        // Rolls over from 0 to 7 and repeats for subsequent operands
        if (bit_index > 0) begin
            bit_index <= bit_index - 1;
        end

        else begin
            bit_index <= 7;
            operand_count_out <= operand_count_out + 1;
        end

        // Pull in data from SPI based on bit index
        if (bit_index > 7) begin
            opcode_out[bit_index - 8] <= spi_data_in;
        end

        else begin
            operand_out[bit_index] <= spi_data_in;
        end

        // Set input valid flags based on bit index
        if (bit_index == 8) begin
            opcode_valid_metastable <= 1;
        end

        if (bit_index == 0) begin
            operand_valid_metastable <= 1;
        end

        else begin
            operand_valid_metastable <= 0;
        end
        
    end
    
end

// SPI output logic
logic [7:0] spi_response_reg;

always_ff @(negedge spi_local_clock or negedge local_reset_n) begin

    if (local_reset_n == 0) begin
        spi_data_out <= 0;
    end

    else begin
        
        // Push SPI data out simply from spi_response_reg
        if (bit_index < 8) begin
            spi_data_out <= spi_response_reg[bit_index];
        end

    end

end

always_comb begin
    case ({response_1_valid_in, response_2_valid_in, response_3_valid_in})
        'b100: spi_response_reg = response_1_in;
        'b010: spi_response_reg = response_2_in;
        'b001: spi_response_reg = response_3_in;
        default: spi_response_reg = 'h0;
    endcase
end

// Clock crossing
always_ff @(posedge clock_in) begin

    if (reset_n_in == 0) begin
        opcode_valid_out <= 0;
        operand_valid_out <= 0;
    end

    else begin
        opcode_valid_out <= opcode_valid_metastable;
        operand_valid_out <= operand_valid_metastable;
    end

end

endmodule