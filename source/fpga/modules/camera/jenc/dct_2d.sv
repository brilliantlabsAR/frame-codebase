/*
Take 8-bit input samples (0..255)
Subtract 128 (-128..127)
Do N*N fDCT, where N=8
Output can have log2(N)+8 bits = 11 bits (-1024..1023)
DC coefficients are stored as a difference, so they can have 12 bits// Implementation of 2-D DCT, sharing one 1-D DCT
*/
module dct_2d #(
    parameter DW = 8,
    // Regular 1-D DCT adds +3 bits (8 -> 11) to coefficients, but 
    // AAN includes a factor of 3.923 on top of that, so +2 bits for 1-D (8+3+2=13) or +4 bits for 2-D (8+3+4=15)      
    parameter CW = DW + 5,
    parameter C2W = CW + 5,     // Coeffs after 2nd pass full size
    parameter QW = DW + 7       // Coeffs after 2nd are normlized to 15 bits (11 + 4)
)(
    input   logic signed[DW-1:0]    di[7:0], 
    input   logic                   di_valid,
    output  logic                   di_hold,
    input   logic [2:0]             di_cnt,
    output  logic signed[QW-1:0]    q[7:0],
    output  logic                   q_valid,
    input   logic                   q_hold,
    output  logic [2:0]             q_cnt,
    input   logic                   clk,
    input   logic                   resetn
);


//------------------------------------------------------------------------------
// input muxes to dct
// MCU 8-line buffer/Transpose mem
//------------------------------------------------------------------------------
logic signed[CW-1:0] dct_di[7:0]; 
logic [2:0] dct_di_cnt;
logic dct_di_valid;
logic dct_di_hold;

logic signed[CW-1:0] transpose_rd_data[7:0];
logic [2:0] transpose_rd_cnt;
logic transpose_rd_hold;
logic transpose_rd_valid;

logic dct_src_sel;    // Source to DCT: 0 .. MCU 8-line buffer, 1 .. Transpose mem

always_comb di_hold = dct_src_sel ? 1 : dct_di_hold;
always_comb transpose_rd_hold = dct_src_sel ? dct_di_hold : 1;
always_comb dct_di_valid = dct_src_sel ? transpose_rd_valid : di_valid;

always_comb dct_di_cnt = dct_src_sel ? transpose_rd_cnt : di_cnt;
always_comb 
    for (int j=0; j<8; j++)
            dct_di[j] = dct_src_sel ? transpose_rd_data[j] : di[j];

always @(posedge clk) 
if (!resetn)
    dct_src_sel <= 0;
else if (dct_di_valid & !dct_di_hold & &dct_di_cnt)
    dct_src_sel <= ~dct_src_sel;

//------------------------------------------------------------------------------
// DCT
//------------------------------------------------------------------------------
logic [C2W-1:0] dct_q[7:0]; 
logic [2:0] dct_q_cnt;
logic dct_q_valid;
logic dct_q_hold;

dct_1d_aan #(
    .DW     (CW),
    .CW     (C2W)
) dct_1d (
    .di             (dct_di),
    .di_valid       (dct_di_valid),
    .di_hold        (dct_di_hold),
    .di_cnt         (dct_di_cnt),
    .q              (dct_q),
    .q_valid        (dct_q_valid),
    .q_hold         (dct_q_hold),
    .q_cnt          (dct_q_cnt),
    .*
);

//------------------------------------------------------------------------------
// Destination of DCT
// Zig zag mem OR Transpose mem
//------------------------------------------------------------------------------
logic dct_dest_sel;     // Destination of DCT output: 0 .. Zig zag mem, 1 .. Transpose mem
logic transpose_sel;    // Transpose operation select: 0 .. write DCT output to transpose, 1 .. read transpose and write back to DCT
logic transpose_wr_valid;

// Destination: Zig-Zag (or Transpose)
always_comb dct_q_hold = dct_dest_sel ? transpose_sel : q_hold;
always_comb q_valid = dct_dest_sel ? 0 : dct_q_valid;
always_comb transpose_wr_valid = dct_dest_sel ? dct_q_valid : 0;
always_comb transpose_rd_valid = transpose_sel;

always @(posedge clk) 
if (!resetn)
    dct_dest_sel <= 1;
else if (dct_q_valid & !dct_q_hold & &dct_q_cnt)
    dct_dest_sel <= ~dct_dest_sel;


// Reduce the range of the signal. Should be 8+2 = 12 (AAN!)

always_comb q_cnt = dct_q_cnt;
always_comb
    for (int j=0; j<8; j++)
        q[j] = dct_q[j];


//------------------------------------------------------------------------------
// Transpose buffer
//------------------------------------------------------------------------------
logic [C2W-1:0] transp_mem[7:0][7:0];

always @(posedge clk) 
if (!resetn) begin
    transpose_sel <= 0;
    transpose_rd_cnt <= 0;
end else if (transpose_sel & ~transpose_rd_hold) begin
    transpose_rd_cnt <= transpose_rd_cnt + 1;
    if (&transpose_rd_cnt)
        transpose_sel <= 0;
end else if (~transpose_sel & transpose_wr_valid)
    if (&dct_q_cnt)
        transpose_sel <= 1;

// write to transpose
always @(posedge clk) 
if (~transpose_sel & transpose_wr_valid)
    for (int j=0; j<8; j++)
        transp_mem[dct_q_cnt][j] <= dct_q[j];

// read from transpose
always_comb
    for (int j=0; j<8; j++)
        transpose_rd_data[j] = transp_mem[j][transpose_rd_cnt];

endmodule
