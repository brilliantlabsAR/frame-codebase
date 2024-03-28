module bytepacker (
    //packed code+coeff
    input   logic [63:0]            in_data,
    input   logic [3:0]             in_bytes,
    input   logic                   in_tlast,
    input   logic                   in_valid,
    output  logic                   in_hold,

    output  logic [127:0]           out_data,
    output  logic [4:0]             out_bytes,
    output  logic                   out_tlast,
    output  logic                   out_valid,
    input   logic                   out_hold,
    output  logic [19:0]            size,

    input   logic                   clk,
    input   logic                   resetn
);

always_comb in_hold = out_hold;

// Stuff 0xFF -> 0xFF00
logic [127:0]       in_data_s[7:0];
logic [4:0]         in_bytes_s[7:0];

generate
for (genvar i=0; i<8; i++) begin : ff_stuff
    if (i==0) 
        always_comb begin
            in_data_s[0] = in_data << 64;
            if (&in_data[7:0] & in_bytes>=8)
                in_bytes_s[0] = in_bytes + 1;
            else
                in_bytes_s[0] = in_bytes;
        end
    else 
        always_comb begin
            if (&in_data_s[i-1][(71 + i*8)  : (64 + i*8)] & in_bytes>=(8-i)) begin
                in_bytes_s[i] = in_bytes_s[i-1] + 1;
                in_data_s[i][127      : (64 + i*8)] = in_data_s[i-1][127      : 64 + i*8];
                in_data_s[i][63 + i*8 : 56 + i*8] = 0;
                in_data_s[i][55 + i*8 :        0] = in_data_s[i-1][63 + i*8 :        8];
            end else begin    
                in_bytes_s[i] = in_bytes_s[i-1];
                in_data_s[i] = in_data_s[i-1];
            end
        end
end
endgenerate

logic [127:0]           s_data;
logic [4:0]             s_bytes;
logic                   s_tlast;
logic                   s_valid;
always @(posedge clk)
if (!resetn)
    s_valid <= 0;
else if (~in_hold)
    s_valid <= in_valid; 

always @(posedge clk)
if (in_valid & ~in_hold) begin
    s_data <= ~(in_data_s[7] | ('1 >> (8*in_bytes_s[7]))); 
    s_bytes <= in_bytes_s[7]; 
    s_tlast <= in_tlast; 
end

// See bitpacker
logic [3:0]             byte_count;
logic [4:0]             next_byte_count;
logic [127:0]           byte_packer;
logic [127:0]           next_byte_packer;
logic [127:0]           next_byte_packer_lsb128;
logic [3:0]             tbytes;

always_comb next_byte_count  = byte_count + s_bytes;
always_comb {next_byte_packer, next_byte_packer_lsb128} = (byte_packer << 128) | (s_data << (128 - 8*byte_count));

logic [1:0] s_tlast_extend; // corner case tlast & count > 16
logic       true_s_tlast;

always @(*) true_s_tlast = (s_valid & s_tlast & next_byte_count <= 16) | s_tlast_extend == 3;

always @(posedge clk)
if (!resetn) begin
    s_tlast_extend <= 0;
end
else if ((s_valid | s_tlast_extend!=0) & ~in_hold) begin
    if ((s_tlast & next_byte_count > 16) | s_tlast_extend!=0)
        s_tlast_extend <= s_tlast_extend + 1;
end

always @(posedge clk)
if (!resetn) begin
    byte_count <= 0;
    byte_packer <= 0;
end
else if ((s_valid | s_tlast_extend==3) & ~in_hold) begin
    if (true_s_tlast)
        byte_count <= 0;
    else
        byte_count <= next_byte_count;

    if (true_s_tlast)
        byte_packer <= 0;
    else if (next_byte_count >= 16)
        byte_packer <= next_byte_packer_lsb128;
    else
        byte_packer <= next_byte_packer;
end
        
always @(posedge clk)
if (!resetn)
    out_valid <= 0;
else if (~in_hold)
    out_valid <= s_tlast_extend==3 | (s_valid & (next_byte_count >= 16 | s_tlast));

always @(posedge clk)
if (~in_hold & (s_tlast_extend==3 | (s_valid & (next_byte_count >= 16 | s_tlast)))) begin
    out_tlast <= true_s_tlast;
    out_data <= ~next_byte_packer;
    if (s_valid & s_tlast & next_byte_count <= 16)
        tbytes <= next_byte_count;
    else if (s_tlast_extend == 3)
        tbytes <= byte_count;
    else
        tbytes <= 16;
end

always_comb out_bytes[3:0] = tbytes;
always_comb out_bytes[4] = tbytes==0;

// Size reg
always @(posedge clk)
if (!resetn)
    size <= 0;
else if (out_valid & ~out_hold & ~out_tlast)
    size <= size + out_bytes;

endmodule
