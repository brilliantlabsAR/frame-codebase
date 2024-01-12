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
 
module image_buffer (
    input logic clock,
    input logic reset_n,

    input logic [13:0] write_address,
    input logic [15:0] read_address,

    input logic [31:0] write_data,
    output logic [7:0] read_data,

    input logic write_enable
);

`ifndef RADIANT (* ram_style="huge" *) `endif reg [31:0] mem [0:16384];

always @(posedge clock) begin
    if (reset_n == 1) begin
        if (write_enable) begin
            mem[write_address] <= write_data;
        end
    end
end

always_comb begin
    case (read_address[1:0])
        2'b00: read_data = mem[read_address[15:2]][31:24];
        2'b01: read_data = mem[read_address[15:2]][23:16];
        2'b10: read_data = mem[read_address[15:2]][15:8];
        2'b11: read_data = mem[read_address[15:2]][7:0];
    endcase
end

endmodule