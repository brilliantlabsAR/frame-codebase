`include "jlib.vh"
`include "zigzag.vh"
module zigzag  #(
    parameter QW = 15 // 1st pass 13, 2nd pass 15
)(
    input logic[QW-1:0]     d[7:0],
    input logic[2:0]        d_cnt,
    input logic             d_valid,
    output logic            d_hold,

    output logic[QW-1:0]    q[1:0],
    output logic[4:0]       q_cnt,
    output logic            q_valid,
    input logic             q_hold,

    input   logic           clk,
    input   logic           resetn,
    input   logic           clk_x22,
    input   logic           resetn_x22
);


//FIFO logic
logic           empty, full;
logic[1:0]      wptr, rptr;
logic[1:0]      wr_cnt, rd_cnt;

always_comb     full = wptr[1] != rptr[1] & wptr[0] == rptr[0];
always_comb     empty =  wptr == rptr;
always_comb     d_hold = full | ~&wr_cnt;

always @(posedge clk) 
if (!resetn) begin
    wptr <= 0;
    wr_cnt <= 0;
end
else if (d_valid & ~full) begin
    wr_cnt <= wr_cnt + 1;
    if (&wr_cnt  & &d_cnt) 
        wptr <= wptr + 1;
end

logic[2:0]       q_cnt_0;
always @(posedge clk) 
    if (!q_hold & ~empty) 
        q_cnt <= {q_cnt_0, rd_cnt};

always @(posedge clk) 
if (!resetn) begin
    rptr <= 0;
    rd_cnt <= 0;
    q_cnt_0 <= 0;
end
else if (~q_hold & ~empty) begin
    rd_cnt <= rd_cnt + 1;
    if (&rd_cnt)
        q_cnt_0 <= q_cnt_0 + 1;
    if (&rd_cnt & &q_cnt_0)
        rptr <= rptr + 1;
end

// RAM write side
logic               d_valid_nrz, d_valid_nrz_pre_cdc;
logic               nrz0;

logic               wptr_cdc;
logic[15:0]         wd_cdc[1:0];
logic[5:0]          d_addr_cdc[1:0];

always_comb     d_valid_nrz =  d_valid ^ nrz0;
always @(posedge clk) 
if (!resetn)
    nrz0 <= 0;
else if (~full)
    nrz0 <= d_valid ^ nrz0;


always @(negedge clk) 
if (!resetn)
    d_valid_nrz_pre_cdc <= 0;
else if (~full)
    d_valid_nrz_pre_cdc <= d_valid_nrz;
 
logic [5:0] zwa0,  zwa1;
always @(posedge clk) 
if (d_valid & ~full) begin
    wd_cdc <= {d[2*wr_cnt + 1], d[2*wr_cnt]};
    wptr_cdc <= wptr[0];

    zwa0 = {wr_cnt, 1'b0, d_cnt};
    zwa1 = zwa0 | (1<<$bits(d_cnt));
    
    d_addr_cdc[0] = en_zigzag(zwa0);
    d_addr_cdc[1] = en_zigzag(zwa1);
end

//CDC
logic [3:0]         we_cdc;
logic [1:0]         we_x22;

always @(*) we_x22 = {we_cdc[3], ^we_cdc[2:1]};
always @(posedge clk_x22) 
if (!resetn_x22)
    we_cdc <= 0;
else begin
    we_cdc[2:0] <= {we_cdc[1:0], d_valid_nrz_pre_cdc};
    we_cdc[3] <= we_x22[0];
end

// Address write:
logic               wptr_x22;
logic[5:0]          d_addr1_x22;
logic[15:0]         wd1_x22;

always @(posedge clk_x22) 
    if(we_x22[0]) 
        {wptr_x22, d_addr1_x22, wd1_x22} <= {wptr_cdc, d_addr_cdc[1], wd_cdc[1]};

logic[5:0]      wa, ra; 
logic[31:0]     wd, rd; 
logic           wbe_tmp; 
logic[3:0]      wbe; 
logic           we, re; 

always_comb wd      = {2{we_x22[1] ? wd1_x22 : wd_cdc[0]}};
always_comb wa      = we_x22[1] ? {wptr_x22, d_addr1_x22[5:1]} : {wptr_cdc, d_addr_cdc[0][5:1]};
always_comb wbe_tmp = we_x22[1] ? d_addr1_x22[0] : d_addr_cdc[0][0];
always_comb wbe     = {{2{wbe_tmp}}, {2{~wbe_tmp}}};
always_comb we      = |we_x22;

always_comb ra = {rptr, q_cnt_0, rd_cnt};
always_comb re = ~empty;

`ifndef USE_LATTICE_EBR
dp_ram_be  #(
    .DW     (2*16),     // = 32
    .DEPTH  (2*8*8/2)   // = 64 (6 bits)
) mem (
    .wclk   (clk_x22),
    .rclk   (clk),
    .*
);
`else
ram_dp_w32_b4_d64 mem (
    .wr_addr_i  ({q_cnt_0, wa}), 
    .wr_data_i  (wd),
    .ben_i      (wbe),
    .wr_en_i    (we), 
    .wr_clk_en_i(we), 

    .rd_addr_i  ({d_cnt,ra}), 
    .rd_en_i    (re), 
    .rd_clk_en_i(re), 
    .rd_data_o  (rd), 

    .wr_clk_i   (clk_x22), 
    .rd_clk_i   (clk), 
    .rst_i      (1'b0)
);
`endif


logic           re_qq;
logic[15:0]     qq[1:0];
always @(posedge clk) re_qq <= re; 
always @(posedge clk) 
if (re_qq) begin
    qq[0] <= rd[15:0];
    qq[1] <= rd[31:16];
end
always_comb begin
    q[0] = q_hold ? qq[0] : rd[15:0];
    q[1] = q_hold ? qq[0] : rd[31:16];
end

// flop output valid
always @(posedge clk)
if (!resetn) 
    q_valid <= 0;
else if (!q_hold)
    q_valid <= ~empty;
endmodule
