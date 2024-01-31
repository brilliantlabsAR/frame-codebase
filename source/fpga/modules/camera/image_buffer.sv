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

    input logic [15:0] write_address,
    input logic [15:0] read_address,

    input logic [7:0] write_data,
    output logic [7:0] read_data,

    input logic write_enable
);

`ifndef RADIANT (* ram_style="huge" *) `endif logic [31:0] mem [0:16384];

always @(posedge clock) begin

    if (reset_n == 0) begin
        read_data <= 0;
    end

    else begin
        if (write_enable) begin
            case (write_address[1:0])
                'd0: mem[write_address[15:2]] <= {mem[write_address[15:2]][31:8],  write_data                                };
                'd1: mem[write_address[15:2]] <= {mem[write_address[15:2]][31:16], write_data, mem[write_address[15:2]][7:0] };
                'd2: mem[write_address[15:2]] <= {mem[write_address[15:2]][31:24], write_data, mem[write_address[15:2]][15:0]};
                'd3: mem[write_address[15:2]] <= {                                 write_data, mem[write_address[15:2]][23:0]};
            endcase
        end

        case (read_address[1:0])
            'd0: read_data <= mem[read_address[15:2]][7:0];
            'd1: read_data <= mem[read_address[15:2]][15:8];
            'd2: read_data <= mem[read_address[15:2]][23:16];
            'd3: read_data <= mem[read_address[15:2]][31:24];
        endcase
    end
end

endmodule