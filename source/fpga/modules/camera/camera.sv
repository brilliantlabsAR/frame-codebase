/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

`ifndef RADIANT
`include "modules/camera/crop.sv"
`include "modules/camera/debayer.sv"
`include "modules/camera/image_buffer.sv"
`include "modules/camera/jpeg/jpeg.sv"
`include "modules/camera/metering.sv"
`include "modules/camera/spi_registers.sv"
`endif

`ifdef TESTBENCH
`include "modules/camera/testbenches/image_gen.sv"
`endif

module camera (
    input logic global_reset_n_in,
    
    input logic spi_clock_in, // 72MHz
    input logic spi_reset_n_in,

    input logic pixel_clock_in, // 36MHz
    input logic pixel_reset_n_in,

    input logic jpeg_buffer_clock_in, // 78MHz
    input logic jpeg_buffer_reset_n_in,

`ifndef NO_MIPI_IP_SIM
    inout wire mipi_clock_p_in,
    inout wire mipi_clock_n_in,
    inout wire mipi_data_p_in,
    inout wire mipi_data_n_in,
`else
    // for NO_MIPI_IP_SIM
    input logic byte_to_pixel_frame_valid,
    input logic byte_to_pixel_line_valid,
    input logic [9:0] byte_to_pixel_data,
`endif //NO_MIPI_IP_SIM

    input logic [7:0] op_code_in,
    input logic op_code_valid_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    input integer operand_count_in,
    output logic [7:0] response_out,
    output logic response_valid_out
);

// TODO position signals
logic start_capture_spi_domain;
logic start_capture_metastable;
logic start_capture_pixel_domain;
logic [3:0] compression_factor;

logic [15:0] bytes_available;
logic [7:0] image_buffer_data;
logic [15:0] image_buffer_address;

logic [7:0] red_metering_spi_clock_domain;
logic [7:0] green_metering_spi_clock_domain;
logic [7:0] blue_metering_spi_clock_domain;

logic [15:0] image_address;
logic image_complete;

always_comb bytes_available = image_address + 4;
spi_registers spi_registers (
    .clock_in(spi_clock_in),
    .reset_n_in(spi_reset_n_in),

    .op_code_in(op_code_in),
    .op_code_valid_in(op_code_valid_in),
    .operand_in(operand_in),
    .operand_valid_in(operand_valid_in),
    .operand_count_in(operand_count_in),
    .response_out(response_out),
    .response_valid_out(response_valid_out),

    .start_capture_out(start_capture_spi_domain),
    // TODO position signals
    .compression_factor_out(compression_factor),

    // JPEG image
    .image_address(image_address),
    .image_complete(image_complete),

    .bytes_available_in(bytes_available),
    .data_in(image_buffer_data),
    .bytes_read_out(image_buffer_address),

    .red_metering_in(red_metering_spi_clock_domain),
    .green_metering_in(green_metering_spi_clock_domain),
    .blue_metering_in(blue_metering_spi_clock_domain)
);

always @(posedge pixel_clock_in) begin
    if (pixel_reset_n_in == 0) begin
        start_capture_metastable <= 0;
        start_capture_pixel_domain <= 0;
    end

    else begin
        start_capture_metastable <= start_capture_spi_domain;
        start_capture_pixel_domain <= start_capture_metastable;
    end
end

`ifndef NO_MIPI_IP_SIM
logic byte_to_pixel_frame_valid /* synthesis syn_keep=1 nomerge=""*/;
logic byte_to_pixel_line_valid /* synthesis syn_keep=1 nomerge=""*/;
logic [9:0] byte_to_pixel_data /* synthesis syn_keep=1 nomerge=""*/;
`endif //NO_MIPI_IP_SIM

`ifndef NO_MIPI_IP_SIM
`ifdef RADIANT
logic mipi_byte_clock;
logic mipi_byte_reset_n;

logic mipi_payload_enable_metastable /* synthesis syn_keep=1 nomerge=""*/;
logic mipi_payload_enable /* synthesis syn_keep=1 nomerge=""*/;

logic [7:0] mipi_payload_metastable /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] mipi_payload /* synthesis syn_keep=1 nomerge=""*/;

logic mipi_sp_enable_metastable /* synthesis syn_keep=1 nomerge=""*/;
logic mipi_sp_enable /* synthesis syn_keep=1 nomerge=""*/;

logic mipi_lp_av_enable_metastable /* synthesis syn_keep=1 nomerge=""*/;
logic mipi_lp_av_enable /* synthesis syn_keep=1 nomerge=""*/;

logic [15:0] mipi_word_count /* synthesis syn_keep=1 nomerge=""*/;
logic [5:0] mipi_datatype;

reset_sync mipi_byte_clock_reset_sync (
    .clock_in(mipi_byte_clock),
    .async_reset_n_in(global_reset_n_in),
    .sync_reset_n_out(mipi_byte_reset_n)
);

csi2_receiver_ip csi2_receiver_ip (
    .clk_byte_o(),
    .clk_byte_hs_o(mipi_byte_clock),
    .clk_byte_fr_i(mipi_byte_clock),
    .reset_n_i(global_reset_n_in),
    .reset_byte_fr_n_i(mipi_byte_reset_n),
    .clk_p_io(mipi_clock_p_in),
    .clk_n_io(mipi_clock_n_in),
    .d_p_io(mipi_data_p_in),
    .d_n_io(mipi_data_n_in),
    .payload_en_o(mipi_payload_enable_metastable),
    .payload_o(mipi_payload_metastable),
    .tx_rdy_i(1'b1),
    .pd_dphy_i(~global_reset_n_in),
    .dt_o(mipi_datatype),
    .wc_o(mipi_word_count),
    .ref_dt_i(6'h2B),
    .sp_en_o(mipi_sp_enable_metastable),
    .lp_en_o(),
    .lp_av_en_o(mipi_lp_av_enable_metastable)
);

always @(posedge mipi_byte_clock or negedge mipi_byte_reset_n) begin
    if (!mipi_byte_reset_n) begin
        mipi_payload_enable <= 0;
        mipi_payload <= 0;
        mipi_sp_enable <= 0;
        mipi_lp_av_enable <= 0;
    end

    else begin
        mipi_payload_enable <= mipi_payload_enable_metastable;
        mipi_payload <= mipi_payload_metastable;
        mipi_sp_enable <= mipi_sp_enable_metastable;
        mipi_lp_av_enable <= mipi_lp_av_enable_metastable;
    end
end

byte_to_pixel_ip byte_to_pixel_ip (
    .reset_byte_n_i(mipi_byte_reset_n),
    .clk_byte_i(mipi_byte_clock),
    .sp_en_i(mipi_sp_enable),
    .dt_i(mipi_datatype),
    .lp_av_en_i(mipi_lp_av_enable),
    .payload_en_i(mipi_payload_enable),
    .payload_i(mipi_payload),
    .wc_i(mipi_word_count),
    .reset_pixel_n_i(pixel_reset_n_in),
    .clk_pixel_i(pixel_clock_in),
    .fv_o(byte_to_pixel_frame_valid),
    .lv_o(byte_to_pixel_line_valid),
    .pd_o(byte_to_pixel_data)
);
`endif // RADIANT
`endif //NO_MIPI_IP_SIM

`ifdef TESTBENCH // TESTBENCH
image_gen image_gen (
    .clock_in(pixel_clock_in),
    .reset_n_in(pixel_reset_n_in),

    .bayer_data_out(byte_to_pixel_data),
    .line_valid_out(byte_to_pixel_line_valid),
    .frame_valid_out(byte_to_pixel_frame_valid)
);
`endif // TESTBENCH

logic [9:0] panned_data;
logic panned_line_valid;
logic panned_frame_valid;

logic[10:0] x_pan_crop_start;   // Todo: Make SPI register
logic[10:0] x_pan_crop_end;     // Todo: Make SPI register
logic[10:0] y_pan_crop_start;   // Todo: Make SPI register
logic[10:0] y_pan_crop_end;     // Todo: Make SPI register

`ifdef COCOTB_SIM
always_comb x_pan_crop_start    = 1;
always_comb x_pan_crop_end      = x_pan_crop_start + 200 + 2;
//always_comb x_pan_crop_end      = x_pan_crop_start + 16 + 2;
always_comb y_pan_crop_start    = 1;
always_comb y_pan_crop_end      = y_pan_crop_start + 200 + 2;
//always_comb y_pan_crop_end      = y_pan_crop_start + 16 + 2;
`else
`ifdef TESTBENCH
always_comb x_pan_crop_start    = 10;
always_comb x_pan_crop_end      = 25;
always_comb y_pan_crop_start    = 12;
always_comb y_pan_crop_end      = 24;
`else
always_comb x_pan_crop_start    = 284;
always_comb x_pan_crop_end      = 1004;
always_comb y_pan_crop_start    = 4;
always_comb y_pan_crop_end      = 724;
`endif
`endif

crop pan_crop (
    .clock_in(pixel_clock_in),
    .reset_n_in(pixel_reset_n_in),

    .red_data_in('0),
    .green_data_in(byte_to_pixel_data),
    .blue_data_in('0),
    .line_valid_in(byte_to_pixel_line_valid),
    .frame_valid_in(byte_to_pixel_frame_valid),

    .x_crop_start(x_pan_crop_start),
    .x_crop_end(x_pan_crop_end),
    .y_crop_start(y_pan_crop_start),
    .y_crop_end(y_pan_crop_end),

    .red_data_out( ),
    .green_data_out(panned_data),
    .blue_data_out( ),
    .line_valid_out(panned_line_valid),
    .frame_valid_out(panned_frame_valid)
);

logic [9:0] debayered_red_data;
logic [9:0] debayered_green_data;
logic [9:0] debayered_blue_data;
logic debayered_line_valid;
logic debayered_frame_valid;

debayer debayer (
    .pixel_clock_in(pixel_clock_in),
    .pixel_reset_n_in(pixel_reset_n_in),

    .x_crop_start_lsb(x_pan_crop_start[0]),
    .y_crop_start_lsb(y_pan_crop_start[0]),

    .bayer_data_in(panned_data),
    .line_valid_in(panned_line_valid),
    .frame_valid_in(panned_frame_valid),

    .red_data_out(debayered_red_data),
    .green_data_out(debayered_green_data),
    .blue_data_out(debayered_blue_data),
    .line_valid_out(debayered_line_valid),
    .frame_valid_out(debayered_frame_valid)
);

logic [7:0] red_metering_pixel_clock_domain;
logic [7:0] green_metering_pixel_clock_domain;
logic [7:0] blue_metering_pixel_clock_domain;

logic [7:0] red_metering_metastable;
logic [7:0] green_metering_metastable;
logic [7:0] blue_metering_metastable;

metering metering (
    .clock_in(pixel_clock_in),
    .reset_n_in(pixel_reset_n_in),

    .red_data_in(debayered_red_data),
    .green_data_in(debayered_green_data),
    .blue_data_in(debayered_blue_data),
    .line_valid_in(debayered_line_valid),
    .frame_valid_in(debayered_frame_valid),

    .red_metering_out(red_metering_pixel_clock_domain),
    .green_metering_out(green_metering_pixel_clock_domain),
    .blue_metering_out(blue_metering_pixel_clock_domain)
);

always @(posedge spi_clock_in) begin
    if (spi_reset_n_in == 0) begin
        red_metering_metastable <= 0;
        green_metering_metastable <= 0;
        blue_metering_metastable <= 0;

        red_metering_spi_clock_domain <= 0;
        green_metering_spi_clock_domain <= 0;
        blue_metering_spi_clock_domain <= 0;
    end

    else begin
        red_metering_metastable <= red_metering_pixel_clock_domain;
        green_metering_metastable <= green_metering_pixel_clock_domain;
        blue_metering_metastable <= blue_metering_pixel_clock_domain;

        red_metering_spi_clock_domain <= red_metering_metastable;
        green_metering_spi_clock_domain <= green_metering_metastable;
        blue_metering_spi_clock_domain <= blue_metering_metastable;
    end
end

logic [9:0] zoomed_red_data;
logic [9:0] zoomed_green_data;
logic [9:0] zoomed_blue_data;
logic zoomed_line_valid;
logic zoomed_frame_valid;

logic[10:0] x_zoom_crop_start;  // Todo: Make SPI register
logic[10:0] x_zoom_crop_end;    // Todo: Make SPI register
logic[10:0] y_zoom_crop_start;  // Todo: Make SPI register
logic[10:0] y_zoom_crop_end;    // Todo: Make SPI register
logic[10:0] x_size;             // Todo: Make SPI register
logic[10:0] y_size;             // Todo: Make SPI register

always_comb x_size = x_zoom_crop_end - x_zoom_crop_start;
always_comb y_size = y_zoom_crop_end - y_zoom_crop_start;

`ifdef COCOTB_SIM
// after debayer
always_comb x_zoom_crop_start    = 0;
always_comb x_zoom_crop_end      = x_pan_crop_end - x_pan_crop_start - 2;
//always_comb x_zoom_crop_end      = 16;
always_comb y_zoom_crop_start    = 0;
always_comb y_zoom_crop_end      = y_pan_crop_end - y_pan_crop_start - 2;
//always_comb y_zoom_crop_end      = 16;
`else
`ifdef TESTBENCH
always_comb x_zoom_crop_start    = 0;
always_comb x_zoom_crop_end      = 15;
always_comb y_zoom_crop_start    = 0;
always_comb y_zoom_crop_end      = 12;
`else
always_comb x_zoom_crop_start    = 260;
always_comb x_zoom_crop_end      = 460;
always_comb y_zoom_crop_start    = 260;
always_comb y_zoom_crop_end      = 460;
`endif
`endif

crop zoom_crop (
    .clock_in(pixel_clock_in),
    .reset_n_in(pixel_reset_n_in),

    .red_data_in(debayered_red_data),
    .green_data_in(debayered_green_data),
    .blue_data_in(debayered_blue_data),
    .line_valid_in(debayered_line_valid),
    .frame_valid_in(debayered_frame_valid),

    .x_crop_start(x_zoom_crop_start),
    .x_crop_end(x_zoom_crop_end),
    .y_crop_start(y_zoom_crop_start),
    .y_crop_end(y_zoom_crop_end),

    .red_data_out(zoomed_red_data),
    .green_data_out(zoomed_green_data),
    .blue_data_out(zoomed_blue_data),
    .line_valid_out(zoomed_line_valid),
    .frame_valid_out(zoomed_frame_valid)
);

logic [127:0] image_data;
//logic [15:0] image_address;
logic image_data_valid;
//logic image_complete;

// Define selection of 4 possible QF
parameter QF0 = 50;
parameter QF1 = 100;
parameter QF2 = 10;
parameter QF3 = 25;

jpeg_encoder #(.QF0(QF0), .QF1(QF1), .QF2(QF2), .QF3(QF3)) jpeg_encoder (
    .pixel_clock_in(pixel_clock_in),
    .pixel_reset_n_in(pixel_reset_n_in),

    .jpeg_fast_clock_in(jpeg_buffer_clock_in),
    .jpeg_fast_reset_n_in(jpeg_buffer_reset_n_in),

    .red_data_in(zoomed_red_data),
    .green_data_in(zoomed_green_data),
    .blue_data_in(zoomed_blue_data),
    .line_valid_in(zoomed_line_valid),
    .frame_valid_in(zoomed_frame_valid),

    .start_capture_in(start_capture_pixel_domain),
    .x_size_in(x_size),
    .y_size_in(y_size),
    .qf_select_in(compression_factor[1:0]),

    .data_out(image_data),
    .data_valid_out(image_data_valid),
    .address_out(image_address),
    .image_valid_out(image_complete)
);

image_buffer image_buffer (
    .write_address_in(image_address),
    .read_address_in(image_buffer_address),
    .write_data_in(image_data),
    .read_data_out(image_buffer_data),
    .write_read_n_in(image_data_valid),
    .*
);

endmodule
