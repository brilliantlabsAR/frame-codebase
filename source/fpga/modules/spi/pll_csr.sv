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
    parameter PLL_CSR_BASE = 'h40
)(
    // SPI clock
    input logic spi_clock_in,
    input logic spi_async_peripheral_reset_n,

    // SPI interface
    input logic [7:0] opcode_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    output logic [7:0] response_out
    
    
    output logic pllpowerdown_n,            // pll power down control
                                            // 0 .. PLL power down (default)
                                            // 1 .. PLL power on
    output logic image_buffer_clock_select, // seletcs SPI clock to read image buffer when PLL is off
                                            // 0 .. spi clock (default)
                                            // 1 .. pixel clock
    input logic pll_locked                  // PLL lock status - needed in order to safely switch image buffer clocks
);

always @(negedge spi_clock_in or negedge spi_async_peripheral_reset_n) // Async reset
if (!spi_async_peripheral_reset_n) begin
    pllpowerdown <= 0;
    image_buffer_clock_select <= 0;
end
else if (operand_valid_in & opcode_in == PLL_CSR_BASE) begin
    pllpowerdown <= operand_in[0];
    image_buffer_clock_select <= operand_in[1];
end

// CDC
logic [1:0] pll_locked_cdc;
always @(posedge spi_clock_in) pll_locked_cdc <= {pll_locked_cdc, pll_locked};

always_comb response_out = opcode_in == PLL_CSR_BASE + 1 ? pll_locked_cdc[1] : '0;

endmodule

