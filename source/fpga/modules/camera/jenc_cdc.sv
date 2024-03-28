module jenc_cdc (
    // input
    input logic[127:0]  jpeg_out_data,
    input logic[4:0]    jpeg_out_bytes,
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
logic [1:0]             word_cnt;
logic [11:0]            qword_cnt;
logic [127:32]          jpeg_out_data_127_32_cdc;

always @(posedge clock_spi_in)
if (reset_spi_n_in == 0) begin
    jpeg_out_valid_cdc <= 0;
    qword_cnt <= 0;
    word_cnt <= 0;
end else begin
    // CDC
    jpeg_out_valid_cdc[1:0] <= {jpeg_out_valid_cdc[0],  jpeg_out_data_valid};

    // little precaution: if not done writing the 4th 32-bit word when a new 128-bit word is available,
    // wait until finished
    if (!(jpeg_out_valid_cdc[2:1] == 2'b01 & word_cnt == 3))
        jpeg_out_valid_cdc[2] <= jpeg_out_valid_cdc[1];
        
    // capture CDC data    
    if (jpeg_out_valid_cdc[2:1] == 2'b01 & word_cnt == 0) begin
        jpeg_out_data_127_32_cdc <= jpeg_out_data[127:32];
    end

    if (jpeg_out_valid_cdc[2:1] == 2'b01 | word_cnt > 0)
        word_cnt <= word_cnt + 1;

    if (word_cnt == 3)
        qword_cnt <= qword_cnt + 1;
end 

always_comb jpeg_buffer_write_data = word_cnt == 0 ? jpeg_out_data[31:0] : jpeg_out_data_127_32_cdc[32*word_cnt +: 32];
always_comb jpeg_buffer_address = {qword_cnt, word_cnt};	
always_comb jpeg_buffer_write_enable = word_cnt > 0 | jpeg_out_valid_cdc[2:1] == 2'b01;

endmodule
