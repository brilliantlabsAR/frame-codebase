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
    input logic clock_in,
    input logic reset_n_in,

    input logic [15:0] write_address_in,
    input logic [15:0] read_address_in,

    input logic [7:0] write_data_in,
    output logic [7:0] read_data_out,

    input logic write_enable_in
);

`ifndef RADIANT (* ram_style="huge" *) `endif logic [31:0] mem [0:16383];

always @(posedge clock_in) begin

    if (reset_n_in == 0) begin
        read_data_out <= 0;
    end

    else begin
        if (write_enable_in) begin
            case (write_address_in[1:0])
                'd0: mem[write_address_in[15:2]] <= {mem[write_address_in[15:2]][31:8],  write_data_in                                   };
                'd1: mem[write_address_in[15:2]] <= {mem[write_address_in[15:2]][31:16], write_data_in, mem[write_address_in[15:2]][7:0] };
                'd2: mem[write_address_in[15:2]] <= {mem[write_address_in[15:2]][31:24], write_data_in, mem[write_address_in[15:2]][15:0]};
                'd3: mem[write_address_in[15:2]] <= {                                    write_data_in, mem[write_address_in[15:2]][23:0]};
            endcase
        end

        case (read_address_in[1:0])
            'd0: read_data_out <= mem[read_address_in[15:2]][7:0];
            'd1: read_data_out <= mem[read_address_in[15:2]][15:8];
            'd2: read_data_out <= mem[read_address_in[15:2]][23:16];
            'd3: read_data_out <= mem[read_address_in[15:2]][31:24];
        endcase
    end
end

endmodule