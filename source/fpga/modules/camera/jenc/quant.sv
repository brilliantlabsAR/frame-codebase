// Jpeg Quatizer
`include "zigzag.vh"
module quant #(
    parameter DW = 15,
    // Regular 1-D DCT adds +3 bits to coefficients, but 
    // AAN includes a factor of 3.923 on top of that, so +2 bits       
    parameter QW = DW - 4,
    parameter M_BITS = 13,         // Bit size of Multiplier coefficients
    parameter SENSOR_X_SIZE    = 720,
    parameter SENSOR_Y_SIZE    = 720
)(
    input   logic signed[DW-1:0]    di[7:0], 
    input   logic                   di_valid,
    output  logic                   di_hold,
    input   logic [2:0]             di_cnt,
    output  logic signed[QW-1:0]    q[1:0],
    output  logic                   q_valid,
    input   logic                   q_hold,
    output  logic [4:0]             q_cnt,
    output  logic [1:0]             q_chroma, 
    output  logic                   q_last_mcu,

    input   logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_m1,
    input   logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_m1,

    input   logic                   clk,
    input   logic                   resetn
);

always_comb assert (DW == 15) else $error();
always_comb assert (QW == 11) else $error();
always_comb assert (M_BITS == 13) else $error();


//Write (or Read) into (from) Zig Zag buffer in *REVERSED* (forward) zig zag order
logic [DW-1:0]      zigzag_mem[63:0];
logic               zigzag_sel;         // Zig Zag mem select: 0 .. write DCT-2D output to Zig Zag buffer, 1 .. read Zig Zag buffer & send to quantizer
logic [4:0]         zigzag_rd_cnt;      // read 32 x 2
logic [2:0]         zigzag_mcu_cnt;     // 0..3 Y, 4..U, 5..V
logic signed[DW-1:0] zigzag_rd_data[1:0];

always_comb di_hold = zigzag_sel;

always @(posedge clk) 
if (!resetn) begin
    zigzag_sel <= 0;
    zigzag_rd_cnt <= 0;
    zigzag_mcu_cnt <= 0;
end else if (zigzag_sel & ~q_hold) begin
    zigzag_rd_cnt <= zigzag_rd_cnt + 1;
    if (&zigzag_rd_cnt) begin
        zigzag_sel <= 0;
        zigzag_mcu_cnt <= zigzag_mcu_cnt == 5 ? 0 : zigzag_mcu_cnt + 1;
    end
end else if (~zigzag_sel & di_valid)
    if (&di_cnt)
        zigzag_sel <= 1;


// write to Zig Zag
logic [5:0] zwa;
always @(posedge clk) 
if (~zigzag_sel & di_valid)
    for (int j=0; j<8; j++) begin
        zwa = di_cnt + j*8;
        //$display("WRITE: %d -> %d", wa0 ,en_zigzag(wa0) );
`ifdef READ_ZIG_ZAG_NOT_WRITE
        zigzag_mem[zwa] <= di[j];
`else
        zigzag_mem[en_zigzag(zwa)] <= di[j];
`endif
    end

// read from Zig Zag
logic [5:0] zra;
always_comb
    for (int j=0; j<2; j++) begin
        zra = zigzag_rd_cnt*2 + j;
`ifdef READ_ZIG_ZAG_NOT_WRITE
        zigzag_rd_data[j] = zigzag_mem[de_zigzag(zra)];
`else
        zigzag_rd_data[j] = zigzag_mem[zra];
`endif
    end

// pipline inputs
logic signed[DW-1:0]    di0[1:0];
logic                   di0_valid;
logic [4:0]             di0_cnt;
logic [1:0]             di0_chroma;

always @(posedge clk) 
if (!resetn)
    di0_valid <= 0;
else if (!q_hold)
    di0_valid <= zigzag_sel;

always @(posedge clk) 
if (zigzag_sel & !q_hold) begin
    di0_chroma  <= zigzag_mcu_cnt[2] ? (zigzag_mcu_cnt[0] ? 2 : 1) : 0;
    di0_cnt     <= zigzag_rd_cnt;
    di0         <= zigzag_rd_data;
end

logic [M_BITS-1:0]  q_factor[1:0];
logic [(1+6)-1:0]   q_ra[1:0];
// read the quantizer coefficients 2 at a time
always_comb
    for (int i=0; i<2; i++)
        q_ra[i] = {zigzag_mcu_cnt[2], de_zigzag((zigzag_rd_cnt << 1) | i)};

quant_tables #(.N(2)) quant_tables (
    .re         (zigzag_sel & ~q_hold),
    .ra         (q_ra),
    .rd         (q_factor),
    .*
);

logic signed[DW+M_BITS-1:0]    mult_out[1:0];
always_comb q[0] = mult_out[0] >> (M_BITS-1);
always_comb q[1] = mult_out[1] >> (M_BITS-1);
quant_seq_mult_15x13_p4 mult0 (
    .a_in       (di0[0]),
    .b_in       (q_factor[0]),
    .out        (mult_out[0]),
    .in_valid   (di0_valid & !q_hold),
    .out_valid  (q_valid),
    .en         (~q_hold),
    .*
);
quant_seq_mult_15x13_p4 mult1 (
    .a_in       (di0[1]),
    .b_in       (q_factor[1]),
    .out        (mult_out[1]),
    .in_valid   (di0_valid & !q_hold),
    .out_valid  ( ),
    .en         (~q_hold),
    .*
);


//logic for finding the last block
parameter X_SIZE_D16 = (SENSOR_X_SIZE + 15) >> 4;
parameter Y_SIZE_D16 = (SENSOR_Y_SIZE + 15) >> 4;
logic[$clog2(X_SIZE_D16)-1:0] x_mcu;
logic[$clog2(Y_SIZE_D16)-1:0] y_mcu;

// pipline
logic                   last_mcu;
logic                   di0_last_mcu;

always_comb last_mcu = zigzag_mcu_cnt == 5 & x_mcu == (x_size_m1 >> 4) & y_mcu == (y_size_m1 >> 4);

always @(posedge clk) 
if (!resetn) begin
    x_mcu <= 0;
    y_mcu <= 0;
end else if (zigzag_sel & ~q_hold) begin
    if (&zigzag_rd_cnt & zigzag_mcu_cnt == 5) begin
        if (x_mcu == (x_size_m1 >> 4)) begin
            x_mcu <= 0;
            if (y_mcu == (y_size_m1 >> 4))
                y_mcu <= 0;
            else
                y_mcu <= y_mcu + 1;
        end else
            x_mcu <= x_mcu + 1;
    end
end

always @(posedge clk) 
if (zigzag_sel & !q_hold)
    di0_last_mcu  <= last_mcu;

// Hijack multiplier for pipelining for now :)
logic signed[DW+M_BITS-1:0]    pipe_out;
quant_seq_mult_15x13_p4 cnt_pipe (
    .a_in       ({di0_last_mcu, di0_chroma, di0_cnt}),
    .b_in       (1),
    .out        ({q_last_mcu, q_chroma, q_cnt}),
    .in_valid   (di0_valid & !q_hold),
    .out_valid  ( ),
    .en         (~q_hold),
    .*
);

endmodule
