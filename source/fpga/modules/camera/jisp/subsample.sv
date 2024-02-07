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
    output  logic               frame_valid_out,
    output  logic               line_valid_out,
    output  logic               eof_out,
    output  logic               eol_out,
    output  logic[$clog2(SENSOR_X_SIZE)-1:0] yuvrgb_out_pixel_count,
    output  logic[$clog2(SENSOR_Y_SIZE)-1:0] yuvrgb_out_line_count,
    input   logic               clk,
    input   logic               resetn
);

localparam LINE_BUF_SIZE = SENSOR_X_SIZE/2;
localparam LW = DW + 1;

logic unsigned [LW-1:0]     line_buffer[LINE_BUF_SIZE-1:0][2:1];    
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
else if (line_valid_in & yuvrgb_in_valid & !yuvrgb_in_hold) begin       
        pixel_count <= pixel_count + 1;
        yuvrgb_out[0] <= yuvrgb_in[0];
        for (int i=1; i<=2; i++)
            if (pixel_count[0]==0)
                yuvrgb_out[i] <= yuvrgb_in[i];
            else if (line_count[0]==0)
                line_buffer[pixel_count >> 1][i] <= yuvrgb_out[i] + yuvrgb_in[i];
            else // line_count[0]==1
                yuvrgb_out[i] <= (line_buffer[pixel_count >> 1][i] + yuvrgb_out[i] + yuvrgb_in[i] + 2) >> 2;
end

always @(posedge clk)
if (!resetn) begin
    yuvrgb_out_valid <= {1'b0, 1'b0, 1'b0};
    frame_valid_out <= 0;
    line_valid_out <= 0;
    eof_out <= 0;
    eol_out <= 0;
end 
else if (!yuvrgb_in_hold) begin
        yuvrgb_out_valid[0] <= yuvrgb_in_valid;
        yuvrgb_out_valid[1] <= yuvrgb_in_valid & pixel_count[0]==1 & line_count[0]==1;
        yuvrgb_out_valid[2] <= yuvrgb_in_valid & pixel_count[0]==1 & line_count[0]==1;
        frame_valid_out <= frame_valid_in;
        line_valid_out <= line_valid_in;
        eof_out <= eof;
        eol_out <= eol;
end

always_comb yuvrgb_in_hold = yuvrgb_out_hold;

always @(posedge clk) if (line_valid_in & yuvrgb_in_valid & !yuvrgb_in_hold)
    yuvrgb_out_pixel_count <= pixel_count;

always @(posedge clk) if (line_valid_in & yuvrgb_in_valid & !yuvrgb_in_hold)
    yuvrgb_out_line_count <= line_count;

endmodule
