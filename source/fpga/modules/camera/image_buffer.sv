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
    input logic reset_n_in,

    input logic [13:0] address_in,
    input logic [31:0] write_data_in,
    output logic [31:0] read_data_out,

    input logic write_enable_in
);

`ifndef RADIANT (* ram_style="huge" *) `endif logic [31:0] mem [0:16383];

always @(posedge clock_in) begin

    if (reset_n_in == 0) begin
        read_data_out <= 0;
    end

    else begin
        if (write_enable_in) begin
            mem[address_in] <= write_data_in;
        end

        read_data_out <= mem[address_in];
    end
end

endmodule

module image_buffer (
    input logic write_clock_in,
    input logic read_clock_in,
    input logic write_reset_n_in,
    input logic read_reset_n_in,

    input logic [15:0] write_address_in, // TODO change this once we have a different port width
    input logic [15:0] read_address_in,

    input logic [7:0] write_data_in, // TODO change this once we have a different port width
    output logic [7:0] read_data_out,

    input logic write_read_n_in
);

// Write clock domain
logic [13:0] packed_write_address;
logic [31:0] packed_write_data;
logic packed_write_enable;

always @(posedge write_clock_in) begin

    if (write_reset_n_in == 0) begin
        packed_write_address <= 0;
        packed_write_data <= 0;
        packed_write_enable <= 0;
    end

    else begin
        if (write_read_n_in) begin
            case (write_address_in[1:0])
                'd0: packed_write_data <= {packed_write_data[31:8],  write_data_in                         };
                'd1: packed_write_data <= {packed_write_data[31:16], write_data_in, packed_write_data[7:0] };
                'd2: packed_write_data <= {packed_write_data[31:24], write_data_in, packed_write_data[15:0]};
                'd3: packed_write_data <= {                          write_data_in, packed_write_data[23:0]};
            endcase

            packed_write_address <= write_address_in[15:2];
            
            if (write_address_in[1:0] == 2'b11) begin
                packed_write_enable <= 1;
            end
            else begin
                packed_write_enable <= 0;
            end
        end

        else begin
            packed_write_data <= 0;
            packed_write_enable <= 0;
        end
    end

end

// Read clock domain
logic [13:0] packed_write_address_metastable;
logic [31:0] packed_write_data_metastable;
logic packed_write_enable_metastable;

logic [13:0] write_address;
logic [31:0] write_data;
logic write_enable;

logic [13:0] address;
logic [31:0] read_data;

always @(posedge read_clock_in) begin

    if (read_reset_n_in == 0) begin
        packed_write_address_metastable <= 0;
        packed_write_data_metastable <= 0;
        packed_write_enable_metastable <= 0;

        write_address <= 0;
        write_data <= 0;
        write_enable <= 0;
        
        read_data_out <= 0;
    end

    else begin
        packed_write_address_metastable <= packed_write_address;
        packed_write_data_metastable <= packed_write_data;
        packed_write_enable_metastable <= packed_write_enable;

        write_address <= packed_write_address_metastable;
        write_data <= packed_write_data_metastable;
        write_enable <= packed_write_enable_metastable;

        if (write_enable) begin
            read_data_out <= 0;
        end

        else begin
            case (read_address_in[1:0])
                'd0: read_data_out <= read_data[7:0];
                'd1: read_data_out <= read_data[15:8];
                'd2: read_data_out <= read_data[23:16];
                'd3: read_data_out <= read_data[31:24];
            endcase
        end

    end

end

inferred_lram inferred_lram (
    .clock_in(read_clock_in), // Use the faster clock
    .reset_n_in(read_reset_n_in),
    .address_in(address),
    .write_data_in(write_data),
    .read_data_out(read_data),
    .write_enable_in(write_enable)
);

always_comb begin

    if (write_enable) begin
        address = write_address;
    end

    else begin
        address = read_address_in[15:2];
    end

end

endmodule