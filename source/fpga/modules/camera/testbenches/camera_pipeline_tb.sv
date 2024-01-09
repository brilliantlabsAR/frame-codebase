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

`define RADIANT 1
`define SIM 1

`timescale 1 ps / 1 ps

module image_gen #(
    parameter HPIX = 32'd640,
    parameter VPIX = 32'd400,
    parameter VBP = 32'd2,
	parameter VFP = 32'd1,
	parameter HSYNC = 32'd44,
	parameter VSYNC = 32'd5
) (
    input logic clk,
    input logic reset_n,
    output logic lv,
    output logic fv,
    output logic [9:0] pix_data,
	output logic pix_en
);

logic [31:0] x;
logic [31:0] y;
logic [7:0] reset_counter;

localparam HFP = 2*HPIX;
localparam HBP = 2.2*HPIX;
// localparam HFP = 32'd2560;
// localparam HBP = 32'd2816;

always @(posedge clk) begin
    if(!reset_n) begin
        x <= 0;
		y <= 0;
		reset_counter <= 'd0;
    end else begin
		if (!reset_counter[4])
			reset_counter <= reset_counter +1;
		else begin 
			if ( (x >= (HSYNC+HBP)) && (x < (HSYNC+HBP+HPIX))  &&  (y >= (VSYNC+VBP)) && (y < (VSYNC+VBP+VPIX)) )
				pix_en <= 1;
			else 
				pix_en <= 0;
			
			if ( (x >= (HSYNC)) && (x < (HSYNC+HBP+HPIX+HFP))  &&  (y >= (VSYNC+VBP)) && (y < (VSYNC+VBP+VPIX)) )
				lv <= 1;
			else
				lv <= 0;

			if ( (y >= 0) && (y < VSYNC) )
				fv <= 0;
			else
				fv <= 1;
			
			if (x <= (HSYNC+HBP+HPIX+HFP))
				x <= x + 1;
			else begin
				x <= 0;
				if (y <= (VSYNC+VBP+VPIX+VFP))
					y <= y + 1;
				else 
					y <= 0;
			end

			if (x >= (HSYNC+HBP)) begin
				if ((x - (HSYNC+HBP)) < 'd320) begin
					if (y[0]) begin
						if (x[0]) pix_data <= 'h3ff; // r
						else pix_data <= 'h3ff; // g
					end
					else begin
						if (x[0]) pix_data <= 'h3ff; // g
						else pix_data <= 'h3ff; // b
					end
				end
				else if (((x - (HSYNC+HBP)) >= 'd320) & ((x - (HSYNC+HBP)) < 'd640)) begin
					if (y[0]) begin
						if (x[0]) pix_data <= 'h3ff; // r
						else pix_data <= 'h0; // g
					end
					else begin
						if (x[0]) pix_data <= 'h0; // g
						else pix_data <= 'h3ff; // b
					end
				end
				else if (((x - (HSYNC+HBP)) >= 'd640) & ((x - (HSYNC+HBP)) < 'd960)) begin
					if (y[0]) begin
						if (x[0]) pix_data <= 'h0; // r
						else pix_data <= 'h3ff; // g
					end
					else begin
						if (x[0]) pix_data <= 'h3ff; // g
						else pix_data <= 'h0; // b
					end
				end
				else if (((x - (HSYNC+HBP)) >= 'd960) & ((x - (HSYNC+HBP)) < 'd1280)) begin
					if (y[0]) begin
						if (x[0]) pix_data <= 'h3ff; // r
						else pix_data <= 'h3ff; // g
					end
					else begin
						if (x[0]) pix_data <= 'h0; // g
						else pix_data <= 'h0; // b
					end
				end
			end

			// else if (((x - (HSYNC+HBP)) >= 'd96) & ((x - (HSYNC+HBP)) < 'd128)) pix_data <= 'h60; 
			// else if (((x - (HSYNC+HBP)) >= 'd128) & ((x - (HSYNC+HBP)) < 'd160)) pix_data <= 'h80; 
			// else if (((x - (HSYNC+HBP)) >= 'd160) & ((x - (HSYNC+HBP)) < 'd192)) pix_data <= 'ha0; 
			// else if (((x - (HSYNC+HBP)) >= 'd192) & ((x - (HSYNC+HBP)) < 'd224)) pix_data <= 'hc0; 
			// else if (((x - (HSYNC+HBP)) >= 'd224) & ((x - (HSYNC+HBP)) < 'd256)) pix_data <= 'he0;
			// else if (((x - (HSYNC+HBP)) >= 'd256) & ((x - (HSYNC+HBP)) < 'd288)) pix_data <= 'h100;
			// else if (((x - (HSYNC+HBP)) >= 'd288) & ((x - (HSYNC+HBP)) < 'd312)) pix_data <= 'h12;
			// else if (((x - (HSYNC+HBP)) >= 'd312) & ((x - (HSYNC+HBP)) < 'd344)) pix_data <= 'h14;
			// else if (((x - (HSYNC+HBP)) >= 'd344) & ((x - (HSYNC+HBP)) < 'd376)) pix_data <= 'h16;
			// else pix_data <= 'h122;
		end
	end
end

endmodule

module camera_ram_inferred (
    input logic clk,
    input logic rst_n,
    input logic [15:0] wr_addr,
    input logic [15:0] rd_addr,
    input logic [31:0] wr_data,
    output logic [31:0] rd_data,
    input logic wr_en,
    input logic rd_en
);

reg [31:0] mem [0:16384];

always @(posedge clk) begin
    if (rst_n & wr_en) begin
        mem[wr_addr] <= wr_data;
    end
end

always @(posedge clk) begin
    if (rst_n & rd_en)
        rd_data <= mem[rd_addr];
end

endmodule

module camera_pipeline_tb;


// Clocking
logic clock_osc;

OSCA #(
    .HF_CLK_DIV("24"),
    .HF_OSC_EN("ENABLED"),
    .LF_OUTPUT_EN("DISABLED")
    ) osc (
    .HFOUTEN(1'b1),
    .HFCLKOUT(clock_osc) // f = (450 / (HF_CLK_DIV + 1)) ± 7%
);

logic clock_camera_pixel;
logic clock_camera_byte;
logic clock_spi;
logic pll_locked;

pll_ip pll_ip (
    .clki_i(clock_osc),
    .clkop_o(),
    .clkos_o(clock_camera_pixel),
    .clkos2_o(),
    .clkos3_o(clock_spi),
    .clkos4_o(clock_camera_sync),
    .lock_o(pll_locked)
);

// Reset
reg CLK_GSR  = 0;
reg USER_GSR = 1;
GSR GSR_INST (.GSR_N(USER_GSR), .CLK(CLK_GSR));

logic reset_n;
logic global_reset_n;
logic reset_camera_pixel_n;
logic reset_camera_byte_n;
logic reset_camera_sync_n;
logic reset_spi_n;

reset_global reset_global (
    .clock_in(clock_osc),
    .pll_locked_in(pll_locked),
    .global_reset_n_out(global_reset_n)
);

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

reset_sync reset_sync_clock_spi (
    .clock_in(clock_spi),
    .async_reset_n_in(reset_n),
    .sync_reset_n_out(reset_spi_n)
);

// Image to MIPI
logic pixel_lv;
logic pixel_fv;
logic pixel_en;
logic [9:0] pixel_data;


parameter H_SIZE = 50;
parameter V_SIZE = 2;
parameter WC = H_SIZE * 10 / 8;

image_gen #(
    .HPIX (H_SIZE),
    .VPIX (V_SIZE)
) i_image_gen (
    .reset_n (reset_camera_pixel_n),
    .clk  (clock_camera_pixel),
    .fv   (pixel_fv),
    .lv   (),
    .pix_data (pixel_data),
    .pix_en (pixel_lv) 
    // byte2pix expects pix_en to be on all the time, instead linevalid becomes enable
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
        r_tx_wc <= WC;
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
        .ref_clk_i(clock_camera_sync & reset_camera_sync_n),
        .reset_n_i(reset_camera_sync_n),
        .usrstdby_i(1'b0),
        .pd_dphy_i(1'b0),
        .byte_or_pkt_data_i(r_byte_data_3d),
        .byte_or_pkt_data_en_i(r_byte_data_en_3d),
        .ready_o(ready),
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

// Camera pipeline
camera camera (
    .global_reset_n_in(reset_n),

    .clock_pixel_in(clock_camera_pixel),
    .reset_pixel_n_in(reset_camera_pixel_n),

	.clock_spi_in(clock_spi),
    .reset_spi_n_in(reset_spi_n),
    
    .mipi_clock_p_in(mipi_clock_p),
    .mipi_clock_n_in(mipi_clock_n),
    .mipi_data_p_in(mipi_data_p),
    .mipi_data_n_in(mipi_data_n)
);

endmodule
