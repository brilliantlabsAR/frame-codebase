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
 
 module display_ram_inferred #(
	ADDR = 12,
	DATA = 10,
	SIM = 0
) (
	input logic clk,
	input logic rst_n,
	input logic [ADDR-1:0] wr_addr,
	input logic [ADDR-1:0] rd_addr,
	input logic [DATA-1:0] wr_data,
	output logic [DATA-1:0] rd_data,
	input logic wr_en,
	input logic rd_en
);

logic [DATA-1:0] mem [(2**ADDR)-1:0];

generate
if (SIM) begin
	initial begin
		integer pixel_counter = 0;
		for (pixel_counter = 0; pixel_counter < (2**ADDR)-1; pixel_counter = pixel_counter+1) begin
			mem[pixel_counter] = 0;
		end	
	end
end
endgenerate

always @(posedge clk) begin
	if (rst_n & wr_en)
		mem[wr_addr] <= wr_data;
end

always @(posedge clk) begin
	if (rst_n & rd_en)
		rd_data <= mem[rd_addr];
end

endmodule