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

module camera #(SIM=0) (
    input logic clock_36MHz,
    input logic clock_72MHz,
    input logic global_reset_n,
    input logic reset_n_clock_36MHz,
    input logic reset_n_clock_96MHz,

    inout wire mipi_clock_p,
    inout wire mipi_clock_n,
    inout wire mipi_data_p,
    inout wire mipi_data_n,

    input logic camera_ram_read_enable,
    input logic [15:0] camera_ram_read_address,
    output logic [31:0] camera_ram_read_data,
    input logic capture
);

logic payload_en, sp_en, sp_en_d, lp_av_en, lp_en, lp_av_en_d /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] payload /* synthesis syn_keep=1 nomerge=""*/;
logic [15:0] word_count /* synthesis syn_keep=1 nomerge=""*/;
logic [5:0] datatype;

csi2_receiver_ip csi2_receiver_ip (
    .clk_byte_o( ),
    .clk_byte_hs_o(byte_clk_hs),
    .clk_byte_fr_i(byte_clk_hs),
    .reset_n_i(global_reset_n),
    .reset_byte_fr_n_i(reset_n_clock_96MHz),
    .clk_p_io(mipi_clock_p),
    .clk_n_io(mipi_clock_n),
    .d_p_io(mipi_data_p),
    .d_n_io(mipi_data_n),
    .payload_en_o(payload_en),
    .payload_o(payload),
    .tx_rdy_i(1'b1),
    .pd_dphy_i(~global_reset_n),
    .dt_o(datatype),
    .wc_o(word_count),
    .ref_dt_i(6'h2B), // RAW10 packet code
    .sp_en_o(sp_en),
    .lp_en_o(lp_en),
    .lp_av_en_o(lp_av_en)
);

always @(posedge byte_clk_hs or negedge reset_n_clock_96MHz) begin
    if (!reset_n_clock_96MHz) begin
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
always @(posedge byte_clk_hs or negedge reset_n_clock_96MHz) begin
    if (!reset_n_clock_96MHz) begin
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

logic [9:0] pixel_data /* synthesis syn_keep=1 nomerge=""*/;
logic frame_valid, line_valid /* synthesis syn_keep=1 nomerge=""*/;
byte_to_pixel_ip byte_to_pixel_ip (
    .reset_byte_n_i(reset_n_clock_96MHz),
    .clk_byte_i(byte_clk_hs),
    .sp_en_i(sp_en_d),
    .dt_i(datatype),
    .lp_av_en_i(lp_av_en_d),
    .payload_en_i(payload_en_3d),
    .payload_i(payload_3d),
    .wc_i(word_count),
    .reset_pixel_n_i(reset_n_clock_36MHz),
    .clk_pixel_i(clock_36MHz),
    .fv_o(frame_valid),
    .lv_o(line_valid),
    .pd_o(pixel_data)
);


logic [29:0] rgb30 /* synthesis syn_keep=1 nomerge=""*/;
logic [9:0] rgb10 /* synthesis syn_keep=1 nomerge=""*/;
logic [7:0] rgb8 /* synthesis syn_keep=1 nomerge=""*/;
logic [3:0] gray4 /* synthesis syn_keep=1 nomerge=""*/;
logic camera_fifo_write_enable /* synthesis syn_keep=1 nomerge=""*/;
logic debayer_frame_valid /* synthesis syn_keep=1 nomerge=""*/;

generate
    if(SIM)
        debayer #(.HSIZE('d1280)) debayer_inst (
            .clock_72MHz(clock_72MHz),
            .clock_36MHz(clock_36MHz),
            .reset_n(reset_n_clock_36MHz),
            .x_offset(10'd0),
            .y_offset(9'd0),
            .x_size(10'd1280),
            .y_size(9'd4),
            .pixel_data(pixel_data),
            .line_valid(line_valid),
            .frame_valid(frame_valid),
            .rgb10(rgb10),
            .rgb8(rgb8),
            .gray4(gray4),
            .camera_fifo_write_enable(camera_fifo_write_enable),
            .frame_valid_o(debayer_frame_valid)
        );
    
    else
        debayer debayer_inst (
            .clock_72MHz(clock_72MHz),
            .clock_36MHz(clock_36MHz),
            .reset_n(reset_n_clock_36MHz),
            .x_offset(10'd440),
            .y_offset(9'd200),
            .x_size(10'd400),
            .y_size(9'd400),
            .pixel_data(pixel_data),
            .line_valid(line_valid),
            .frame_valid(frame_valid),
            .rgb10(rgb10),
            .rgb8(rgb8),
            .gray4(gray4),
            .camera_fifo_write_enable(camera_fifo_write_enable),
            .frame_valid_o(debayer_frame_valid)
        ) /* synthesis syn_keep=1 */;
endgenerate

logic [15:0] camera_ram_write_address /* synthesis syn_keep=1 nomerge=""*/;
logic camera_ram_write_enable /* synthesis syn_keep=1 nomerge=""*/;
logic [31:0] camera_ram_write_data /* synthesis syn_keep=1 nomerge=""*/;

camera_fifo camera_fifo (
    .clock(clock_72MHz),
    .reset_n(reset_n_clock_36MHz),
    .rgb10(rgb10),
    .rgb8(rgb8),
    .gray4(gray4),
    .pixel_width(4'd8),
    .write_enable(camera_fifo_write_enable),
    .frame_valid(debayer_frame_valid),
    .write_enable_frame_buffer(camera_ram_write_enable),
    .pixel_data_to_ram(camera_ram_write_data),
    .ram_address(camera_ram_write_address)
);

logic capture_state = 0;
logic [1:0] debayer_frame_valid_edge = 0;
logic [1:0] frame_count = 0;
always_ff @(posedge clock_72MHz) begin : capture_control
    debayer_frame_valid_edge <= {debayer_frame_valid_edge[0], debayer_frame_valid};
    if (capture == 1) begin
        capture_state <= 1;
        if (debayer_frame_valid == 0) // frame not currently active, capture next frame
            frame_count <= 'd1;
        else // frame currently active, overwrite this frame and capture next
            frame_count <= 'd0; 
    end
    else if (capture_state == 1 && debayer_frame_valid_edge == 2'b10) begin
        if (frame_count == 0) frame_count <= frame_count+1;
        else capture_state <= 0;
    end
end

generate
    if(SIM)
        camera_ram_inferred camera_ram (
            .clk(clock_72MHz),
            .rst_n(reset_n_clock_36MHz),
            .wr_addr(camera_ram_write_address),
            .rd_addr(camera_ram_read_address),
            .wr_data(camera_ram_write_data),
            .rd_data(camera_ram_read_data),
            .wr_en(camera_ram_write_enable & capture_state),
            .rd_en(camera_ram_read_enable)
        );
    
    else
        camera_ram_ip camera_ram (
            .clk_i(clock_72MHz),
            .dps_i(1'b0),
            .rst_i(~reset_n_clock_36MHz),
            .wr_clk_en_i(reset_n_clock_36MHz),
            .rd_clk_en_i(reset_n_clock_36MHz),
            .wr_en_i(camera_ram_write_enable & capture_state),
            .wr_data_i(camera_ram_write_data),
            .wr_addr_i(camera_ram_write_address),
            .rd_addr_i(camera_ram_read_address),
            .rd_data_o(camera_ram_read_data),
            .lramready_o( ),
            .rd_datavalid_o( )
        )/* synthesis syn_keep=1 */;
endgenerate


endmodule