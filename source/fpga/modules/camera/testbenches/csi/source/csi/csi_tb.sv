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

`timescale 1ns/1ns

module csi_tb;

// Clocking
logic osc_clock;

logic tx_pixel_clock;
logic tx_byte_clock;
logic tx_sync_clock;
logic pll_locked;

OSCA #(
    .HF_CLK_DIV("24"),
    .HF_OSC_EN("ENABLED"),
    .LF_OUTPUT_EN("DISABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(osc_clock) // f = (450 / (HF_CLK_DIV + 1)) ± 7%
);

pll_sim_ip tx_pll (
    .clki_i(osc_clock),
    .clkop_o(tx_pixel_clock),
    .clkos_o( ),
    .clkos2_o(tx_sync_clock),
    .lock_o(pll_locked)
);

// Reset
reg CLK_GSR  = 0;
reg USER_GSR = 1;
GSR GSR_INST (.GSR_N(USER_GSR), .CLK(CLK_GSR));

logic reset_n;
logic global_reset_n;
logic tx_pixel_reset_n;
logic tx_byte_reset_n;
logic tx_sync_reset_n;

reset_global reset_global (
    .clock_in(osc_clock),
    .pll_locked_in(pll_locked),
    .global_reset_n_out(global_reset_n)
);

logic pll_dphy_locked;

assign reset_n = global_reset_n && pll_dphy_locked;

reset_sync reset_sync_tx_pixel_clock (
    .clock_in(tx_pixel_clock),
    .async_reset_n_in(reset_n),
    .sync_reset_n_out(tx_pixel_reset_n)
);

reset_sync reset_sync_tx_sync_clock (
    .clock_in(tx_sync_clock),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(tx_sync_reset_n)
);

reset_sync reset_sync_tx_byte_clock (
    .clock_in(tx_byte_clock),
    .async_reset_n_in(reset_n),
    .sync_reset_n_out(tx_byte_reset_n)
);

// Image to MIPI
logic pixel_lv;
logic pixel_fv;
logic pixel_en;
logic [9:0] pixel_data;


parameter IMAGE_X_SIZE = 76;
parameter IMAGE_Y_SIZE = 76;
parameter WORD_COUNT = IMAGE_X_SIZE * 10 / 8; // RAW10 in bytes

image_gen tx_image_gen (
    .reset_n_in (tx_pixel_reset_n),
    .pixel_clock_in (tx_pixel_clock),
    .frame_valid (pixel_fv),
    .pixel_data_out (pixel_data),
    .line_valid (pixel_lv) 
);

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

always @(posedge tx_byte_clock or negedge tx_byte_reset_n) begin
    if (~tx_byte_reset_n) begin
        r_sp_en <= 0;
        r_lp_en <= 0;
    end
    else begin
        r_sp_en <= fv_start | fv_end;
        r_lp_en <= lv_start;
    end
end

always @(posedge tx_byte_clock or negedge tx_byte_reset_n) begin
    if (~tx_byte_reset_n) begin
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

always @(posedge tx_byte_clock or negedge tx_byte_reset_n) begin
    if (~tx_byte_reset_n) begin
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
always @(posedge tx_byte_clock or negedge tx_byte_reset_n) begin
    if (~tx_byte_reset_n) begin
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
        .rst_n_i(tx_pixel_reset_n),
        .pix_clk_i(tx_pixel_clock),
        .byte_clk_i(tx_byte_clock),
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
        .ref_clk_i(tx_sync_clock & tx_sync_reset_n),
        .reset_n_i(tx_sync_reset_n),
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
        .byte_clk_o(tx_byte_clock),
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

// RX section

logic rx_pixel_clock;
logic rx_pll_locked;

pll_sim_ip rx_pll (
    .clki_i(osc_clock),
    .clkop_o(rx_pixel_clock),
    .clkos_o( ),
    .clkos2_o(),
    .lock_o(rx_pll_locked)
);

// Reset
logic global_reset_n;
logic rx_pixel_reset_n;

reset_sync reset_sync_rx_pixel_clock (
    .clock_in(rx_pixel_clock),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(rx_pixel_reset_n)
);

logic rx_byte_clock;
logic rx_byte_reset_n;

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

reset_sync reset_sync_rx_byte_clock (
    .clock_in(rx_byte_clock),
    .async_reset_n_in(global_reset_n),
    .sync_reset_n_out(rx_byte_reset_n)
);

csi2_receiver_ip csi2_receiver_ip (
    .clk_byte_o(),
    .clk_byte_hs_o(rx_byte_clock),
    .clk_byte_fr_i(rx_byte_clock),
    .reset_n_i(global_reset_n),
    .reset_byte_fr_n_i(rx_byte_reset_n),
    .clk_p_io(mipi_clock_p),
    .clk_n_io(mipi_clock_n),
    .d_p_io(mipi_data_p),
    .d_n_io(mipi_data_n),
    .payload_en_o(mipi_payload_enable_metastable),
    .payload_o(mipi_payload_metastable),
    .tx_rdy_i(1'b1),
    .pd_dphy_i(~global_reset_n),
    .dt_o(mipi_datatype),
    .wc_o(mipi_word_count),
    .ref_dt_i(6'h2B),
    .sp_en_o(mipi_sp_enable_metastable),
    .lp_en_o(),
    .lp_av_en_o(mipi_lp_av_enable_metastable)
);

always @(posedge rx_byte_clock or negedge rx_byte_reset_n) begin

    if (!rx_byte_reset_n) begin
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
    .reset_byte_n_i(rx_byte_reset_n),
    .clk_byte_i(rx_byte_clock),
    .sp_en_i(mipi_sp_enable),
    .dt_i(mipi_datatype),
    .lp_av_en_i(mipi_lp_av_enable),
    .payload_en_i(mipi_payload_enable),
    .payload_i(mipi_payload),
    .wc_i(mipi_word_count),
    .reset_pixel_n_i(rx_pixel_reset_n),
    .clk_pixel_i(rx_pixel_clock),
    .fv_o(byte_to_pixel_frame_valid),
    .lv_o(byte_to_pixel_line_valid),
    .pd_o(byte_to_pixel_data)
);

logic [7:0] tx_frame_count;
logic [7:0] rx_frame_count;
initial tx_frame_count = 0;
initial rx_frame_count = 0;
always_ff @(negedge pixel_fv) begin
    if (!pixel_fv) begin
        tx_frame_count <= tx_frame_count + 1;
        $display("Sent frame %0d", tx_frame_count);
    end
end

logic pixel_lv_ref;
logic pixel_fv_ref;
logic [9:0] pixel_data_ref;
logic pixel_en_ref;

image_gen rx_image_gen (
    .reset_n_in (pixel_en_ref),
    .pixel_clock_in (rx_pixel_clock),
    .frame_valid (pixel_fv_ref),
    .pixel_data_out (pixel_data_ref),
    .line_valid (pixel_lv_ref) 
);

initial begin
    pixel_en_ref <= 0;
    #2117760;
    pixel_en_ref <= 1;
end

endmodule