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
`include "modules/camera/debayer.sv"
`include "modules/camera/image_buffer.sv"
`endif

module camera (
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

// Registers to hold the current command operations
logic capture_flag;
logic capture_in_progress_flag;

// TODO make capture_size dynamic once we have adjustable resolution
logic [15:0] capture_size = 200 * 200;
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
logic [1:0] cropped_frame_valid_edge_monitor;
logic cropped_frame_valid;

always_ff @(posedge clock_spi_in) begin
    if (reset_spi_n_in == 0) begin
        capture_in_progress_flag <= 0;
        cropped_frame_valid_edge_monitor <= 0;
    end

    else begin
        cropped_frame_valid_edge_monitor <= {cropped_frame_valid_edge_monitor[0],
                                             cropped_frame_valid};

        if (capture_flag && cropped_frame_valid_edge_monitor == 'b01) begin
            capture_in_progress_flag <= 1;
        end

        if (cropped_frame_valid_edge_monitor == 'b10) begin
            capture_in_progress_flag <= 0;
        end
    end
end

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

reset_sync reset_sync_clock_byte (
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

logic byte_to_pixel_frame_valid /* synthesis syn_keep=1 nomerge=""*/;
logic byte_to_pixel_line_valid /* synthesis syn_keep=1 nomerge=""*/;
logic [9:0] byte_to_pixel_data /* synthesis syn_keep=1 nomerge=""*/;

byte_to_pixel_ip byte_to_pixel_ip (
    .reset_byte_n_i(mipi_byte_reset_n),
    .clk_byte_i(mipi_byte_clock),
    .sp_en_i(mipi_sp_enable),
    .dt_i(mipi_datatype),
    .lp_av_en_i(mipi_lp_av_enable),
    .payload_en_i(mipi_payload_enable),
    .payload_i(mipi_payload),
    .wc_i(mipi_word_count),
    .reset_pixel_n_i(reset_pixel_n_in),
    .clk_pixel_i(clock_pixel_in),
    .fv_o(byte_to_pixel_frame_valid),
    .lv_o(byte_to_pixel_line_valid),
    .pd_o(byte_to_pixel_data)
);

logic [11:0] debayered_red_data;
logic [11:0] debayered_green_data;
logic [11:0] debayered_blue_data;
logic debayered_line_valid;
logic debayered_frame_valid;

debayer #(
    .X_RESOLUTION_IN(1288), // Include 1 left padding and 2 right padding
    .Y_RESOLUTION_IN(768) // Include 1 top padding and 1 bottom padding
) debayer (
    .pixel_clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),

    .pixel_data_in(byte_to_pixel_data),
    .line_valid_in(byte_to_pixel_line_valid),
    .frame_valid_in(byte_to_pixel_frame_valid),

    .pixel_red_data_out(debayered_red_data),
    .pixel_green_data_out(debayered_green_data),
    .pixel_blue_data_out(debayered_blue_data),
    .line_valid_out(debayered_line_valid),
    .frame_valid_out(debayered_frame_valid)
);

logic [9:0] cropped_red_data;
logic [9:0] cropped_green_data;
logic [9:0] cropped_blue_data;
logic cropped_line_valid;

crop #(
    .X_CROP_START(544),
    .X_CROP_END(744),
    .Y_CROP_START(628),
    .Y_CROP_END(828)
) crop (
    .pixel_clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),

    .pixel_red_data_in(debayered_red_data[11:2]),
    .pixel_green_data_in(debayered_green_data[11:2]),
    .pixel_blue_data_in(debayered_blue_data[11:2]),
    .line_valid_in(debayered_line_valid),
    .frame_valid_in(debayered_frame_valid),

    .pixel_red_data_out(cropped_red_data),
    .pixel_green_data_out(cropped_green_data),
    .pixel_blue_data_out(cropped_blue_data),
    .line_valid_out(cropped_line_valid),
    .frame_valid_out(cropped_frame_valid)
);

logic [15:0] buffer_write_address_metastable;
logic [15:0] buffer_write_address;
always_ff @(posedge clock_pixel_in) begin

    if (cropped_frame_valid == 0) begin
        buffer_write_address_metastable <= 0;
    end
    else if (cropped_frame_valid && cropped_line_valid) begin
        buffer_write_address_metastable <= buffer_write_address_metastable + 1;
    end

end

logic [7:0] buffer_write_data_metastable;
logic [7:0] buffer_write_data;
assign buffer_write_data_metastable = {cropped_red_data[9:7], 
                                       cropped_green_data[9:7], 
                                       cropped_blue_data[9:8]};

logic buffer_write_enable_metastable;
logic buffer_write_enable;
assign buffer_write_enable_metastable = cropped_frame_valid && 
                                        cropped_line_valid && 
                                        capture_in_progress_flag;

always_ff @(posedge clock_spi_in) begin
    
    if (reset_spi_n_in == 0) begin
        buffer_write_address <= 0;
        buffer_write_data <= 0;
        buffer_write_enable <= 0;
    end

    else begin
        buffer_write_address <= buffer_write_address_metastable;
        buffer_write_data <= buffer_write_data_metastable;
        buffer_write_enable <= buffer_write_enable_metastable;
    end
    
end

image_buffer image_buffer (
    .clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),
    .write_address_in(buffer_write_address),
    .read_address_in(buffer_read_address),
    .write_data_in(buffer_write_data),
    .read_data_out(buffer_read_data),
    .write_enable_in(buffer_write_enable)
);

`endif

endmodule