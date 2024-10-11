/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

module spi_peripheral (
    // System clock + reset
    // input logic clock_in,            // This 72 MHz clock is no longer used
    input logic reset_n_in,

    // External SPI signals
    input logic spi_select_in,          // note: CS is active low
    input logic spi_clock_in,
    input logic spi_data_in,
    output logic spi_data_out,
    
    // Sub-peripheral interface
    output logic [7:0] address_out,     // was opcode_out
    output logic [7:0] wr_data,         // was operand_out
    output logic [31:0] rd_byte_count,  // was operand_count_out
    output logic [31:0] wr_byte_count,  // was operand_count_out
    output logic data_rd_en,            // was opcode_valid_out + operand_valid_out
    output logic data_wr_en,            // was opcode_valid_out + operand_valid_out

    input logic [7:0] rd_data_1,        // Graphics; was response_1_in
    input logic [7:0] rd_data_2,        // Camera; was response_2_in
    input logic [7:0] rd_data_3,        // Chip ID; was response_3_in
    input logic [7:0] rd_data_4         // PLL CSR
);

logic                   spi_resetn;
logic [3:0]             bit_index;
logic [7:0]             shift_reg;
logic [7:0]             rd_data;

always_comb  spi_resetn = reset_n_in & ~spi_select_in; // local reset
always_comb  wr_data = shift_reg;

always_comb  rd_data = rd_data_1 | rd_data_2 | rd_data_3 | rd_data_4;

// At rising edge of SPI clock keep track data bytes and bits within the data
always_ff @(posedge spi_clock_in or negedge spi_resetn)
if (!spi_resetn) begin
    bit_index <= 15;
    rd_byte_count <= 0;
    wr_byte_count <= 0;
    data_wr_en <= 0;
    data_rd_en <= 0;
end else begin
    // Roll underflows back over to read multiple bytes continiously
    if (bit_index == 0) begin
        bit_index <= 7;
        rd_byte_count <= rd_byte_count + 1;
    end
    else
        bit_index <= bit_index - 1;
    data_wr_en <= bit_index == 0;
    data_rd_en <= bit_index == 1;
    if(data_wr_en)
        wr_byte_count <= rd_byte_count;
end

// At falling edge of SPI clock, shift out read data
always @(negedge spi_clock_in or negedge spi_resetn)
if (!spi_resetn)
    spi_data_out <= 0;
else if (bit_index == 7)
    spi_data_out <= rd_data[7];
else  if (~bit_index[3])  
    spi_data_out <= shift_reg[7];
    
// At rising edge of SPI clock, shift in address/data phases    
always_ff @(posedge spi_clock_in)
if (bit_index[3]) 
    address_out <= {address_out, spi_data_in};
else if (bit_index == 7)
    shift_reg <= {rd_data, spi_data_in};
else
    shift_reg <= {shift_reg, spi_data_in};

endmodule
