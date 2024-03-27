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

`timescale 10ns / 10ns

`include "../image_buffer.sv"

module image_buffer_tb;

logic spi_clock = 0;
logic pixel_clock = 0;

logic spi_reset_n = 0;
logic pixel_reset_n = 0;

logic [15:0] write_address = 16'hFFFF;
logic [16:0] read_address = 0;
logic [7:0] write_data = 8'h00;
logic [7:0] read_data;
logic write_enable = 1;

initial begin
    forever #1 spi_clock <= ~spi_clock;
end

initial begin
    forever #2 pixel_clock <= ~pixel_clock;
end

initial begin
    #10
    spi_reset_n <= 1;
    pixel_reset_n <= 1;
    #200
    write_enable <= 0;
    read_address <= 0;
    #200
    spi_reset_n <= 0;
    pixel_reset_n <= 0;
    #10
    $finish;
end

always_ff @(posedge pixel_clock) begin

    if (pixel_reset_n == 0) begin
        write_address <= 16'hFFFF;
        write_data <= 8'h00;
    end

    else begin
        if (write_enable) begin
            write_address <= write_address + 1;
            write_data <= write_data - 1;
        end
        else begin
            write_address <= 0;
            write_data <= 0;
        end
    end

end

always_ff @(posedge spi_clock) begin

    if (spi_reset_n == 0) begin
        read_address <= 0;
    end

    else begin
        if (write_enable) begin
            read_address <= 0;
        end
        else begin
            read_address <= read_address + 1;
        end
    end

end

image_buffer image_buffer (
    .write_clock_in(pixel_clock),
    .read_clock_in(spi_clock),
    .write_reset_n_in(pixel_reset_n),
    .read_reset_n_in(spi_reset_n),
    .write_address_in(write_address),
    .read_address_in(read_address[16:1]),
    .write_data_in(write_data),
    .read_data_out(read_data),
    .write_read_n_in(write_enable)
);

integer i;
initial begin
    $dumpfile("simulation/image_buffer_tb.fst");
    $dumpvars(0, image_buffer_tb);

    for (i = 0; i < 8; i = i + 1)
        $dumpvars(1, image_buffer.inferred_lram.mem[i]);
end

endmodule