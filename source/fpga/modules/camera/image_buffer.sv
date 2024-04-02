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

module inferred_lram (
    input logic clock_in,

    input logic [13:0] write_address_in,
    input logic [13:0] read_address_in,
    input logic [31:0] write_data_in,
    output logic [31:0] read_data_out,

    input logic write_enable_in
);

`ifndef RADIANT (* ram_style="huge" *) `endif logic [31:0] mem [0:16383];

always @(posedge clock_in) begin
    if (write_enable_in) begin
        mem[write_address_in] <= write_data_in;
    end

    read_data_out <= mem[read_address_in];
end

endmodule

module image_buffer (
    input logic pixel_clock_in,
    input logic spi_clock_in,
    input logic pixel_reset_n_in,
    input logic spi_reset_n_in,

    input logic [15:0] write_address_in, 
    input logic [15:0] read_address_in,

    input logic [31:0] write_data_in,
    output logic [7:0] read_data_out,

    input logic write_read_n_in
);

logic [13:0] packed_write_address;
logic [31:0] packed_write_data;
logic packed_write_enable;

jenc_cdc jenc_cdc (
    .jpeg_out_address(write_address_in),
    .jpeg_out_data(write_data_in),
    .jpeg_out_data_valid(write_read_n_in),

    .jpeg_buffer_address(packed_write_address),
    .jpeg_buffer_write_data(packed_write_data),
    .jpeg_buffer_write_enable(packed_write_enable),
    
    .clock_pixel_in(pixel_clock_in),
    .reset_pixel_n_in(pixel_clock_in),
    .clock_spi_in(spi_clock_in),
    .reset_spi_n_in(spi_reset_n_in)
);

logic [31:0] read_data;
logic [1:0] read_address_q;

always @(posedge spi_clock_in) begin
    //read_address_q <= read_address_in;
    case (read_address_in[1:0])
        'd0: read_data_out <= read_data[7:0];
        'd1: read_data_out <= read_data[15:8];
        'd2: read_data_out <= read_data[23:16];
        'd3: read_data_out <= read_data[31:24];
    endcase
end

inferred_lram inferred_lram (
    .clock_in(spi_clock_in), // Use the faster clock
    .write_address_in(packed_write_address),
    .read_address_in(read_address_in[15:2]),
    .write_data_in(packed_write_data),
    .read_data_out(read_data),
    .write_enable_in(packed_write_enable)
);

endmodule
