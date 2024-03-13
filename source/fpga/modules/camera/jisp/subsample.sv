
/*
 * Subsample 4:4:4 to 4:2:0 (4:4:4, 4:2:2, 4:0:0 can be added easily)
 *
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
 module subsample #(
    parameter SENSOR_X_SIZE = 'd720,
    parameter SENSOR_Y_SIZE = 'd720,
    parameter DW    = 8
)(
    input   logic unsigned[DW-1:0]  yuvrgb_in[2:0], // to do: make pktized interface
    input   logic               yuvrgb_in_valid,
    output  logic               yuvrgb_in_hold,
    input   logic               frame_valid_in,
    input   logic               line_valid_in,
    output  logic unsigned[DW-1:0]  yuvrgb_out[2:0], // to do: make pktized interface
    output  logic [2:0]         yuvrgb_out_valid, // per component
    input   logic               yuvrgb_out_hold,
    output  logic               eof_out,
    output  logic[$clog2(SENSOR_X_SIZE)-1:0] yuvrgb_out_pixel_count,
    output  logic[$clog2(SENSOR_Y_SIZE)-1:0] yuvrgb_out_line_count,
    input   logic               clk,
    input   logic               resetn
);

localparam LINE_BUF_SIZE = SENSOR_X_SIZE/2;
localparam LW = DW + 1;

logic                       eof, eol;
logic                       frame_valid_in_q, line_valid_in_q;
logic [$clog2(SENSOR_X_SIZE)-1:0]   pixel_count;
logic [$clog2(SENSOR_Y_SIZE)-1:0]   line_count;

always @(posedge clk) 
if (!resetn) frame_valid_in_q <= 0; 
else frame_valid_in_q <= frame_valid_in;

always @(posedge clk) 
if (!resetn) line_valid_in_q <= 0; 
else line_valid_in_q <= line_valid_in;

always_comb eof = frame_valid_in_q & ~frame_valid_in;
always_comb eol = line_valid_in_q & ~line_valid_in;

// Line buffer explicit instance
logic unsigned [LW-1:0]     line_buf_in[2:1];
logic unsigned [LW-1:0]     line_buf_out[2:1];
logic lb_en, lb_we, lb_re;

always_comb lb_en = line_valid_in & yuvrgb_in_valid & !yuvrgb_in_hold;
always_comb lb_we = line_count[0]==0 & pixel_count[0]==1 & lb_en;
always_comb lb_re = line_count[0]==1 & pixel_count[0]==0 & lb_en;

`ifndef USE_LATTICE_EBR
dp_ram  #(
    .DW     (2*LW),
    .DEPTH  (SENSOR_X_SIZE/2)    // in bytes
) line_buf (
    .wa     (pixel_count >> 1),
    .wd     ({line_buf_in[2], line_buf_in[1]}),
    .we     (lb_we),
    .ra     (pixel_count >> 1),
    .re     (lb_re),
    .rd     ({line_buf_out[2], line_buf_out[1]}),
    .rclk   (clk),
    .wclk   (clk)
);
`else
ram_dp_w18_d360 line_buf (
    .wr_addr_i  (pixel_count >> 1), 
    .wr_data_i  ({line_buf_in[2], line_buf_in[1]}), 
    .wr_en_i    (lb_we), 
    .wr_clk_en_i(lb_we), 
    .rd_addr_i  (pixel_count >> 1), 
    .rd_en_i    (lb_re), 
    .rd_clk_en_i(lb_re), 
    .rd_data_o  ({line_buf_out[2], line_buf_out[1]}), 
    .wr_clk_i   (clk), 
    .rd_clk_i   (clk), 
    .rst_i      (1'b0)
);
`endif

// Store chroma lines in line buffer
always @(posedge clk)
if (!resetn | eof) begin
    pixel_count <= 0;
    line_count <= 0;
end 
else if (eol) begin
    pixel_count <= 0;
    line_count <= line_count + 1;
end 
else if (line_valid_in & yuvrgb_in_valid & !yuvrgb_in_hold)     
    pixel_count <= pixel_count + 1;

logic unsigned[DW-1:0]  yuvrgb_out_r[2:0]; // to do: make pktized interface
logic unsigned[DW-1:0]  yuvrgb_out_w[2:0]; // to do: make pktized interface

always_comb begin
    yuvrgb_out_w[0] = yuvrgb_in[0]; // nothing for Y

    for (int i=1; i<=2; i++) begin
        // Line buffer input
        line_buf_in[i] = yuvrgb_out_r[i] + yuvrgb_in[i];

        // outputs
        yuvrgb_out_w[i] = yuvrgb_out_r[i];

        if (pixel_count[0]==0)
            yuvrgb_out_w[i] = yuvrgb_in[i];
        else if (line_count[0]==1)
            yuvrgb_out_w[i] = (line_buf_out[i] + line_buf_in[i] + 2) >> 2;

    end
    // assemble output
    yuvrgb_out[0] = yuvrgb_out_r[0]; // Reg
    yuvrgb_out[1] = yuvrgb_out_w[1]; // Wire!
    yuvrgb_out[2] = yuvrgb_out_r[2]; // Reg
end

always @(posedge clk)
if (line_valid_in & yuvrgb_in_valid & !yuvrgb_in_hold)
    for (int i=0; i<=2; i++)
        if (~(i == 1 & pixel_count[0]==1)) // dont need V to be stored
            yuvrgb_out_r[i] <= yuvrgb_out_w[i];

always @(posedge clk)
if (!resetn) begin
    yuvrgb_out_valid <= {1'b0, 1'b0, 1'b0};
    eof_out <= 0;
end 
else if (!yuvrgb_in_hold) begin
        yuvrgb_out_valid[0] <= yuvrgb_in_valid;
        yuvrgb_out_valid[1] <= yuvrgb_in_valid & pixel_count[0]==0 & line_count[0]==1;
        yuvrgb_out_valid[2] <= yuvrgb_in_valid & pixel_count[0]==1 & line_count[0]==1;
        eof_out <= eof;
end

always_comb yuvrgb_in_hold = yuvrgb_out_hold;

always @(posedge clk) if (line_valid_in & yuvrgb_in_valid & !yuvrgb_in_hold)
    yuvrgb_out_pixel_count <= pixel_count;

always @(posedge clk) if (line_valid_in & yuvrgb_in_valid & !yuvrgb_in_hold)
    yuvrgb_out_line_count <= line_count;

endmodule
