module transpose  #(
    parameter QW = 13 // 1st pass 13, 2nd pass 15
)(
    input logic signed[QW-1:0] d[7:0],
    input logic[2:0]        d_cnt,
    input logic             d_valid,
    output logic            d_hold,

    output logic signed[QW-1:0] q[7:0],
    output logic[2:0]       q_cnt,
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
    if (!q_hold & ~empty & &rd_cnt) 
        q_cnt <= q_cnt_0;

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
logic[5:0]      wa, ra; 
logic[31:0]     wd, rd; 
logic[3:0]      wbe; 
logic           we, re; 

// Async FIFO
logic           e; // =empty
logic           wsel;
logic           wptr_x22;
logic signed[QW-1:0] wd1_x22, wd0_x22;
logic[1:0]      wr_cnt_x22;
logic[2:0]      d_cnt_x22;

afifo #(.DSIZE($bits(wptr[0]) + $bits(wr_cnt) + $bits(d_cnt) + 2*$bits(d[0])), .ASIZE(3)) afifo(
    .i_wclk(clk),
    .i_wrst_n(resetn), 
    .i_wr(d_valid & ~full),
    .i_wdata({wptr[0], wr_cnt, d_cnt, d[2*wr_cnt + 1], d[2*wr_cnt]}),
    .o_wfull(),
    .i_rclk(clk_x22),
    .i_rrst_n(resetn_x22),
    .i_rd(wsel),
    .o_rdata({wptr_x22, wr_cnt_x22, d_cnt_x22, wd1_x22, wd0_x22}),
    .o_rempty(e)
);

always @(posedge clk_x22) 
if (!resetn_x22)
    wsel <= 0;
else if (we)
    wsel <= ~wsel;

always_comb wd[15:0] = wsel ? wd1_x22 : wd0_x22;
always_comb wd[31:16] = wd[15:0];
always_comb wa      = {wptr_x22, wr_cnt_x22, wsel, d_cnt_x22} >> 1;
always_comb wbe     = {{2{d_cnt_x22[0]}}, {2{~d_cnt_x22[0]}}};
always_comb we      = ~e;

always_comb ra = {rptr, q_cnt_0, rd_cnt};
always_comb re = ~empty & ~q_hold;

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
    .wr_addr_i  (wa), 
    .wr_data_i  (wd),
    .ben_i      (wbe),
    .wr_en_i    (we), 
    .wr_clk_en_i(we), 

    .rd_addr_i  (ra), 
    .rd_en_i    (re), 
    .rd_clk_en_i(re), 
    .rd_data_o  (rd), 

    .wr_clk_i   (clk_x22), 
    .rd_clk_i   (clk), 
    .rst_i      (1'b0)
);
`endif


logic           re_qq;
logic[1:0]      rd_cnt_qq;
logic[15:0]     qq[5:0];
always @(posedge clk) re_qq <= re; 
always @(posedge clk) if(re & !q_hold) rd_cnt_qq <= rd_cnt; 
always @(posedge clk) 
if (re_qq & !q_hold) begin
    qq[2*rd_cnt_qq  ] <= rd[15:0];
    qq[2*rd_cnt_qq+1] <= rd[31:16];
end
always_comb begin
    for (int i=0;i<6;i++) q[i] = qq[i];
    q[6] = rd[15:0];
    q[7] = rd[31:16];
end

// flop output valid
always @(posedge clk)
if (!resetn) 
    q_valid <= 0;
else if (!q_hold)
    q_valid <= re & &rd_cnt;
endmodule
