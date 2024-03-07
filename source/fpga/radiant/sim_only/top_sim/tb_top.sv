`timescale 1ps/1ps

module tb_top;

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
logic clock_camera_sync;
logic clock_spi;
logic pll_locked;

pll_sim_ip pll_sim_ip (
    .clki_i(clock_osc),
    .clkop_o(clock_camera_pixel),
    .clkos_o(clock_spi),
    .clkos2_o(clock_camera_sync),
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


parameter IMAGE_X_SIZE = 1288;
parameter IMAGE_Y_SIZE = 768;
parameter WORD_COUNT = IMAGE_X_SIZE * 10 / 8; // RAW10 in bytes

image_gen i_image_gen (
    .reset_n_in (reset_camera_pixel_n),
    .pixel_clock_in (clock_camera_pixel),
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
        .ref_clk_i(clock_camera_sync & reset_camera_sync_n),
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

logic spi_clock_in, spi_data_in, spi_data_out, spi_select_in;

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

    .mipi_clock_p_in(mipi_clock_p),
    .mipi_clock_n_in(mipi_clock_n),
    .mipi_data_p_in(mipi_data_p),
    .mipi_data_n_in(mipi_data_n)
);

task txrx_byte(
    input logic [7:0] data_send,
    output logic [7:0] data_recvd
);
    begin
        for (integer i = 7; i >= 0; i--) begin
            spi_data_in <= data_send[i];
            #62500;
            spi_clock_in <= ~spi_clock_in;
            #62500;
            data_recvd[i] <= spi_data_out;
            spi_clock_in <= ~spi_clock_in;
        end
        $display("%0t spi => sent: 0x%0h recieved: 0x%0h", $time, data_send, data_recvd);
        #250000;
    end
endtask

task delay_us(
    input logic [31:0] us
);
    begin
        for (integer i = 0; i < us; i++) begin
            #1000000;
        end
    end
endtask

logic [7:0] frame_count;
initial frame_count = 0;
always_ff @(negedge pixel_fv) begin
    if (!pixel_fv) begin
        frame_count <= frame_count + 1;
        $display("Sent frame %0d", frame_count);
    end
end

logic [7:0] jpeg_bytes0;
logic [7:0] jpeg_bytes1;
logic [7:0] jpeg_bytes2;
logic [23:0] jpeg_bytes;

logic [7:0] temp;

initial begin
        $display("Starting testbench");
        spi_clock_in = 0;
        spi_select_in = 1;
        
        // Wait for reset, 1 frame of 76x76 to end
        delay_us('d1100);

        // Reset jpeg
        spi_select_in = 0;
        txrx_byte('h30, temp);
        txrx_byte('h06, temp);
        spi_select_in = 1;
        delay_us('d1);
        spi_select_in = 0;
        txrx_byte('h30, temp);
        txrx_byte('h00, temp);
        spi_select_in = 1;

        delay_us('d5);
        
        // Camera capture
        $display("capture");
        spi_select_in = 0;
        txrx_byte('h20, temp);
        spi_select_in = 1;
        delay_us('d8000);

        // JPEG bytes available
        $display("read jpeg bytes available");
        spi_select_in = 0;
        txrx_byte('h31, temp);
        txrx_byte('hff, jpeg_bytes0);
        txrx_byte('hff, jpeg_bytes1);
        txrx_byte('hff, jpeg_bytes2);
        jpeg_bytes = jpeg_bytes0 + (jpeg_bytes1 << 8) + (jpeg_bytes2 << 16);
        spi_select_in = 1;
        
        $display("reading camera");
        spi_select_in = 0;
        txrx_byte('h22, temp);
        for (integer i=0; i < jpeg_bytes; i++)
            txrx_byte('hff, temp);
        spi_select_in = 1;
    end

endmodule
