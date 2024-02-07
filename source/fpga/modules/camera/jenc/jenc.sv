module jenc #(
    parameter DW = 8,
    parameter QW = 11,
    parameter CW = QW + 4
)(
    input   logic signed[DW-1:0]    di[7:0], 
    input   logic                   di_valid,
    output  logic                   di_hold,
    input   logic [2:0]             di_cnt,

    output  logic signed[QW-1:0]    q[1:0],
    output  logic                   q_valid,
    input   logic                   q_hold,
    output  logic [4:0]             q_cnt,

    input   logic                   clk,
    input   logic                   resetn
);

logic signed[CW-1:0]    d[7:0];
logic                   d_valid;
logic                   d_hold;
logic [2:0]             d_cnt;


dct_2d dct_2d (
    .q              (d),
    .q_valid        (d_valid),
    .q_hold         (d_hold),
    .q_cnt          (d_cnt),
    .*);
quant quant(
    .di             (d),
    .di_valid       (d_valid),
    .di_hold        (d_hold),
    .di_cnt         (d_cnt),
    .*
);

endmodule
