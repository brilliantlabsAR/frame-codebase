/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Chips & Scripts (rmetchev@ieee.org) 
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

    read_data_out <= mem[address_in];

end

endmodule

module image_buffer (
    input logic write_clock_in,
    input logic read_clock_in,
    input logic write_reset_n_in,
    input logic read_reset_n_in,

    input logic [15:0] write_address_in,
    input logic [15:0] read_address_in,

    input logic [31:0] write_data_in,
    output logic [7:0] read_data_out,

    input logic write_read_n_in
);

// Write to read CDC
logic [15:0] write_address;
logic [31:0] write_data;
logic write_enable;
logic [2:0] write_enable_cdc;
logic write_enable_cdc_pulse;

assign write_enable_cdc_pulse = write_enable_cdc[2:1] == 2'b01;

always @(posedge read_clock_in) begin : cdc

    if (read_reset_n_in == 0) begin
        write_enable <= 0;
        write_enable_cdc <= 0;
    end

    else begin
        write_enable_cdc <= {write_enable_cdc[1:0], write_read_n_in};

        if (write_enable_cdc_pulse) begin
            write_address <= write_address_in >> 2;
            write_data <= write_data_in;
        end

        write_enable <= write_enable_cdc_pulse;
    end

end

// Read/write selection
logic [13:0] address;
assign address = write_enable ? write_address : read_address_in[15:2];

// Read 8 bits of 32 based on address
logic [31:0] read_data;
always @(posedge read_clock_in) begin
    case (read_address_in[1:0])
        'd0: read_data_out <= read_data[7:0];
        'd1: read_data_out <= read_data[15:8];
        'd2: read_data_out <= read_data[23:16];
        'd3: read_data_out <= read_data[31:24];
    endcase
end

// Large RAM
//inferred_lram inferred_lram (
    //.clock_in(read_clock_in), // Use the faster clock
    //.address_in(address),
    //.write_data_in(write_data),
    //.read_data_out(read_data),
    //.write_enable_in(write_enable)
//);

image_buffer_ip lram(
        .clk_i(read_clock_in),
        .dps_i(1'b0),
        .rst_i(1'b0),
        .clk_en_i(1'b1),
        .wr_en_i(write_enable),
        .wr_data_i(write_data),
        .addr_i(address),
        .rd_data_o(read_data),
        .lramready_o( ),
        .rd_datavalid_o( )
);

endmodule