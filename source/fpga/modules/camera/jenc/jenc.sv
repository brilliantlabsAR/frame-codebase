module jenc #(
    parameter DW = 8,
    parameter QW = 11,
    parameter CW = QW + 4,
    parameter SENSOR_X_SIZE    = 720,
    parameter SENSOR_Y_SIZE    = 720
)(
    input   logic signed[DW-1:0]    di[7:0], 
    input   logic                   di_valid,
    output  logic                   di_hold,
    input   logic [2:0]             di_cnt,

    output  logic [5:0]             out_codecoeff_length,
    output  logic [51:0]            out_codecoeff,
    output  logic                   out_valid,
    input   logic                   out_hold,

    input   logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_m1,
    input   logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_m1,

    input   logic                   clk,
    input   logic                   resetn
);

logic signed[CW-1:0]    d[7:0];
logic                   d_valid;
logic                   d_hold;
logic [2:0]             d_cnt;

logic signed[10:0]      q[1:0]; 
logic                   q_valid;
logic                   q_hold;
logic [4:0]             q_cnt;
logic [1:0]             q_chroma;
logic                   q_last_mcu;

dct_2d dct_2d (
    .q              (d),
    .q_valid        (d_valid),
    .q_hold         (d_hold),
    .q_cnt          (d_cnt),
    .*
);
quant quant(
    .di             (d),
    .di_valid       (d_valid),
    .di_hold        (d_hold),
    .di_cnt         (d_cnt),
    .*
);
entropy entropy(
    .*
);

endmodule
