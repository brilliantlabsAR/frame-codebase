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

logic [13:0] ram_address;
logic [31:0] ram_write_data;
logic [31:0] ram_read_data;
logic ram_write_enable;

// `ifndef RADIANT (* ram_style="huge" *) `endif logic [31:0] mem [0:16383];
PDPSC512K #(
    .OUTREG("NO_REG"),
    .GSR("DISABLED"),
    .RESETMODE("SYNC"),
    .ASYNC_RESET_RELEASE("SYNC"),
    .ECC_BYTE_SEL("BYTE_EN")
) image_mem (
    .DI(ram_write_data),
    .ADW(ram_address),
    .ADR(ram_address),
    .CLK(clock_in),
    .CEW(1'b1),
    .CER(1'b1),
    .WE(ram_write_enable),
    .CSW(1'b1),
    .CSR(1'b1),
    .RSTR(~reset_n_in),
    .BYTEEN_N(4'b000),
    .DO(ram_read_data)
);

always @(posedge clock_in) begin

    if (reset_n_in == 0) begin
        
        read_data_out <= 0;

    end

    else begin

        if (write_enable_in) begin
            ram_write_enable <= 1;
            ram_address <= write_address_in[15:2];

            case (write_address_in[1:0])
                'd0: ram_write_data <= {ram_read_data[31:8],  write_data_in                                   };
                'd1: ram_write_data <= {ram_read_data[31:16], write_data_in, ram_read_data[7:0] };
                'd2: ram_write_data <= {ram_read_data[31:24], write_data_in, ram_read_data[15:0]};
                'd3: ram_write_data <= {                                    write_data_in, ram_read_data[23:0]};
            endcase

        end

        else begin
            ram_write_enable <= 0;
            ram_address <= read_address_in[15:2];

            case (read_address_in[1:0])
                'd0: read_data_out <= ram_read_data[7:0];
                'd1: read_data_out <= ram_read_data[15:8];
                'd2: read_data_out <= ram_read_data[23:16];
                'd3: read_data_out <= ram_read_data[31:24];
            endcase
        end

    end

end

endmodule