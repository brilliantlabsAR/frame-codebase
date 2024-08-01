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

// External SPI domain signals
logic spi_edge;
assign spi_edge = spi_clock_in | spi_select_in;

integer spi_bit_index = 0;
logic [7:0] spi_response_reg;

logic [7:0] spi_opcode;
logic [7:0] spi_operand;
logic spi_opcode_valid;
logic spi_operand_valid;
integer spi_operand_count = 0;

// SPI input & bit counting login
always_ff @(posedge spi_edge) begin

    if (spi_select_in == 1) begin
        spi_bit_index <= 0;

        spi_opcode <= 0;
        spi_operand <= 0;
        spi_opcode_valid <= 0;
        spi_operand_valid <= 0;
        spi_operand_count <= 0;
    end

    else begin

        // Count up spi_bit_index from 0 - 15 for first opcode and operand. Roll
        // over to 8 and repeat for subsequent operands
        if (spi_bit_index < 15) begin
            spi_bit_index <= spi_bit_index + 1;
        end

        else begin
            spi_bit_index <= 8;
            spi_operand_count <= spi_operand_count + 1;
        end

        // Pull in data from SPI based on bit index
        if (spi_bit_index < 8) begin
            spi_opcode[spi_bit_index] <= spi_data_in;
        end

        else begin
            spi_operand[spi_bit_index - 8] <= spi_data_in;
        end

        // Set input valid flags based on bit index
        if (spi_bit_index == 7) begin
            spi_opcode_valid <= 1;
        end

        if (spi_bit_index == 15) begin
            spi_operand_valid <= 1;
        end

        else begin
            spi_operand_valid <= 0;
        end
        
    end
    
end

// SPI output login
always_ff @(negedge spi_edge) begin

    if (spi_select_in == 1) begin
        spi_data_out <= 0;
    end

    else begin
        
        // Push SPI data out simply from spi_response_reg
        if (spi_bit_index > 7) begin
            spi_data_out <= spi_response_reg[spi_bit_index - 8];
        end

    end

end

// Internal clock domain side login
always_ff @(posedge clock_in) begin

    if (reset_n_in == 0) begin
        spi_response_reg <= 0;
        opcode_valid_out <= 0;
        operand_valid_out <= 0;
        operand_count_out <= 0;
    end

    else begin
        
        // Update response reg whenever response valid is high. Note this 
        // register has no clock domain crossing since it's set well before the 
        // first SPI bit is pushed out
        case ({response_1_valid_in, response_2_valid_in, response_3_valid_in})
            'b100: spi_response_reg <= response_1_in;
            'b010: spi_response_reg <= response_2_in;
            'b001: spi_response_reg <= response_3_in;
            default: spi_response_reg <= 'h0;
        endcase

        // Clock domain crossing from external to internal spi clocks
        opcode_out <= spi_opcode;
        operand_out <= spi_operand;
        opcode_valid_out <= spi_opcode_valid;
        operand_valid_out <= spi_operand_valid;
        operand_count_out <= spi_operand_count;
        
    end

end

endmodule