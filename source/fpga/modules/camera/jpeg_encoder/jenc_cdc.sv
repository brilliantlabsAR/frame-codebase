module jenc_cdc (
    // input
    input logic[15:0]   jpeg_out_address,
    input logic[31:0]   jpeg_out_data,
    input logic         jpeg_out_data_valid,

    // output
    output  logic[13:0] jpeg_buffer_address,
    output  logic[31:0] jpeg_buffer_write_data,
    output  logic       jpeg_buffer_write_enable,

    // 2x clock
    input logic         clock_spi_in,
    input logic         reset_spi_n_in,
    // clock
    input logic         clock_pixel_in,
    input logic         reset_pixel_n_in
);

// JPEG CDC for frame buffer
logic [2:0]             jpeg_out_valid_cdc;
logic                   cdc_pulse;

always_comb cdc_pulse = jpeg_out_valid_cdc[2:1] == 2'b01;

always @(posedge clock_spi_in)
if (reset_spi_n_in == 0) begin
    jpeg_out_valid_cdc <= 0;
    jpeg_buffer_write_enable <= 0;
end
else begin
    // CDC Pulse
    jpeg_out_valid_cdc <= {jpeg_out_valid_cdc,  jpeg_out_data_valid};
    jpeg_buffer_write_enable <= cdc_pulse;
    if (cdc_pulse) begin
        jpeg_buffer_write_data <= jpeg_out_data;
        jpeg_buffer_address <= jpeg_out_address >> 2;
    end
end
endmodule
