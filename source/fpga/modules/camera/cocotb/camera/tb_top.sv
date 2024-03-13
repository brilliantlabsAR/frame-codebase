`timescale 1ps/1ps
module tb_top (
    input logic global_reset_n,
    input logic clock_camera_pixel,
    input logic clock_camera_sync,

    // Image to MIPI
    input logic pixel_lv,
    input logic pixel_fv,
    input logic [9:0] pixel_data,

    input logic spi_clock_in, 
    input logic spi_data_in, 
    output logic spi_data_out, 
    input logic spi_select_in
);

`ifdef COCOTB_MODELSIM
`include "dumper.vh"
GSR GSR_INST (.GSR_N('1), .CLK('0));
`endif //COCOTB_MODELSIM

`ifndef NO_MIPI_IP_SIM

logic reset_n;
logic reset_camera_pixel_n;
logic reset_camera_byte_n;
logic reset_camera_sync_n;

logic clock_camera_byte;
logic pll_dphy_locked;

assign reset_n = global_reset_n && pll_dphy_locked;

reset_sync reset_sync_clock_camera_pixel (
    .clock_in(clock_camera_pixel),
    .async_reset_n_in(reset_n),
    .sync_reset_n_out(reset_camera_pixel_n)
);

reset_sync reset_sync_clock_camera_sync (
    .clock_in(clock_camera_sync),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(reset_camera_sync_n)
);

reset_sync reset_sync_clock_camera_byte (
    .clock_in(clock_camera_byte),
    .async_reset_n_in(reset_n),
    .sync_reset_n_out(reset_camera_byte_n)
);

parameter IMAGE_X_SIZE = 1288;
parameter IMAGE_Y_SIZE = 768;
parameter WORD_COUNT = IMAGE_X_SIZE * 10 / 8; // RAW10 in bytes

logic c2d_ready, tx_d_hs_en, byte_data_en;
logic [5:0] dt;
logic [7:0] byte_data;
logic r_sp_en;
logic r_lp_en;
logic [5:0] r_dt;
logic [15:0] r_tx_wc;
logic r_byte_data_en_1d, r_byte_data_en_2d, r_byte_data_en_3d;
logic [7:0] r_byte_data_1d, r_byte_data_2d, r_byte_data_3d;
logic [1:0] vc;
assign vc = 2'b00;
logic fv_start, fv_end, lv_start, lv_end;

always @(posedge clock_camera_byte or negedge reset_camera_byte_n) begin
    if (~reset_camera_byte_n) begin
        r_sp_en <= 0;
        r_lp_en <= 0;
    end
    else begin
        r_sp_en <= fv_start | fv_end;
        r_lp_en <= lv_start;
    end
end

always @(posedge clock_camera_byte or negedge reset_camera_byte_n) begin
    if (~reset_camera_byte_n) begin
        r_dt <= 0;
    end
    else if (fv_start) begin
        r_dt <= 6'h00;
    end
    else if (fv_end) begin
        r_dt <= 6'h01;
    end
    else if (lv_start)
        r_dt <= 6'h2b;
end

always @(posedge clock_camera_byte or negedge reset_camera_byte_n) begin
    if (~reset_camera_byte_n) begin
        r_tx_wc <= 0;
    end
    else if (fv_start) begin
        r_tx_wc <= 0;
    end
    else if (fv_end) begin
        r_tx_wc <= 0;
    end
    else if (lv_start) begin
        r_tx_wc <= WORD_COUNT;
    end
end

logic txfr_en, txfr_en_1d;
always @(posedge clock_camera_byte or negedge reset_camera_byte_n) begin
    if (~reset_camera_byte_n) begin
        r_byte_data_en_1d <= 0;
        r_byte_data_en_2d <= 0;
        r_byte_data_en_3d <= 0;

        r_byte_data_1d <= 0;
        r_byte_data_2d <= 0;
        r_byte_data_3d <= 0;
        txfr_en_1d     <= 0;
    end
    else begin
        r_byte_data_en_1d <= byte_data_en;
        r_byte_data_en_2d <= r_byte_data_en_1d;
        r_byte_data_en_3d <= r_byte_data_en_2d;

        r_byte_data_1d <= byte_data;
        r_byte_data_2d <= r_byte_data_1d;
        r_byte_data_3d <= r_byte_data_2d;
        txfr_en_1d     <= txfr_en;
    end
end

pixel_to_byte_ip pix2byte_inst (
        .rst_n_i(reset_camera_pixel_n),
        .pix_clk_i(clock_camera_pixel),
        .byte_clk_i(clock_camera_byte),
        .fv_i(pixel_fv),
        .lv_i(pixel_lv),
        .dvalid_i(1'b1),
        .pix_data0_i(pixel_data),
        .c2d_ready_i(c2d_ready),
        .txfr_en_i(txfr_en_1d),
        .fv_start_o(fv_start),
        .fv_end_o(fv_end),
        .lv_start_o(lv_start),
        .lv_end_o(lv_end),
        .txfr_req_o(tx_d_hs_en),
        .byte_en_o(byte_data_en),
        .byte_data_o(byte_data),
        .data_type_o(dt)
);	

logic packet_recv_ready;
wire mipi_clock_p;
wire mipi_clock_n;
wire mipi_data_p;
wire mipi_data_n;

csi2_transmitter_ip csi_tx_inst (
        .ref_clk_i(clock_camera_sync),
        .reset_n_i(reset_camera_sync_n),
        .usrstdby_i(1'b0),
        .pd_dphy_i(1'b0),
        .byte_or_pkt_data_i(r_byte_data_3d),
        .byte_or_pkt_data_en_i(r_byte_data_en_3d),
        .ready_o(),
        .vc_i(vc),
        .dt_i(r_dt),
        .wc_i(r_tx_wc),
        .clk_hs_en_i(tx_d_hs_en),
        .d_hs_en_i(tx_d_hs_en),
        .d_hs_rdy_o(txfr_en),
        .byte_clk_o(clock_camera_byte),
        .c2d_ready_o(c2d_ready),
        .phdr_xfr_done_o( ),
        .ld_pyld_o(packet_recv_ready),
        .clk_p_io(mipi_clock_p),
        .clk_n_io(mipi_clock_n),
        .d_p_io(mipi_data_p),
        .d_n_io(mipi_data_n),
        .sp_en_i(r_sp_en),
        .lp_en_i(r_lp_en),
        .pll_lock_o(pll_dphy_locked)
);
`endif

top dut (
    .spi_select_in(spi_select_in),
    .spi_clock_in(spi_clock_in),
    .spi_data_in(spi_data_in),
    .spi_data_out(spi_data_out),

    // .display_clock_out(display_clock_out),
    // .display_hsync_out(display_hsync_out),
    // .display_vsync_out(display_vsync_out),
    // .display_y0_out(display_y0_out),
    // .display_y1_out(display_y1_out),
    // .display_y2_out(display_y2_out),
    // .display_y3_out(display_y3_out),
    // .display_cr0_out(display_cr0_out),
    // .display_cr1_out(display_cr1_out),
    // .display_cr2_out(display_cr2_out),
    // .display_cb0_out(display_cb0_out),
    // .display_cb1_out(display_cb1_out),
    // .display_cb2_out(display_cb2_out),

    `ifdef NO_MIPI_IP_SIM
    .byte_to_pixel_frame_valid(pixel_fv),
    .byte_to_pixel_line_valid(pixel_lv),
    .byte_to_pixel_data(pixel_data),
    .clock_camera_pixel(clock_camera_pixel)
    `else
    .mipi_clock_p_in(mipi_clock_p),
    .mipi_clock_n_in(mipi_clock_n),
    .mipi_data_p_in(mipi_data_p),
    .mipi_data_n_in(mipi_data_n)
    `endif //NO_MIPI_IP_SIM
);

endmodule
