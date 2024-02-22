module bitpacker (
    //packed code+coeff
    input   logic [5:0]             in_codecoeff_length,
    input   logic [51:0]            in_codecoeff,
    input   logic                   in_tlast,
    input   logic                   in_valid,
    output  logic                   in_hold,


    output  logic [63:0]            out_data,
    output  logic [3:0]             out_bytes,
    output  logic                   out_valid,
    input   logic                   out_hold,

    input   logic                   clk,
    input   logic                   resetn
);

// incoming: 52 bits max = 6.5 bytes -> 8 bytes
logic [5:0]             bit_count;
logic [6:0]             next_bit_count;
logic [63:0]            bit_packer;
logic [127:0]           next_bit_packer;
logic [2:0]             tbytes;

always_comb in_hold = out_hold;

always_comb next_bit_count  = bit_count + in_codecoeff_length;
always_comb next_bit_packer = (bit_packer << 64) | (in_codecoeff << ((128-52) - bit_count));

always @(posedge clk)
if (!resetn)
    bit_count <= 0;
else if (in_valid & ~in_hold)
    if (in_tlast)
        bit_count <= 0;
    else
        bit_count <= next_bit_count;
        
always @(posedge clk)
if (!resetn)
    bit_packer <= 0;
else if (in_valid & ~in_hold)
    if (in_tlast)
        bit_packer <= 0;
    else if (next_bit_count >= 64)
        bit_packer <= next_bit_packer;
    else
        bit_packer <= next_bit_packer >> 64;
        
always @(posedge clk)
if (!resetn)
    out_valid <= 0;
else if (~in_hold)
    out_valid <= in_valid & (next_bit_count >= 64 | in_tlast);

always @(posedge clk)
if (in_valid & ~in_hold) begin
    if (in_tlast) begin
        out_data <= (next_bit_packer >> 64) | ({64{1'b1}} >> next_bit_count);
        tbytes <= (next_bit_count + 7) >> 3; // Adjust for EOS
    end else if (next_bit_count >= 64) begin
        out_data <= (next_bit_packer >> 64);
        tbytes <= 8;
    end
end

always_comb out_bytes[2:0] = tbytes;
always_comb out_bytes[3] = tbytes==0;
endmodule
