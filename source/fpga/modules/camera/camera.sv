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
`include "modules/camera/metering.sv"
`endif

module camera (
    input logic global_reset_n_in,
    
    input logic clock_spi_in, // 72MHz
    input logic reset_spi_n_in,

    input logic clock_pixel_in, // 36MHz
    input logic reset_pixel_n_in,

    input logic clk_x22, // must be faster than 2*36MHz!
    input logic resetn_x22,

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

`ifdef COCOTB_MODELSIM
`ifndef TOP_SIM
`include "dumper.vh"
GSR GSR_INST (.GSR_N('1), .CLK(clk));
`endif //TOP_SIM
`endif //COCOTB_MODELSIM

`ifndef NO_MIPI_IP_SIM
logic byte_to_pixel_frame_valid /* synthesis syn_keep=1 nomerge=""*/;
logic byte_to_pixel_line_valid /* synthesis syn_keep=1 nomerge=""*/;
logic [9:0] byte_to_pixel_data /* synthesis syn_keep=1 nomerge=""*/;
`endif //NO_MIPI_IP_SIM

logic[10:0] X_CROP_START;   // Todo: Make SPI register
logic[10:0] X_CROP_END;     // Todo: Make SPI register
logic[9:0] Y_CROP_START;    // Todo: Make SPI register
logic[9:0] Y_CROP_END;      // Todo: Make SPI register

always_ff @(posedge clock_spi_in) X_CROP_START <= 0;
always_ff @(posedge clock_spi_in) X_CROP_END   <= 18;
always_ff @(posedge clock_spi_in) Y_CROP_START <= 0;
always_ff @(posedge clock_spi_in) Y_CROP_END   <= 18;

logic[10:0] x_size;     // Todo: Make SPI register
logic[9:0] y_size;      // Todo: Make SPI register

always_comb x_size = X_CROP_END - X_CROP_START - 2;
always_comb y_size = Y_CROP_END - Y_CROP_START - 2;

// Registers to hold the current command operations
logic capture_flag;
logic capture_in_progress_flag;

// TODO make capture_size dynamic once we have adjustable resolution
logic [15:0] bytes_read;

logic [15:0] buffer_read_address;
logic [7:0] buffer_read_data;
assign buffer_read_address = bytes_read;

logic [7:0] red_metering;
logic [7:0] green_metering;
logic [7:0] blue_metering;

logic last_op_code_valid_in;
logic last_operand_valid_in;

// Jpeg
logic                   rgb_sel, jpeg_sel;
logic [19:0]            jpeg_out_size;
always_comb jpeg_sel = ~rgb_sel;

// Handle op-codes as they come in
always_ff @(posedge clock_spi_in) begin
    
    if (reset_spi_n_in == 0) begin
        response_out <= 0;
        response_valid_out <= 0;
        capture_flag <= 0;
        bytes_read <= 0;
        last_op_code_valid_in <= 0;
        last_operand_valid_in <= 0;

        rgb_sel <= 0;
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
                    capture_flag <= 1;
                    bytes_read <= 0;
                end

                // Read data
                'h22: begin
                    response_out <= buffer_read_data;
                    response_valid_out <= 1;

                    if (last_operand_valid_in == 0 && operand_valid_in == 1) begin
                        bytes_read <= bytes_read + 1;
                    end
                end

                // JPEG
                'h30: begin
                    if (operand_valid_in) begin
                        rgb_sel <= operand_in[0]; // flip sense
                    end
                end
                // JPEG size
                'h31: begin
                    response_valid_out <= 1;
                    case (operand_count_in)
                        0: response_out <= jpeg_out_size[7:0];
                        1: response_out <= jpeg_out_size[15:8];
                        2: response_out <= jpeg_out_size[19:16];
                    endcase
                end

                // Metering
                'h25: begin
                    case (operand_count_in)
                        0: response_out <= red_metering;
                        1: response_out <= green_metering;
                        2: response_out <= blue_metering;
                    endcase

                    response_valid_out <= 1;
                end

            endcase

        end

        else begin
            response_valid_out <= 0;
        end

    end

end

// Capture command logic
logic [1:0] frame_valid_cdc;
logic [1:0] capture_in_progress_state;
logic [2:0] capture_in_progress_cdc;

logic debayered_frame_valid;
logic cropped_frame_valid;
logic jpeg_end;

always_comb capture_in_progress_flag  = capture_in_progress_state[1];

always_ff @(posedge clock_spi_in) begin
    if (reset_spi_n_in == 0) begin
        frame_valid_cdc <= 0;
        capture_in_progress_state <= 0;
    end

    else begin
        frame_valid_cdc <= {frame_valid_cdc, (byte_to_pixel_frame_valid | cropped_frame_valid | debayered_frame_valid)};
        
        case (capture_in_progress_state)
        0 : if (frame_valid_cdc[1] == 0 & capture_flag)
                capture_in_progress_state <= 1;
        1 : if (frame_valid_cdc[1] == 1)
                capture_in_progress_state <= 3;
        default : if (frame_valid_cdc[1] == 0)
                capture_in_progress_state <= 0;
        endcase
    end
end

// CDC
always_ff @(posedge clock_pixel_in)
    if (reset_pixel_n_in == 0) 
        capture_in_progress_cdc <= 0;
    else 
        capture_in_progress_cdc <= {capture_in_progress_cdc, capture_in_progress_flag};

// CDC
logic [1:0] jpeg_sel_cdc;
always_ff @(posedge clock_pixel_in)
    if (reset_pixel_n_in == 0) 
        jpeg_sel_cdc <= 1;
    else 
        jpeg_sel_cdc <= {jpeg_sel_cdc, jpeg_sel};
`ifdef RADIANT

`ifndef NO_MIPI_IP_SIM
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
`endif //NO_MIPI_IP_SIM

logic [9:0] cropped_data;
logic cropped_line_valid;
//logic cropped_frame_valid;

crop crop (
    .pixel_clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),

    .x_crop_start(X_CROP_START),
    .x_crop_end(X_CROP_END),
    .y_crop_start(Y_CROP_START),
    .y_crop_end(Y_CROP_END),

    .pixel_red_data_in(byte_to_pixel_data),
    .pixel_green_data_in('0),
    .pixel_blue_data_in('0),
    .line_valid_in(byte_to_pixel_line_valid),
    .frame_valid_in(byte_to_pixel_frame_valid),

    .pixel_red_data_out(cropped_data),
    .pixel_green_data_out(),
    .pixel_blue_data_out(),
    .line_valid_out(cropped_line_valid),
    .frame_valid_out(cropped_frame_valid)
);

logic [9:0] debayered_red_data;
logic [9:0] debayered_green_data;
logic [9:0] debayered_blue_data;
logic debayered_line_valid;
//logic debayered_frame_valid;

// TODO: fix ranges, only works 0:728
debayer debayer (
    .pixel_clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),

    .pixel_data_in(cropped_data),
    .line_valid_in(cropped_line_valid),
    .frame_valid_in(cropped_frame_valid),

    .pixel_red_data_out(debayered_red_data),
    .pixel_green_data_out(debayered_green_data),
    .pixel_blue_data_out(debayered_blue_data),
    .line_valid_out(debayered_line_valid),
    .frame_valid_out(debayered_frame_valid)
);

metering #(
    .X_WINDOW_START(104), 
    .X_WINDOW_END(616),
    .Y_WINDOW_START(104),
    .Y_WINDOW_END(616)
) metering (
    .pixel_clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),

    .pixel_data_in(byte_to_pixel_data),
    .line_valid_in(byte_to_pixel_line_valid),
    .frame_valid_in(byte_to_pixel_frame_valid),

    .red_metering_out(red_metering),
    .green_metering_out(green_metering),
    .blue_metering_out(blue_metering)
);


// JPEG Top
logic [31:0]        jpeg_out_data;
logic [15:0]        jpeg_out_address;
logic               jpeg_out_image_valid;
logic               jpeg_out_data_valid;


jenc_top #(
    .SENSOR_X_SIZE      (1280),
    .SENSOR_Y_SIZE      (720)
) jenc_top (
    .start_capture_in   (jpeg_sel & (capture_in_progress_cdc[2:1] == 2'b01)),

    .red_data_in        (debayered_red_data),
    .green_data_in      (debayered_green_data),
    .blue_data_in       (debayered_blue_data),
    .frame_valid_in     (debayered_frame_valid),
    .line_valid_in      (debayered_line_valid),

    .data_out           (jpeg_out_data),
    .address_out        (jpeg_out_address),
    .image_valid_out    (jpeg_out_image_valid),
    .data_valid_out     (jpeg_out_data_valid),

    .compression_factor_in  ('0),
    .x_size_in          (x_size),
    .y_size_in          (y_size),

    .clock_pixel_in,
    .reset_pixel_n_in,
    .clk_x22,
    .resetn_x22
);

// JPEG CDC for frame buffer
// CDC first, then split 128 bits into chunks of 32 bits/4 bytes, then write
//
// Important for synthesis:
// set false_path -from  -to ... (between clocks)
// set_max_delay {$clock_spi_in_period} -from [jpeg_sel] -to [get_clocks clock_pixel_in]

always_comb jpeg_out_size = jpeg_out_image_valid ? jpeg_out_address + 4 : 0;

logic [13:0]            jpeg_buffer_address;
logic [31:0]            jpeg_buffer_write_data;
logic                   jpeg_buffer_write_enable;

jenc_cdc jenc_cdc (
    .reset_pixel_n_in   (reset_pixel_n_in & ~(capture_in_progress_cdc[2:1] == 2'b01)),
    .reset_spi_n_in     (reset_spi_n_in & ~(capture_in_progress_state==0 & frame_valid_cdc[1] == 0 & capture_flag)),
    .*
);

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
    .line_valid         (capture_in_progress_cdc[1] & debayered_line_valid),
    .frame_valid        (capture_in_progress_cdc[1] & debayered_frame_valid),
    .red_data           (debayered_red_data),
    .green_data         (debayered_green_data),
    .blue_data          (debayered_blue_data),
    .reset_pixel_n_in   (reset_pixel_n_in & ~(capture_in_progress_cdc[2:1] == 2'b01)),
    .reset_spi_n_in     (reset_spi_n_in & ~(capture_in_progress_state==0 & frame_valid_cdc[1] == 0 & capture_flag)),
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
    .reset_n_in(reset_spi_n_in & ~(capture_in_progress_state==0 & frame_valid_cdc[1] == 0 & capture_flag)),
    .write_address_in(buffer_address),
    .read_address_in(buffer_read_address),
    .write_data_in(buffer_write_data),
    .read_data_out(buffer_read_data),
    .write_enable_in(buffer_write_enable)
);

`endif

endmodule
