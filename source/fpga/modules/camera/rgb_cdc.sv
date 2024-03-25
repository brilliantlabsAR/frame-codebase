module rgb_cdc (
    // input
    input logic         jpeg_sel,
    input logic         line_valid,
    input logic         frame_valid,
    
    input logic[9:0]    red_data,
    input logic[9:0]    green_data,
    input logic[9:0]    blue_data,

    // output
    output  logic[13:0] rgb_buffer_address,
    output  logic[31:0] rgb_buffer_write_data,
    output  logic       rgb_buffer_write_enable,

    // 2x clock
    input logic         clock_spi_in,
    input logic         reset_spi_n_in,
    // clock
    input logic         clock_pixel_in,
    input logic         reset_pixel_n_in
);

always @(posedge clock_pixel_in) if($past(reset_pixel_n_in) && $past(frame_valid) && !frame_valid) assert ($past(pix_cnt) == 3) else $fatal("Enforcing even image dimensions!");

// RGB data: Assemble 32 bits/4 bytes, then CDC, then write
logic [1:0]             pix_cnt;
logic                   we_pre_cdc;
logic [2:0]				we_cdc;
logic [7:0]				pix_cnt_0_data;
	
always @(posedge clock_pixel_in)
if (reset_pixel_n_in == 0) begin
    pix_cnt <= 0;
    we_pre_cdc <= 0;
end else begin
    if (~jpeg_sel & line_valid & frame_valid) begin
        pix_cnt <= pix_cnt + 1;
        // assemble 32 bits of 4 pixels
        if (pix_cnt==0)
            pix_cnt_0_data <= {red_data[9:7], green_data[9:7], blue_data[9:8]};
        else begin
            rgb_buffer_write_data[8*pix_cnt +: 8] <= {red_data[9:7], green_data[9:7], blue_data[9:8]};
            if (pix_cnt==1)
                rgb_buffer_write_data[8*0 +: 8] <= pix_cnt_0_data;
        end
    end
    we_pre_cdc <= ~jpeg_sel & line_valid & frame_valid & pix_cnt==3;
end 

always @(posedge clock_spi_in)
if (reset_spi_n_in == 0) begin
    we_cdc <= 0;
    rgb_buffer_address <= 0;
end
else begin
    we_cdc <= {we_cdc, we_pre_cdc};
    if (rgb_buffer_write_enable)
        rgb_buffer_address <= frame_valid == 0 ? 0 : rgb_buffer_address + 1;
end

always_comb rgb_buffer_write_enable = we_cdc[2:1] == 2'b01;

endmodule
