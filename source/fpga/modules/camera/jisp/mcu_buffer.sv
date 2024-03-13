
/*
 * MCU buffer for 4:2:0 (4:4:4, 4:2:2, 4:0:0 can be added easily)
 *
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
 module mcu_buffer #(
    parameter SENSOR_X_SIZE = 'd1280,
    parameter SENSOR_Y_SIZE = 'd720,
    parameter DW            = 8,
    parameter JPEG_BIAS     = 8'd128
)(
    input   logic [DW-1:0]      yuvrgb_in[2:0], // to do: make pktized interface
    input   logic [2:0]         yuvrgb_in_valid, // per component
    output  logic               yuvrgb_in_hold,
    input   logic               eof_in,
    input   logic[$clog2(SENSOR_X_SIZE)-1:0]    yuvrgb_in_pixel_count,
    input   logic[$clog2(SENSOR_Y_SIZE)-1:0]    yuvrgb_in_line_count,

    output  logic signed[DW-1:0] di[7:0], 
    output  logic               di_valid,
    input   logic               di_hold,
    output  logic [2:0]         di_cnt,

    input   logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_m1,
    input   logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_m1,
    input   logic               clk,
    input   logic               resetn
);

//always_comb assert (&x_size_m1[2:0]) else $fatal("Enforcing even image dimensions");
//always_comb assert (&y_size_m1[2:0]) else $fatal("Enforcing even image dimensions");

localparam Y_LINE_BUF_SIZE = SENSOR_X_SIZE;
localparam UV_LINE_BUF_SIZE = SENSOR_X_SIZE/2;
localparam Y_LINE_BUF_HEIGHT = 16;
localparam UV_LINE_BUF_HEIGHT = 8;

// FIFO logic
logic[1:0] wptr, rptr;
logic full, empty;
always_comb empty = wptr==rptr;
always_comb full = wptr[1]!=rptr[1] & wptr[0]==rptr[0];

always @(posedge clk)
if (!resetn)
    wptr <= 0;
else if (!full & yuvrgb_in_valid[0] & (yuvrgb_in_line_count[3:0]==15 | yuvrgb_in_line_count==y_size_m1) & yuvrgb_in_pixel_count==x_size_m1)
    wptr <= wptr + 1;
    
/* Order of reading 8x8 MCUs
420:    Y:  0 1     U:  4       V:  5
            2 3  

422:    Y:  0 1     U:  2       V:  3

444:    Y:  0       U:  1       V:  2

400:    Y:  0       U:  -       V:  -
*/
logic[$clog2(Y_LINE_BUF_SIZE/16)-1:0]    block_count; // 6 bits for 4:2:0, 4:2:2 (7 bits for 4:4:4, 4:0:0)
logic[$clog2(Y_LINE_BUF_SIZE/16)-1:0]    block_v_count; // 6 bits for 4:2:0 (7 bits for 4:2:2, 4:4:4, 4:0:0)
logic[$clog2(6)-1:0]        mcu_count, mcu_count_0;
logic[2:0]                  mcu_line_count; // 8 bytes at a time
logic[(8*DW)-1:0]           rd_y, rd_uv;

always_comb yuvrgb_in_hold = full;

always @(posedge clk)
if (!resetn)
    rptr <= 0;
else if (!di_hold & !empty & mcu_line_count == 7 & mcu_count == 5 & block_count == (x_size_m1 >> 4))
    rptr <= rptr + 1;

always @(posedge clk)
if (!resetn) begin
    mcu_count <= 0;
    mcu_line_count <= 0;
    block_count <= 0;
    block_v_count <= 0;

end
else if (!di_hold & !empty) begin
    mcu_line_count <= mcu_line_count + 1;           // 1. count 8 lines within MCU
    if (mcu_line_count == 7)
        if (mcu_count == 5) begin
            mcu_count <= 0;
            if (block_count == (x_size_m1 >> 4)) begin
                block_count <= 0;
                if (block_v_count == (y_size_m1 >> 4))
                    block_v_count <= 0;
                else 
                    block_v_count <= block_v_count + 1; // 4. vertical block 2x2 luma, 1x1 chroma
            end
            else
                block_count <= block_count + 1;     // 3. horizontal block 2x2 luma, 1x1 chroma
        end 
        else
            mcu_count <= mcu_count + 1;             // 2. count 6 MCUs
end

// keep track of exact x/y read positions of pixels (for 4:2:0 only for now)
// here juat for the read side
/*
logic[$clog2(SENSOR_X_SIZE)-1:0] r_x_luma;
logic[$clog2(SENSOR_Y_SIZE)-1:0] r_y_luma;
logic[$clog2(SENSOR_X_SIZE)-1:0] r_x_chroma;
logic[$clog2(SENSOR_Y_SIZE)-1:0] r_y_chroma;

always_comb r_x_luma  =  {block_count, mcu_count[0], 3'b000};
always_comb r_x_chroma  =  {block_count, 3'b000};

always_comb r_y_luma  =  {block_v_count, mcu_count[1], mcu_line_count};
always_comb r_y_chroma  =  {block_v_count, mcu_line_count};
*/

// Y buffer
//
// Write Address: 
// 2x720x16 bytes = 23040 bytes -> 14.49 -> 15 bits
// 8 pixel write with BE -3 bits -> 12 bits address width
//  1 bit double buffer select
//  4 bits line count
//  7 bits pixel count in increments of 8 pixels
//
// Read Address: 
// 2x720x16 bytes = 23040 bytes -> 14.49 -> 15 bits
// 8 pixel readout -3 bits -> 12 bits address width
//  1 bit double buffer select
//  4 bits line select
//  1 bit 2 8x8 MCU per block horizontally
//  6 bits block count

/*
logic [2*Y_LINE_BUF_SIZE*Y_LINE_BUF_HEIGHT/64 - 1:0] ra_luma; //9bits
logic [2*UV_LINE_BUF_SIZE*UV_LINE_BUF_HEIGHT/64 - 1:0] ra_chroma; //7bits
//#always_comb
//#{{block_count, mcu_count[0]}, {mcu_count[1], mcu_line_count}, rptr[0]}
//end
*/

`ifndef USE_LATTICE_EBR
dp_ram_be  #(
    .DW     (DW*8),
    .DEPTH  (2*Y_LINE_BUF_SIZE*Y_LINE_BUF_HEIGHT/8)
) y_buf (
    .wa     ({(yuvrgb_in_pixel_count >> 3), yuvrgb_in_line_count[3:0], wptr[0]}),
    .wd     ({8{yuvrgb_in[0] - JPEG_BIAS}}),            // <== JPEG bias!
    .wbe    ((yuvrgb_in_pixel_count==x_size_m1 ? '1 : 1) << (yuvrgb_in_pixel_count & 7)),
    .we     (yuvrgb_in_valid[0] & !yuvrgb_in_hold),
    .ra     ({{block_count, mcu_count[0]}, {mcu_count[1], mcu_line_count}, rptr[0]}),
    .re     (!di_hold & !empty & mcu_count <= 3),
    .rd     (rd_y),
    .rclk   (clk),
    .wclk   (clk)
);
`else
ram_dp_w64_b8_d2880 y_buf (
    .wr_addr_i  ({(yuvrgb_in_pixel_count >> 3), yuvrgb_in_line_count[3:0], wptr[0]}), 
    .wr_data_i  ({8{yuvrgb_in[0] - JPEG_BIAS}}),            // <== JPEG bias!
    .ben_i      ((yuvrgb_in_pixel_count==x_size_m1 ? '1 : 1) << (yuvrgb_in_pixel_count & 7)),
    .wr_en_i    (yuvrgb_in_valid[0] & !yuvrgb_in_hold), 
    .wr_clk_en_i(yuvrgb_in_valid[0] & !yuvrgb_in_hold), 

    .rd_addr_i  ({{block_count, mcu_count[0]}, {mcu_count[1], mcu_line_count}, rptr[0]}), 
    .rd_en_i    (!di_hold & !empty & mcu_count <= 3), 
    .rd_clk_en_i(!di_hold & !empty & mcu_count <= 3), 
    .rd_data_o  (rd_y), 
    .wr_clk_i   (clk), 
    .rd_clk_i   (clk), 
    .rst_i      (1'b0)
);
`endif

//U+V buffer
// Address: 2x320x8 bytes = 5120 bytes -> 12.32 -> 13 bits
// 8 pixel readout -3 bits -> 10 bits address width
// 1 bit double buffer select
// 3 bits line select
// 6 bits block count

logic [$clog2(2*2*UV_LINE_BUF_SIZE*UV_LINE_BUF_HEIGHT/8)-1:0] uv_buf_wa;
logic [7:0]         uv_buf_wbe;
logic [DW-1:0]      uv_buf_wd;
logic               uv_buf_we;

// shared UV memory layout
// LSB=00 buffer #0, U
// LSB=01 buffer #0, V
// LSB=10 buffer #1, U
// LSB=11 buffer #1, V

always_comb uv_buf_wa = {(yuvrgb_in_pixel_count >> 4), yuvrgb_in_line_count[3:1], wptr[0], yuvrgb_in_valid[2]}; // LSB selects U/V
always_comb uv_buf_wd = (yuvrgb_in_valid[2] ? yuvrgb_in[2] : yuvrgb_in[1]) - JPEG_BIAS; // <== JPEG bias!
always_comb uv_buf_wbe = (yuvrgb_in_pixel_count==x_size_m1 ? '1 : 1) << ((yuvrgb_in_pixel_count >> 1) & 7);
always_comb uv_buf_we = |yuvrgb_in_valid[2:1] & ~yuvrgb_in_hold;

`ifndef USE_LATTICE_EBR
dp_ram_be  #(
    .DW     (DW*8),
    .DEPTH  (2*2*UV_LINE_BUF_SIZE*UV_LINE_BUF_HEIGHT/8)
) uv_buf (
    .wa     (uv_buf_wa),
    .wd     ({8{uv_buf_wd}}),
    .wbe    (uv_buf_wbe),
    .we     (uv_buf_we),
    .ra     ({block_count, mcu_line_count, rptr[0], mcu_count[0]}),
    .re     (!di_hold & !empty & mcu_count > 3 ),
    .rd     (rd_uv),
    .rclk   (clk),
    .wclk   (clk)
);
`else
ram_dp_w64_b8_d1440 uv_buf (
    .wr_addr_i  (uv_buf_wa),
    .wr_data_i  ({8{uv_buf_wd}}),
    .ben_i      (uv_buf_wbe),
    .wr_en_i    (uv_buf_we),
    .wr_clk_en_i(uv_buf_we),

    .rd_addr_i  ({block_count, mcu_line_count, rptr[0], mcu_count[0]}), 
    .rd_en_i    (!di_hold & !empty & mcu_count > 3), 
    .rd_clk_en_i(!di_hold & !empty & mcu_count > 3), 
    .rd_data_o  (rd_uv), 
    .wr_clk_i   (clk), 
    .rd_clk_i   (clk), 
    .rst_i      (1'b0)
);
`endif

// data out reg & mux
always @(posedge clk)
if (!di_hold & !empty)
    mcu_count_0 <= mcu_count;

always_comb 
    for (int i=0; i<8; i++)
        di[i] = mcu_count_0 < 4 ? rd_y[i*8 +: 8] : rd_uv[i*8 +: 8];

/*
always_comb begin
    for (int i=0; i<8; i++)
        // unaligned image size: replicate
        if (rsel==0 & (r_x_luma >> 3) == (x_size_m1 >> 3) & i > x_size_m1[2:0])
            di[i] = rd[rsel][x_size_m1[2:0]];
        //if ((rsel==0 ? (r_x_luma >> 3) == (x_size_m1 >> 3) : (r_x_chroma >> 3) == (x_size_m1 >> 4)) & i > x_size_m1[2:0])
        //if ((rsel==0 ? (r_x_luma >> 3) == (x_size_m1 >> 3) : (r_x_chroma >> 3) == (x_size_m1 >> 4)) & i > x_size_m1[2:0])
        else if (rsel>0 & (r_x_chroma >> 3) == (x_size_m1 >> 4) & i > x_size_m1[3:1])
            di[i] = rd[rsel][x_size_m1[3:1]];
        else
            di[i] = rd[rsel][i*8 +: 8];
end
*/

always @(posedge clk)
if (!resetn) 
    di_valid <= 0;
else if (!di_hold)
    di_valid <= !empty;

always @(posedge clk)
if (!di_hold & !empty)
    di_cnt <= mcu_line_count;

endmodule
