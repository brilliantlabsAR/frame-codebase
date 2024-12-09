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

module spi_register #(
    parameter REGISTER_ADDRESS = 'hdb,
    parameter REGISTER_VALUE = 'h81
)(
    input logic [7:0] opcode_in,
    output logic [7:0] response_out
);

always_comb response_out = opcode_in == REGISTER_ADDRESS ? REGISTER_VALUE : '0;

endmodule
