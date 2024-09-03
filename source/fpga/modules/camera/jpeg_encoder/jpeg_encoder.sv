/*
 * Top level for JPEG Encoder + ISP
 *
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
 module jpeg_encoder #(
    parameter DW = 8,
    parameter SENSOR_X_SIZE    = 720, //1280,
    parameter SENSOR_Y_SIZE    = 720
)(
    input   logic               start_capture_in,

    input   logic [9:0]         red_data_in,
    input   logic [9:0]         green_data_in,
    input   logic [9:0]         blue_data_in,    
    input   logic               frame_valid_in,
    input   logic               line_valid_in,

    output  logic [31:0]        data_out,           // 4 bytes of data
    output  logic [15:0]        address_out,        // Adress of 16-byte data in image buffer (in bytes)
    output  logic               image_valid_out,    // Set to 1 when compression finished. If 1, size of encoded data is address_out
    output  logic               data_valid_out,     // Qualifier for valid data. Data is invalid if 0.

    input   logic[1:0]          qf_select_in,       // select one of the 4 possible QF
    input   logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_in,
    input   logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_in,

    input   logic               pixel_clock_in,
    input   logic               pixel_reset_n_in,
    input   logic               jpeg_fast_clock_in,
    input   logic               jpeg_fast_reset_n_in
);

// clock
logic               clk_x22;
logic               resetn_x22;
logic [1:0]         jpeg_reset_n_x22_cdc;

// JPEG FSM
enum logic [2:0] {IDLE, RESET, WAIT_FOR_FRAME_START, COMPRESS, IMAGE_VALID} state;
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
logic [31:0]        out_data, out_data_rr;
logic               out_tlast, out_valid, out_hold;

// x22 reset
always_comb clk_x22 = jpeg_fast_clock_in;
always_comb resetn_x22 = jpeg_fast_reset_n_in & jpeg_reset_n_x22_cdc[1];

always @(posedge jpeg_fast_clock_in)
if (!jpeg_fast_reset_n_in)
    jpeg_reset_n_x22_cdc <= 0;
else
    jpeg_reset_n_x22_cdc <= {jpeg_reset_n_x22_cdc, jpeg_reset_n};

// JPEG FSM
always @(posedge pixel_clock_in)
if (!pixel_reset_n_in)
    state <= IDLE;
else 
    case(state)
    RESET:                  if (~frame_valid_in) state <= WAIT_FOR_FRAME_START;     // reset state (1), hold in reset until end of previous frame
    WAIT_FOR_FRAME_START:   if (frame_valid_in) state <= COMPRESS;                  // wait for frame start (2)
    COMPRESS:               if (out_valid & ~out_hold & out_tlast) state <= IMAGE_VALID;    // compress state (3)
    default:                if (start_capture_in) state <= RESET;                   // idle state (0) or image valid state (4)
    endcase        

always_comb jpeg_reset_n    = ~(state == RESET);
//../../jpeg_encoder/jpeg_encoder.sv:90: sorry: "inside" expressions not supported yet.
//always_comb jpeg_en         = state inside {WAIT_FOR_FRAME_START, COMPRESS};
always_comb jpeg_en         = state == WAIT_FOR_FRAME_START | state == COMPRESS;
always_comb image_valid_out = state == IMAGE_VALID;

// image size config
always_comb x_size_m1 = x_size_in - 1;
always_comb y_size_m1 = y_size_in - 1;

// JPEG ISP (RGB2YUV, 4:4:4 2 4:2:0, 16-line MCU buffer)
jisp #(
    .SENSOR_X_SIZE      (SENSOR_X_SIZE),
    .SENSOR_Y_SIZE      (SENSOR_Y_SIZE)
) jisp (
    .rgb24              ('{blue_data_in[9:2], green_data_in[9:2], red_data_in[9:2]}),
    .rgb24_valid        (jpeg_en & line_valid_in),
    .frame_valid_in     (jpeg_en & frame_valid_in),
    .line_valid_in      (jpeg_en & line_valid_in),
    .rgb24_hold         ( ),

    .clk                (pixel_clock_in),
    .resetn             (pixel_reset_n_in & jpeg_reset_n),
    .*
);

jenc #(
    .SENSOR_X_SIZE      (SENSOR_X_SIZE),
    .SENSOR_Y_SIZE      (SENSOR_Y_SIZE)
) jenc (
    .qf_select          (qf_select_in),

    .clk                (pixel_clock_in),
    .resetn             (pixel_reset_n_in & jpeg_reset_n),
    .*
);

// Size reg logic
logic [19:0]        size;
always @(posedge pixel_clock_in)
if (state==WAIT_FOR_FRAME_START & frame_valid_in)
    size <= 0;
else if (out_valid & ~out_hold)
    size <= size + 4;

// data out: need to reverse data endianness 
always @(posedge pixel_clock_in)
if (out_valid & ~out_hold) begin
    for(int i=0; i<4; i++)
        data_out[8*i +: 8] <= out_data[8*(3-i) +: 8];    
    address_out <= size;
end

// pre-CDC: Ensure there is always an idle  cycle
always @(posedge pixel_clock_in)
if (!(pixel_reset_n_in & jpeg_reset_n))
    data_valid_out <= 0;
else if (data_valid_out)
    data_valid_out <= 0;
else
    data_valid_out <= out_valid;

always_comb out_hold = data_valid_out;

endmodule
