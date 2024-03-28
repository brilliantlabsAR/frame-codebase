/*
 * Top level for Jenc related ISP (mainly for simulation purposes)
 *
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
 module jenc_top #(
    parameter DW = 8,
    parameter SENSOR_X_SIZE    = 1280,
    parameter SENSOR_Y_SIZE    = 720
)(
    input   logic               start_capture_in,

    input   logic [9:0]         red_data_in,
    input   logic [9:0]         green_data_in,
    input   logic [9:0]         blue_data_in,    
    input   logic               frame_valid_in,
    input   logic               line_valid_in,

    output  logic [127:0]       data_out,           // 16 bytes of data
    output  logic [15:0]        address_out,        // Adress of 16-byte data in image buffer (in bytes)
    output  logic [4:0]         bytes_out,          // Number of valid data bytes. Can be rounded up to 16
    output  logic               image_valid_out,    // Set to 1 when compression finished. If 1, size of encoded data is address_out+bytes_out (or address_out+16)
    output  logic               data_valid_out,     // Qualifier for valid data. Data is invalid if 0.

    input   [3:0]               compression_factor_in,  // see doc for details re: quality factor 
    input   logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_in,
    input   logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_in,

    input   logic               clock_pixel_in,
    input   logic               reset_pixel_n_in,
    input   logic               clk_x22,
    input   logic               resetn_x22
);

// JPEG FSM
enum logic [2:0] {IDLE, RESET, WAIT_FOR_FRAME, COMPRESS, IMAGE_VALID} state;
logic               jpeg_reset_n;
logic               jpeg_en;

// image size config
logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_m1;
logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_m1;

// JPEG ISP (RGB2YUV, 4:4:4 2 4:2:0, 16-line MCU buffer)
logic signed[DW-1:0] di[7:0]; 
logic               di_valid;
logic               di_hold;
logic [2:0]         di_cnt;

// data out
logic [127:0]       out_data;
logic               out_tlast, out_valid;
logic [4:0]         out_bytes;
logic [19:0]        size;

// JPEG FSM
always @(posedge clock_pixel_in)
if (!reset_pixel_n_in)
    state <= IDLE;
else 
    case(state)
    1: state <= WAIT_FOR_FRAME;                             // reset state (1)
    2: if (frame_valid_in) state <= COMPRESS;               // compress state (2,3)
    3: if (out_valid & out_tlast) state <= IMAGE_VALID;     // compress state
    default: if (start_capture_in & ~frame_valid_in) state <= RESET;   // idle state (0) or image valid state (4)
    endcase        

always_comb jpeg_reset_n    = ~(state == RESET);
always_comb jpeg_en         = state inside {WAIT_FOR_FRAME, COMPRESS};
always_comb image_valid_out = state == IMAGE_VALID;

// image size config
always_comb x_size_m1 = x_size_in - 1;
always_comb y_size_m1 = y_size_in - 1;

// JPEG ISP (RGB2YUV, 4:4:4 2 4:2:0, 16-line MCU buffer)
jisp #(
    .SENSOR_X_SIZE      (SENSOR_X_SIZE),
    .SENSOR_Y_SIZE      (SENSOR_Y_SIZE)
) jisp (
    .rgb24              ({blue_data_in[9:2], green_data_in[9:2], red_data_in[9:2]}),
    .rgb24_valid        (jpeg_en & line_valid_in),
    .frame_valid_in     (jpeg_en & frame_valid_in),
    .line_valid_in      (jpeg_en & line_valid_in),
    .rgb24_hold         ( ),

    .clk                (clock_pixel_in),
    .resetn             (reset_pixel_n_in & jpeg_reset_n),
    .*
);

jenc #(
    .SENSOR_X_SIZE      (SENSOR_X_SIZE),
    .SENSOR_Y_SIZE      (SENSOR_Y_SIZE)
) jenc (
    .out_hold           (1'b0),

    .clk                (clock_pixel_in),
    .resetn             (reset_pixel_n_in & jpeg_reset_n),
    .*
);

// data out
// need to reverse data endianness 
always_comb 
    for(int i=0; i<16; i++)
        data_out[8*i +: 8] = out_data[8*(15-i) +: 8];    

always_comb address_out     = (size >> 4) << 4;
always_comb bytes_out       = out_bytes;
always_comb data_valid_out  = out_valid;

endmodule
