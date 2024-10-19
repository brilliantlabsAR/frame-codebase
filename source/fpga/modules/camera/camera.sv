/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *              Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2024 Brilliant Labs Limited
 */

`ifndef RADIANT
`include "modules/camera/crop.sv"
`include "modules/camera/debayer.sv"
`include "modules/camera/gamma_correction.sv"
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

    input logic jpeg_slow_clock_in, // 18MHz or 12 MHz
    input logic jpeg_slow_reset_n_in,

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

    // SPI interface
    input logic [7:0] opcode_in,
    input logic [7:0] operand_in,
    input logic operand_read,
    input logic operand_valid_in,
    input logic [31:0] rd_operand_count_in,
    output logic [7:0] response_out
);

logic start_capture_spi_clock_domain;;
logic start_capture_pixel_clock_domain;

//logic [10:0] x_resolution = 512;
//logic [10:0] y_resolution = 512;
//logic [10:0] x_pan = 0;

logic[10:0] x_zoom_crop_start;  // Todo: Make SPI register
logic[10:0] x_zoom_crop_end;    // Todo: Make SPI register
logic[10:0] y_zoom_crop_start;  // Todo: Make SPI register
logic[10:0] y_zoom_crop_end;    // Todo: Make SPI register
logic[10:0] x_resolution;       // Todo: Make SPI register
logic[10:0] y_resolution;       // Todo: Make SPI register

always_comb x_resolution = x_zoom_crop_end - x_zoom_crop_start; // Todo: Make SPI register
always_comb y_resolution = y_zoom_crop_end - y_zoom_crop_start; // Todo: Make SPI register

logic [1:0] compression_factor;
logic power_save_enable;

logic image_buffer_ready;               // Ready bit, high when compression finished
logic [15:0] image_buffer_total_size;   // final address + 4, sames as bytes available
logic [7:0] image_buffer_data;          // Read out data
logic [15:0] image_buffer_address;      // Read address

logic [7:0] red_center_metering;
logic [7:0] green_center_metering;
logic [7:0] blue_center_metering;
logic [7:0] red_average_metering;
logic [7:0] green_average_metering;
logic [7:0] blue_average_metering;

spi_registers spi_registers (
    .clock_in(spi_clock_in),
    .reset_n_in(spi_reset_n_in),

    // SPI interface
    .opcode_in(opcode_in),
    .operand_in(operand_in),
    .rd_operand_count_in(rd_operand_count_in),
    //.wr_operand_count_in(wr_operand_count),
    .operand_read(operand_read),
    .operand_valid_in(operand_valid_in),
    .response_out(response_out),

    .start_capture_out(start_capture_spi_clock_domain),
    // .x_resolution_out(x_resolution),
    // .y_resolution_out(y_resolution),
    // .x_pan_out(x_pan),
    .compression_factor_out(compression_factor),
    .power_save_enable_out(power_save_enable),

    .image_ready_in(image_buffer_ready),
    .image_total_size_in(image_buffer_total_size),
    .image_data_in(image_buffer_data),
    .image_address_out(image_buffer_address),

    .red_center_metering_in(red_center_metering),
    .green_center_metering_in(green_center_metering),
    .blue_center_metering_in(blue_center_metering),
    .red_average_metering_in(red_average_metering),
    .green_average_metering_in(green_average_metering),
    .blue_average_metering_in(blue_average_metering)
);

// SPI to display pulse sync
psync1 psync1_operand_valid_in (
        .in             (start_capture_spi_clock_domain),
        .in_clk         (~spi_clock_in),
        .in_reset_n     (spi_reset_n_in),
        .out            (start_capture_pixel_clock_domain),
        .out_clk        (pixel_clock_in),
        .out_reset_n    (pixel_reset_n_in)
);

`ifndef NO_MIPI_IP_SIM
logic [9:0] byte_to_pixel_data;
logic byte_to_pixel_line_valid;
logic byte_to_pixel_frame_valid;
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
    .pd_dphy_i(~global_reset_n_in | power_save_enable),
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
`ifndef IMAGE_X_SIZE
`define IMAGE_X_SIZE 200
`endif
`ifndef IMAGE_Y_SIZE
`define IMAGE_Y_SIZE 200
`endif
always_comb x_pan_crop_start    = 1;
always_comb x_pan_crop_end      = x_pan_crop_start + `IMAGE_X_SIZE + 2;
always_comb y_pan_crop_start    = 1;
always_comb y_pan_crop_end      = y_pan_crop_start + `IMAGE_Y_SIZE + 2;
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

    .red_data_in(byte_to_pixel_data),
    .green_data_in('0),
    .blue_data_in('0),
    .line_valid_in(byte_to_pixel_line_valid),
    .frame_valid_in(byte_to_pixel_frame_valid),

    .x_crop_start(x_pan_crop_start),
    .x_crop_end(x_pan_crop_end),
    .y_crop_start(y_pan_crop_start),
    .y_crop_end(y_pan_crop_end),

    .red_data_out(panned_data),
    .green_data_out( ),
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

logic center_metering_ready_pixel_clock_domain;
logic center_metering_ready_metastable;
logic center_metering_ready_spi_clock_domain;
logic average_metering_ready_pixel_clock_domain;
logic average_metering_ready_metastable;
logic average_metering_ready_spi_clock_domain;

metering #(.SIZE(128)) center_metering (
    .clock_in(pixel_clock_in),
    .reset_n_in(pixel_reset_n_in),

    .red_data_in(debayered_red_data),
    .green_data_in(debayered_green_data),
    .blue_data_in(debayered_blue_data),
    .line_valid_in(debayered_line_valid),
    .frame_valid_in(debayered_frame_valid),

    .red_metering_out(red_center_metering),
    .green_metering_out(green_center_metering),
    .blue_metering_out(blue_center_metering),
    .metering_ready_out(center_metering_ready_pixel_clock_domain)
);

metering #(.SIZE(512)) average_metering (
    .clock_in(pixel_clock_in),
    .reset_n_in(pixel_reset_n_in),

    .red_data_in(debayered_red_data),
    .green_data_in(debayered_green_data),
    .blue_data_in(debayered_blue_data),
    .line_valid_in(debayered_line_valid),
    .frame_valid_in(debayered_frame_valid),

    .red_metering_out(red_average_metering),
    .green_metering_out(green_average_metering),
    .blue_metering_out(blue_average_metering),
    .metering_ready_out(average_metering_ready_pixel_clock_domain)
);

always @(posedge spi_clock_in) begin : metering_cdc
    center_metering_ready_metastable <= center_metering_ready_pixel_clock_domain;
    center_metering_ready_spi_clock_domain <= center_metering_ready_metastable;
    average_metering_ready_metastable <= average_metering_ready_pixel_clock_domain;
    average_metering_ready_spi_clock_domain <= average_metering_ready_metastable;
end

logic [9:0] zoomed_red_data;
logic [9:0] zoomed_green_data;
logic [9:0] zoomed_blue_data;
logic zoomed_line_valid;
logic zoomed_frame_valid;

`ifdef COCOTB_SIM
// after debayer
always_comb x_zoom_crop_start    = 0;
always_comb x_zoom_crop_end      = x_pan_crop_end - x_pan_crop_start - 2;
always_comb y_zoom_crop_start    = 0;
always_comb y_zoom_crop_end      = y_pan_crop_end - y_pan_crop_start - 2;
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

logic [7:0] gamma_corrected_red_data;
logic [7:0] gamma_corrected_green_data;
logic [7:0] gamma_corrected_blue_data;
logic gamma_corrected_line_valid;
logic gamma_corrected_frame_valid;

gamma_correction gamma_correction (
    .clock_in(pixel_clock_in),

    .red_data_in(zoomed_red_data[9:2]),
    .green_data_in(zoomed_green_data[9:2]),
    .blue_data_in(zoomed_blue_data[9:2]),
    .line_valid_in(zoomed_line_valid),
    .frame_valid_in(zoomed_frame_valid),

    .red_data_out(gamma_corrected_red_data),
    .green_data_out(gamma_corrected_green_data),
    .blue_data_out(gamma_corrected_blue_data),
    .line_valid_out(gamma_corrected_line_valid),
    .frame_valid_out(gamma_corrected_frame_valid)
);

logic [31:0] final_image_data;          // image data JPEG -> Image buffer
logic [15:0] final_image_address;       // image address JPEG -> Image buffer
logic final_image_data_valid;           // qualifier
logic final_image_ready;                // Ready bit, high when compression finished

jpeg_encoder jpeg_encoder (
    .pixel_clock_in(pixel_clock_in),
    .pixel_reset_n_in(pixel_reset_n_in),

    .jpeg_fast_clock_in(jpeg_buffer_clock_in),
    .jpeg_fast_reset_n_in(jpeg_buffer_reset_n_in),

    .red_data_in({gamma_corrected_red_data, 2'b0}),
    .green_data_in({gamma_corrected_green_data, 2'b0}),
    .blue_data_in({gamma_corrected_blue_data, 2'b0}),
    .line_valid_in(gamma_corrected_line_valid),
    .frame_valid_in(gamma_corrected_frame_valid),

    .start_capture_in(start_capture_pixel_clock_domain),
    .x_size_in(x_resolution),
    .y_size_in(y_resolution),
    .qf_select_in(compression_factor),

    .data_out(final_image_data),
    .data_valid_out(final_image_data_valid),
    .address_out(final_image_address),
    .image_valid_out(final_image_ready)
);

always_comb image_buffer_total_size = final_image_address + 4;
always_comb image_buffer_ready = final_image_ready;

image_buffer image_buffer (
    .clock_in(jpeg_slow_clock_in),

    .write_address_in(final_image_address),
    .read_address_in(image_buffer_address),

    .write_data_in(final_image_data),
    .read_data_out(image_buffer_data),
    .write_read_n_in(final_image_data_valid)
);

endmodule
