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

module spi (
    input logic spi_clock,
    input logic spi_select,
    input logic spi_data_in,
    output logic spi_data_out
);

enum {IDLE, START} state;

always_ff @(posedge spi_clock) begin

    if (spi_select == 1) begin

        state <= IDLE;

    end else begin

        state <= START;

    end

    // Hold reset whenever the 

end

endmodule