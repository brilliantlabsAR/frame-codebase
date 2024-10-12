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

module inferred_lram (
    input logic clock_in,
    input logic [13:0] address_in,
    input logic [31:0] write_data_in,
    output logic [31:0] read_data_out,
    input logic write_enable_in
);

`ifndef RADIANT (* ram_style="huge" *) `endif logic [31:0] mem [0:16383];
always @(posedge clock_in) begin
    if (write_enable_in) begin
        mem[address_in] <= write_data_in;
    end
    read_data_out <= mem[address_in]; //Enable Output Register = False
end

endmodule

module image_buffer (
    input logic clock_in,
    input logic [15:0] write_address_in,
    input logic [15:0] read_address_in,
    input logic [31:0] write_data_in,
    output logic [7:0] read_data_out,
    input logic write_read_n_in
);

// Read/write selection
logic [13:0] address;
assign address = write_read_n_in ? write_address_in : read_address_in[15:2];

// Read 8 bits of 32 based on address
logic [31:0] read_data;
always_comb begin
    case (read_address_in[1:0])
        'd0: read_data_out = read_data[7:0];
        'd1: read_data_out = read_data[15:8];
        'd2: read_data_out = read_data[23:16];
        'd3: read_data_out = read_data[31:24];
    endcase
end

// Large RAM
inferred_lram inferred_lram (
    .clock_in(clock_in), // Use the faster clock
    .address_in(address),
    .write_data_in(write_data_in),
    .read_data_out(read_data),
    .write_enable_in(write_read_n_in)
);

endmodule
