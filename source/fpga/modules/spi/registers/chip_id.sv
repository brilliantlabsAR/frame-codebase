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

module spi_register_chip_id (
    input logic enable,
    output logic [7:0] data_out,
    output logic data_out_valid
);

    assign data_out = enable ? 'hF1 : 0;
    assign data_out_valid = enable;

endmodule