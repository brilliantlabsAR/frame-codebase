module jenc_test_top #(
    parameter SENSOR_X_SIZE    = 720,
    parameter SENSOR_Y_SIZE    = 720
)(
    // clocks
    input logic             clock_spi_in, // 72MHz -%
    input logic             reset_spi_n_in,

    input logic             clock_pixel_in, // 36MHz +%
    input logic             reset_pixel_n_in,

    input logic [9:0]       debayered_red_data,
    input logic [9:0]       debayered_green_data,
    input logic [9:0]       debayered_blue_data,
    input logic             debayered_line_valid,
    input logic             debayered_frame_valid,

    //SPI side
    input logic[$clog2(SENSOR_X_SIZE)-1:0] x_size_m1,
    input logic[$clog2(SENSOR_Y_SIZE)-1:0] y_size_m1,

    input logic [15:0]      buffer_read_address,
    output logic [7:0]      buffer_read_data,

    input logic             jpeg_sel,
    input logic             jpeg_out_size_clear,
    input logic             jpeg_reset,

    output logic [19:0]     jpeg_out_size,
    output logic            jpeg_end
);

// JPEG Reset just in case
logic jpeg_reset_n;
reset_sync reset_sync_jpeg (
    .clock_in(clock_pixel_in),
    .async_reset_n_in(~jpeg_reset),
    .sync_reset_n_out(jpeg_reset_n)
);


// JPEG ISP (RGB2YUV, 4:4:4 2 4:2:0, 16-line MCU buffer)
logic [7:0]             jpeg_in_data[7:0]; 
logic                   jpeg_in_valid;
logic                   jpeg_in_hold;
logic [2:0]             jpeg_in_cnt;

jisp #(
    .SENSOR_X_SIZE      (720),
    .SENSOR_Y_SIZE      (720)
) jisp (
    .rgb24              ({debayered_blue_data[9:2], debayered_green_data[9:2], debayered_red_data[9:2]}),
    .rgb24_valid        (jpeg_sel & debayered_line_valid),
    .rgb24_hold         ( ),
    .frame_valid_in     (jpeg_sel & debayered_frame_valid),
    .line_valid_in      (jpeg_sel & debayered_line_valid),

    .di                 (jpeg_in_data),
    .di_valid           (jpeg_in_valid),
    .di_hold            (jpeg_in_hold),
    .di_cnt             (jpeg_in_cnt),

    .x_size_m1          (x_size_m1),
    .y_size_m1          (y_size_m1),

    .clk                (clock_pixel_in),
    .resetn             (reset_pixel_n_in & jpeg_reset_n)
);

logic [127:0]           jpeg_out_data;
logic [4:0]             jpeg_out_bytes;
logic                   jpeg_out_tlast;
logic                   jpeg_out_valid;


jenc #(
    .SENSOR_X_SIZE      (720),
    .SENSOR_Y_SIZE      (720)
) jenc (
    .di                 (jpeg_in_data),
    .di_valid           (jpeg_in_valid),
    .di_hold            (jpeg_in_hold),
    .di_cnt             (jpeg_in_cnt),

    .out_data           (jpeg_out_data),
    .out_bytes          (jpeg_out_bytes),
    .out_tlast          (jpeg_out_tlast),
    .out_valid          (jpeg_out_valid),
    .out_hold           (1'b0),

    .size               (jpeg_out_size),
    .size_clear         (jpeg_out_size_clear),

    .x_size_m1          (x_size_m1),
    .y_size_m1          (y_size_m1),

    .clk                (clock_pixel_in),
    .resetn             (reset_pixel_n_in & jpeg_reset_n)
);




// JPEG CDC for frame buffer
// CDC first, then split 128 bits into chunks of 32 bits/4 bytes, then write
//
// Important for synthesis:
// set false_path -from  -to ... (between clocks)
// set_max_delay {$clock_spi_in_period} -from [jpeg_out_data, jpeg_out_bytes, jpeg_out_valid, jpeg_out_tlast] -to  [get_clocks clock_spi_in]
// set_max_delay {$clock_spi_in_period} -from [jpeg_sel] -to [get_clocks clock_pixel_in]
logic [13:0]            jpeg_buffer_address;
logic [31:0]            jpeg_buffer_write_data;
logic                   jpeg_buffer_write_enable;

jenc_cdc jenc_cdc (.*);


// RGB data: Assemble 32 bits/4 bytes, then CDC, then write
//
// Important for synthesis:
// set false_path -from  -to ... (between clocks)
// set_max_delay {$clock_spi_in_period} -from [debayered_frame_valid rgb_buffer_write_data] -to  [get_clocks clock_spi_in]
// set_max_delay {$clock_spi_in_period} -from [jpeg_sel] -to [get_clocks clock_pixel_in]

logic [13:0]            rgb_buffer_address;
logic [31:0]            rgb_buffer_write_data;
logic                   rgb_buffer_write_enable;
	
rgb_cdc rgb_cdc (
    .line_valid         (debayered_line_valid),
    .frame_valid        (debayered_frame_valid),
    .red_data           (debayered_red_data),
    .green_data         (debayered_green_data),
    .blue_data          (debayered_blue_data),
    .*
);

// image buffer
logic [13:0]            buffer_address;
logic [31:0]            buffer_write_data;
logic                   buffer_write_enable;

always_comb buffer_address      = jpeg_sel ? jpeg_buffer_address : rgb_buffer_address;
always_comb buffer_write_data   = jpeg_sel ? jpeg_buffer_write_data : rgb_buffer_write_data;
always_comb buffer_write_enable = jpeg_sel ? jpeg_buffer_write_enable : rgb_buffer_write_enable;

image_buffer image_buffer (
    .clock_in(clock_spi_in),
    .reset_n_in(reset_spi_n_in),
    .write_address_in(buffer_address),
    .read_address_in(buffer_read_address),
    .write_data_in(buffer_write_data),
    .read_data_out(buffer_read_data),
    .write_enable_in(buffer_write_enable)
);
endmodule
