
module camera_ram_inferred (
	input logic clk,
	input logic rst_n,
	input logic [15:0] wr_addr,
	input logic [15:0] rd_addr,
	input logic [31:0] wr_data,
	output logic [31:0] rd_data,
	input logic wr_en,
	input logic rd_en
);

reg [31:0] mem [0:15999];

always @(posedge clk) begin
	if (rst_n & wr_en) begin
		mem[wr_addr] <= wr_data;
	end
end

always @(posedge clk) begin
	if (rst_n & rd_en)
		rd_data <= mem[rd_addr];
end

endmodule