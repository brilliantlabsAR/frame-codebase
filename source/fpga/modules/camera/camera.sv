/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

`ifndef RADIANT
// `include "modules/camera/debayer.sv"
// `include "modules/camera/fifo.sv"
`include "modules/camera/image_buffer.sv"
`endif

module camera #(
    CAPTURE_X_RESOLUTION = 200,
    CAPTURE_Y_RESOLUTION = 200
) (
    input logic global_reset_n_in,
    
    input logic clock_spi_in, // 72MHz
    input logic reset_spi_n_in,

    input logic clock_pixel_in, // 36MHz
    input logic reset_pixel_n_in,

    inout wire mipi_clock_p_in,
    inout wire mipi_clock_n_in,
    inout wire mipi_data_p_in,
    inout wire mipi_data_n_in,

    input logic [7:0] op_code_in,
    input logic op_code_valid_in,
    input logic [7:0] operand_in,
    input logic operand_valid_in,
    input integer operand_count_in,
    output logic [7:0] response_out,
    output logic response_valid_out
);

// TODO add buffers for metastability to inputs?

// Registers to hold the current command operations
logic capture_flag;
logic capture_in_progress_flag;

// TODO make capture_size dynamic once we have adjustable resolution
logic [15:0] capture_size = CAPTURE_X_RESOLUTION * CAPTURE_Y_RESOLUTION;
logic [15:0] bytes_read;

logic [15:0] bytes_remaining;
assign bytes_remaining = capture_size - bytes_read;

logic [15:0] buffer_read_address;
logic [7:0] buffer_read_data;
assign buffer_read_address = bytes_read;

logic last_op_code_valid_in;
logic last_operand_valid_in;

// Handle op-codes as they come in
always_ff @(posedge clock_spi_in) begin
    
    if (reset_spi_n_in == 0) begin
        response_out <= 0;
        response_valid_out <= 0;
        capture_flag <= 0;
        bytes_read <= 0;
        last_op_code_valid_in <= 0;
        last_operand_valid_in <= 0;
    end

    else begin

        last_op_code_valid_in <= op_code_valid_in;
        last_operand_valid_in <= operand_valid_in;

        // Clear capture flag once it is in process
        if (capture_in_progress_flag == 1) begin
            capture_flag <= 0;  
        end
        
        if (op_code_valid_in) begin

            case (op_code_in)

                // Capture
                'h20: begin
                    if (capture_in_progress_flag == 0) begin
                        capture_flag <= 1;
                        bytes_read <= 0;
                    end
                end

                // Bytes available
                'h21: begin
                    case (operand_count_in)
                        0: response_out <= bytes_remaining[15:8];
                        1: response_out <= bytes_remaining[7:0];
                    endcase

                    response_valid_out <= 1;
                end

                // Read data
                'h22: begin
                    response_out <= buffer_read_data;
                    response_valid_out <= 1;

                    if (last_operand_valid_in == 0 && operand_valid_in == 1) begin
                        bytes_read <= bytes_read + 1;
                    end
                end

            endcase

        end

        else begin
            response_valid_out <= 0;
        end

    end

end

// Capture command logic
logic [1:0] frame_valid_cropped_edge_monitor;
logic frame_valid_cropped;

always_ff @(posedge clock_spi_in) begin
    if (reset_spi_n_in == 0) begin
        capture_in_progress_flag <= 0;
        frame_valid_cropped_edge_monitor <= 0;
    end

    else begin
        frame_valid_cropped_edge_monitor <= {frame_valid_cropped_edge_monitor[0],
                                             frame_valid_cropped};

        if (capture_flag && frame_valid_cropped_edge_monitor == 'b01) begin
            capture_in_progress_flag <= 1;
        end

        if (frame_valid_cropped_edge_monitor == 'b10) begin
            capture_in_progress_flag <= 0;
        end
    end
end

`ifdef RADIANT

logic payload_en /* synthesis syn_keep=1 nomerge=""*/;
logic sp_en /* synthesis syn_keep=1 nomerge=""*/;
logic sp_en_d /* synthesis syn_keep=1 nomerge=""*/;
logic lp_av_en /* synthesis syn_keep=1 nomerge=""*/;
logic lp_av_en_d /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] payload /* synthesis syn_keep=1 nomerge=""*/;
logic [15:0] word_count /* synthesis syn_keep=1 nomerge=""*/;
logic [5:0] datatype;

logic clock_byte;
logic reset_byte_n;

reset_sync reset_sync_clock_byte (
    .clock_in(clock_byte),
    .async_reset_n_in(global_reset_n_in),
    .sync_reset_n_out(reset_byte_n)
);

csi2_receiver_ip csi2_receiver_ip (
    .clk_byte_o( ),
    .clk_byte_hs_o(clock_byte),
    .clk_byte_fr_i(clock_byte),
    .reset_n_i(global_reset_n_in), // async reset
    .reset_byte_fr_n_i(reset_byte_n),
    .clk_p_io(mipi_clock_p_in),
    .clk_n_io(mipi_clock_n_in),
    .d_p_io(mipi_data_p_in),
    .d_n_io(mipi_data_n_in),
    .payload_en_o(payload_en),
    .payload_o(payload),
    .tx_rdy_i(1'b1),
    .pd_dphy_i(~global_reset_n_in),
    .dt_o(datatype),
    .wc_o(word_count),
    .ref_dt_i(6'h2B), // RAW10 packet code
    .sp_en_o(sp_en),
    .lp_en_o(),
    .lp_av_en_o(lp_av_en)
);

always @(posedge clock_byte or negedge reset_byte_n) begin
    if (!reset_byte_n) begin
        lp_av_en_d <= 0;
        sp_en_d <= 0;
    end
    else begin
        lp_av_en_d <= lp_av_en;
        sp_en_d <= sp_en;
    end
end

logic payload_en_1d, payload_en_2d, payload_en_3d /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] payload_1d /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] payload_2d /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] payload_3d /* synthesis syn_keep=1 nomerge=""*/;
always @(posedge clock_byte or negedge reset_byte_n) begin
    if (!reset_byte_n) begin
        payload_en_1d <= 0;
        payload_en_2d <= 0;
        payload_en_3d <= 0;

        payload_1d <= 0;
        payload_2d <= 0;
        payload_3d <= 0;
    end
    else begin
        payload_en_1d <= payload_en;
        payload_en_2d <= payload_en_1d;
        payload_en_3d <= payload_en_2d;

        payload_1d <= payload;
        payload_2d <= payload_1d;
        payload_3d <= payload_2d;
    end
end

logic frame_valid /* synthesis syn_keep=1 nomerge=""*/;
logic line_valid /* synthesis syn_keep=1 nomerge=""*/;
logic [9:0] pixel_data /* synthesis syn_keep=1 nomerge=""*/;

byte_to_pixel_ip byte_to_pixel_ip (
    .reset_byte_n_i(reset_byte_n),
    .clk_byte_i(clock_byte),
    .sp_en_i(sp_en_d),
    .dt_i(datatype),
    .lp_av_en_i(lp_av_en_d),
    .payload_en_i(payload_en_3d),
    .payload_i(payload_3d),
    .wc_i(word_count),
    .reset_pixel_n_i(reset_pixel_n_in),
    .clk_pixel_i(clock_pixel_in),
    .fv_o(frame_valid),
    .lv_o(line_valid),
    .pd_o(pixel_data)
);

logic [11:0] pixel_red_data_debayer_to_crop;
logic [11:0] pixel_green_data_debayer_to_crop;
logic [11:0] pixel_blue_data_debayer_to_crop;
logic line_valid_debayer_to_crop;
logic frame_valid_debayer_to_crop;

debayer #(
    .X_RESOLUTION_IN(1288), // Include 1 left padding and 2 right padding
    .Y_RESOLUTION_IN(768) // Include 1 top padding and 1 bottom padding
) debayer (
    .pixel_clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),

    .pixel_data_in(pixel_data),
    .line_valid_in(line_valid),
    .frame_valid_in(frame_valid),

    .pixel_red_data_out(pixel_red_data_debayer_to_crop),
    .pixel_green_data_out(pixel_green_data_debayer_to_crop),
    .pixel_blue_data_out(pixel_blue_data_debayer_to_crop),
    .line_valid_out(line_valid_debayer_to_crop),
    .frame_valid_out(frame_valid_debayer_to_crop)
);

logic [9:0] pixel_red_data_cropped;
logic [9:0] pixel_green_data_cropped;
logic [9:0] pixel_blue_data_cropped;
logic line_valid_cropped;

crop #(
    .X_CROP_START(544),
    .X_CROP_END(744),
    .Y_CROP_START(628),
    .Y_CROP_END(828)
) crop (
    .pixel_clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),

    .pixel_red_data_in(pixel_red_data_debayer_to_crop[11:2]),
    .pixel_green_data_in(pixel_green_data_debayer_to_crop[11:2]),
    .pixel_blue_data_in(pixel_blue_data_debayer_to_crop[11:2]),
    .line_valid_in(line_valid_debayer_to_crop),
    .frame_valid_in(frame_valid_debayer_to_crop),

    .pixel_red_data_out(pixel_red_data_cropped),
    .pixel_green_data_out(pixel_green_data_cropped),
    .pixel_blue_data_out(pixel_blue_data_cropped),
    .line_valid_out(line_valid_cropped),
    .frame_valid_out(frame_valid_cropped)
);

logic buffer_write_enable /* synthesis syn_keep=1 nomerge=""*/;
logic [15:0] buffer_write_address;
logic [15:0] buffer_write_data;
assign buffer_write_data = {
        pixel_red_data_cropped[9:7],
        pixel_green_data_cropped[9:7],
        pixel_blue_data_cropped[9:8]};

always_ff @(posedge clock_pixel_in) begin
    if (frame_valid_cropped == 0) begin
        buffer_write_address <= 0;
        buffer_write_enable <= 0;
    end
    else if (frame_valid_cropped & line_valid_cropped & capture_in_progress_flag) begin
        buffer_write_address <= buffer_write_address + 1;
        buffer_write_enable <= 1;
    end
    else begin
        buffer_write_enable <= 0;
    end
end

image_buffer image_buffer (
    .clock(clock_spi_in),
    .reset_n(reset_spi_n_in),
    .write_address(buffer_write_address),
    .read_address(buffer_read_address),
    .write_data(buffer_write_data),
    .read_data(buffer_read_data),
    .write_enable(buffer_write_enable)
);

`endif

endmodule