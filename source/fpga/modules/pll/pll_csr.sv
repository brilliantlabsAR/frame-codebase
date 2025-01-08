/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

module pll_csr #(
    parameter PLL_CSR_BASE = 'h40,
    parameter PLLPOWERDOWN_N_DEFAULT = 1,
    parameter IMAGE_BUFFER_READ_EN_DEFAULT = 0
)(
    // SPI clock
    input logic spi_clock_in,
    input logic spi_reset_n_in,

    // SPI interface
    input logic [7:0] opcode_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    output logic [7:0] response_out,

    output logic pllpowerdown_n,            // pll power down control
                                            // 0 .. PLL power down
                                            // 1 .. PLL power on (default)
    output logic image_buffer_read_en,      // seletcs SPI clock to read image buffer when PLL is off
                                            // 0 .. pixel clock (default)
                                            // 1 .. spi clock
    input logic pll_locked                  // PLL lock status - needed in order to safely switch image buffer clocks
);

always @(negedge spi_clock_in or negedge spi_reset_n_in) // Async reset
if (!spi_reset_n_in) begin
    pllpowerdown_n <= PLLPOWERDOWN_N_DEFAULT;
    image_buffer_read_en <= IMAGE_BUFFER_READ_EN_DEFAULT;
end
else if (operand_valid_in & opcode_in == PLL_CSR_BASE) begin
    pllpowerdown_n <= operand_in[0];
    image_buffer_read_en <= operand_in[1];
end

// CDC
//logic [1:0] pll_locked_cdc;
//always @(posedge spi_clock_in) pll_locked_cdc <= {pll_locked_cdc, pll_locked};

//always_comb response_out = opcode_in == PLL_CSR_BASE + 1 ? pll_locked_cdc[1] : '0;
always_comb response_out = opcode_in == PLL_CSR_BASE + 1 ? pll_locked : '0;

endmodule

