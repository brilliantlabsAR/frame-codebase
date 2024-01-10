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
`endif

module camera #(
    CAPTURE_X_RESOLUTION = 200,
    CAPTURE_Y_RESOLUTION = 200,
    CAPTURE_X_OFFSET = 220,
    CAPTURE_Y_OFFSET = 100,
    IMAGE_X_SIZE = 1288
) (
    input logic global_reset_n_in,
    
    input logic clock_spi_in, // 72MHz
    input logic reset_spi_n_in,

    input logic clock_pixel_in, // 36MHz
    input logic reset_pixel_n_in,

    input logic clock_sync_in, // 96MHz

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

logic payload_en /* synthesis syn_keep=1 nomerge=""*/;
logic sp_en /* synthesis syn_keep=1 nomerge=""*/;
logic sp_en_d /* synthesis syn_keep=1 nomerge=""*/;
logic lp_av_en /* synthesis syn_keep=1 nomerge=""*/;
logic lp_en /* synthesis syn_keep=1 nomerge=""*/;
logic lp_av_en_d /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] payload /* synthesis syn_keep=1 nomerge=""*/;
logic [15:0] word_count /* synthesis syn_keep=1 nomerge=""*/;
logic [5:0] datatype;

logic clock_byte;
logic reset_sync_n;

reset_sync reset_sync_clock_sync (
    .clock_in(clock_sync_in),
    .async_reset_n_in(global_reset_n_in),
    .sync_reset_n_out(reset_sync_n)
);

csi2_receiver_ip csi2_receiver_ip (
    .clk_byte_o( ),
    .clk_byte_hs_o(clock_byte),
    .clk_byte_fr_i(clock_byte),
    .reset_n_i(global_reset_n_in), // async reset
    .reset_byte_fr_n_i(reset_sync_n),
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
    .lp_en_o(lp_en),
    .lp_av_en_o(lp_av_en)
);

always @(posedge clock_byte or negedge reset_sync_n) begin
    if (!reset_sync_n) begin
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
always @(posedge clock_byte or negedge reset_sync_n) begin
    if (!reset_sync_n) begin
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
    .reset_byte_n_i(reset_sync_n),
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

logic [9:0] rgb10 /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] rgb8 /* synthesis syn_keep=1 nomerge=""*/;
logic [3:0] gray4 /* synthesis syn_keep=1 nomerge=""*/;
logic fifo_write_enable /* synthesis syn_keep=1 nomerge=""*/;

debayer # (
    .IMAGE_X_SIZE(IMAGE_X_SIZE)
) debayer (
    .clock_2x_in(clock_spi_in),
    .clock_in(clock_pixel_in),
    .reset_n_in(reset_pixel_n_in),
    .x_offset_in(CAPTURE_X_OFFSET * 2),
    .y_offset_in(CAPTURE_Y_OFFSET * 2),
    .x_size_in(CAPTURE_X_RESOLUTION * 2),
    .y_size_in(CAPTURE_Y_RESOLUTION * 2),
    .pixel_data_in(pixel_data),
    .line_valid_in(line_valid),
    .frame_valid_in(frame_valid),
    .rgb10_out(rgb10),
    .rgb8_out(rgb8),
    .gray4_out(gray4),
    .fifo_write_enable_out(fifo_write_enable),
    .frame_valid_out(debayer_frame_valid)
) /* synthesis syn_keep=1 */;

logic buffer_write_enable /* synthesis syn_keep=1 nomerge=""*/;
logic [13:0] buffer_write_address /* synthesis syn_keep=1 nomerge=""*/;
logic [31:0] buffer_write_data /* synthesis syn_keep=1 nomerge=""*/;

fifo fifo (
    .clock_in(clock_spi_in),
    .reset_n_in(reset_spi_n_in),
    .rgb10_in(rgb10),
    .rgb8_in(rgb8),
    .gray4_in(gray4),
    .pixel_width_in(4'd8),
    .write_enable_in(fifo_write_enable),
    .frame_valid_in(debayer_frame_valid),
    .write_enable_out(buffer_write_enable),
    .pixel_data_out(buffer_write_data),
    .address_out(buffer_write_address)
);

`ifndef SIM
PDPSC512K #(
    .OUTREG("NO_REG"),
    .GSR("DISABLED"),
    .RESETMODE("SYNC"),
    .ASYNC_RESET_RELEASE("SYNC"),
    .ECC_BYTE_SEL("BYTE_EN")
) camera_buffer (
    .DI(buffer_write_data),
    .ADW(buffer_write_address),
    .ADR(buffer_read_address),
    .CLK(clock_spi_in),
    .CEW('b1),
    .CER('b1),
    .WE(buffer_write_enable & capture_in_progress_flag),
    .CSW('b1),
    .CSR('b1),
    .RSTR('b0),
    .BYTEEN_N('b0000),
    .DO(buffer_read_data)
);
`else
camera_ram_inferred camera_buffer (
    .clk(clock_spi_in),
    .rst_n(reset_spi_n_in),
    .wr_addr(buffer_write_address),
    .rd_addr(buffer_read_address),
    .wr_data(buffer_write_data),
    .rd_data(buffer_read_data),
    .wr_en(buffer_write_enable & capture_in_progress_flag),
    .rd_en(1'b1)
);
`endif

`endif


endmodule