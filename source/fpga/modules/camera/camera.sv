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
// `include "modules/camera/packing_fifo.sv"
`endif

module camera (
    input logic clock_spi_in, // 72MHz
    input logic reset_spi_n_in,

    input logic clock_pixel_in, // 36MHz
    input logic reset_pixel_n_in,

    inout wire mipi_clock_p_out,
    inout wire mipi_clock_n_out,
    inout wire mipi_data_p_out,
    inout wire mipi_data_n_out,

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
parameter CAPTURE_X_RESOLUTION = 200;
parameter CAPTURE_Y_RESOLUTION = 200;
logic [15:0] capture_size = CAPTURE_X_RESOLUTION * CAPTURE_Y_RESOLUTION;
logic [15:0] bytes_read;

logic [15:0] bytes_remaining;
assign bytes_remaining = capture_size - bytes_read;

logic [13:0] buffer_read_address;
logic [7:0] buffer_read_byte_data;

logic [1:0] operand_valid_in_edge_monitor;

// Handle op-codes as they come in
always_ff @(posedge clock_spi_in) begin
    
    if (reset_spi_n_in == 0) begin
        response_out <= 0;
        response_valid_out <= 0;
        capture_flag <= 0;
        bytes_read <= 0;
        buffer_read_address <= 0;
        operand_valid_in_edge_monitor <= 0;
    end

    else begin

        operand_valid_in_edge_monitor <= {operand_valid_in_edge_monitor[0], 
                                          operand_valid_in};

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
                    response_out <= buffer_read_byte_data;
                    response_valid_out <= 1;

                    if (operand_valid_in_edge_monitor == 'b01) begin
                        bytes_read <= bytes_read + 1;
                        buffer_read_address <= bytes_read[15:2];
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
logic [1:0] debayer_frame_valid_edge_monitor;
logic debayer_frame_valid;

always_ff @(posedge clock_spi_in) begin
    if (reset_spi_n_in == 0) begin
        capture_in_progress_flag <= 0;
        debayer_frame_valid_edge_monitor <= 0;
    end

    else begin
        debayer_frame_valid_edge_monitor <= {debayer_frame_valid_edge_monitor[0],
                                             debayer_frame_valid};

        if (capture_flag && debayer_frame_valid_edge_monitor == 'b01) begin
            capture_in_progress_flag <= 1;
        end

        if (debayer_frame_valid_edge_monitor == 'b10) begin
            capture_in_progress_flag <= 0;
        end
    end
end

// Read data logic
logic [31:0] buffer_read_data;

always_comb begin
    case (bytes_read[1:0])
        'b00: buffer_read_byte_data = buffer_read_data[31:24];
        'b01: buffer_read_byte_data = buffer_read_data[23:16];
        'b10: buffer_read_byte_data = buffer_read_data[15:8];
        'b11: buffer_read_byte_data = buffer_read_data[7:0];
    endcase
end

`ifdef RADIANT

// logic payload_en, sp_en, sp_en_d, lp_av_en, lp_en, lp_av_en_d /* synthesis syn_keep=1 nomerge=""*/;
// logic [7:0] payload /* synthesis syn_keep=1 nomerge=""*/;
// logic [15:0] word_count /* synthesis syn_keep=1 nomerge=""*/;
// logic [5:0] datatype;

// logic reset_n_clock_byte;

// reset_sync reset_sync_clock_byte (
//     .clock_in(byte_clk_hs),
//     .async_reset_n_in(global_reset_n),
//     .sync_reset_n_out(reset_n_clock_byte)
// );

// csi2_receiver_ip csi2_receiver_ip (
//     .clk_byte_o( ),
//     .clk_byte_hs_o(byte_clk_hs),
//     .clk_byte_fr_i(byte_clk_hs),
//     .reset_n_i(global_reset_n),
//     .reset_byte_fr_n_i(reset_n_clock_byte),
//     .clk_p_io(mipi_clock_p),
//     .clk_n_io(mipi_clock_n),
//     .d_p_io(mipi_data_p),
//     .d_n_io(mipi_data_n),
//     .payload_en_o(payload_en),
//     .payload_o(payload),
//     .tx_rdy_i(1'b1),
//     .pd_dphy_i(~global_reset_n),
//     .dt_o(datatype),
//     .wc_o(word_count),
//     .ref_dt_i(6'h2B), // RAW10 packet code
//     .sp_en_o(sp_en),
//     .lp_en_o(lp_en),
//     .lp_av_en_o(lp_av_en)
// );

// always @(posedge byte_clk_hs or negedge reset_n_clock_byte) begin
//     if (!reset_n_clock_byte) begin
//         lp_av_en_d <= 0;
//         sp_en_d <= 0;
//     end
//     else begin
//         lp_av_en_d <= lp_av_en;
//         sp_en_d <= sp_en;
//     end
// end

// logic payload_en_1d, payload_en_2d, payload_en_3d /* synthesis syn_keep=1 nomerge=""*/;
// logic [7:0] payload_1d /* synthesis syn_keep=1 nomerge=""*/;
// logic [7:0] payload_2d /* synthesis syn_keep=1 nomerge=""*/;
// logic [7:0] payload_3d /* synthesis syn_keep=1 nomerge=""*/;
// always @(posedge byte_clk_hs or negedge reset_n_clock_byte) begin
//     if (!reset_n_clock_byte) begin
//         payload_en_1d <= 0;
//         payload_en_2d <= 0;
//         payload_en_3d <= 0;

//         payload_1d <= 0;
//         payload_2d <= 0;
//         payload_3d <= 0;
//     end
//     else begin
//         payload_en_1d <= payload_en;
//         payload_en_2d <= payload_en_1d;
//         payload_en_3d <= payload_en_2d;

//         payload_1d <= payload;
//         payload_2d <= payload_1d;
//         payload_3d <= payload_2d;
//     end
// end

// logic [9:0] pixel_data /* synthesis syn_keep=1 nomerge=""*/;
// logic frame_valid /* synthesis syn_keep=1 nomerge=""*/;
// logic line_valid /* synthesis syn_keep=1 nomerge=""*/;

// byte_to_pixel_ip byte_to_pixel_ip (
//     .reset_byte_n_i(reset_n_clock_byte),
//     .clk_byte_i(byte_clk_hs),
//     .sp_en_i(sp_en_d),
//     .dt_i(datatype),
//     .lp_av_en_i(lp_av_en_d),
//     .payload_en_i(payload_en_3d),
//     .payload_i(payload_3d),
//     .wc_i(word_count),
//     .reset_pixel_n_i(reset_n_clock),
//     .clk_pixel_i(clock),
//     .fv_o(frame_valid),
//     .lv_o(line_valid),
//     .pd_o(pixel_data)
// );

// logic [29:0] rgb30 /* synthesis syn_keep=1 nomerge=""*/;
// logic [9:0] rgb10 /* synthesis syn_keep=1 nomerge=""*/;
// logic [7:0] rgb8 /* synthesis syn_keep=1 nomerge=""*/;
// logic [3:0] gray4 /* synthesis syn_keep=1 nomerge=""*/;
// logic camera_fifo_write_enable /* synthesis syn_keep=1 nomerge=""*/;
// logic debayer_frame_valid /* synthesis syn_keep=1 nomerge=""*/;

// debayer debayer_inst (
//     .clock_2x(clock_2x),
//     .clock(clock),
//     .reset_n(reset_n_clock),
//     .x_offset(10'd440),
//     .y_offset(9'd200),
//     .x_size(CAPTURE_X_RESOLUTION * 2),
//     .y_size(CAPTURE_Y_RESOLUTION * 2),
//     .pixel_data(pixel_data),
//     .line_valid(line_valid),
//     .frame_valid(frame_valid),
//     .rgb10(rgb10),
//     .rgb8(rgb8),
//     .gray4(gray4),
//     .camera_fifo_write_enable(camera_fifo_write_enable),
//     .frame_valid_o(debayer_frame_valid)
// ) /* synthesis syn_keep=1 */;

// logic [15:0] camera_ram_write_address /* synthesis syn_keep=1 nomerge=""*/;
logic camera_ram_write_enable /* synthesis syn_keep=1 nomerge=""*/;
// logic [31:0] camera_ram_write_data /* synthesis syn_keep=1 nomerge=""*/;

// packing_fifo packing_fifo (
//     .clock(clock_2x),
//     .reset_n(reset_n_clock),
//     .rgb10(rgb10),
//     .rgb8(rgb8),
//     .gray4(gray4),
//     .pixel_width(4'd8),
//     .write_enable(camera_fifo_write_enable),
//     .frame_valid(debayer_frame_valid),
//     .write_enable_frame_buffer(camera_ram_write_enable),
//     .pixel_data_to_ram(camera_ram_write_data),
//     .ram_address(camera_ram_write_address)
// );

PDPSC512K #(
    .OUTREG("NO_REG"),
    .GSR("DISABLED"),
    .RESETMODE("SYNC"),
    .ASYNC_RESET_RELEASE("SYNC"),
    .ECC_BYTE_SEL("BYTE_EN")
) camera_buffer (
    .DI(),
    .ADW(),
    .ADR(buffer_read_address),
    .CLK(clock_spi_in),
    .CEW('b1),
    .CER('b1),
    .WE(camera_ram_write_enable & capture_in_progress_flag),
    .CSW('b1),
    .CSR('b1),
    .RSTR('b0),
    .BYTEEN_N('b0000),
    .DO(buffer_read_data)
);
`endif


endmodule