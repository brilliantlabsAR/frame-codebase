module ebr_tb #(
    parameter SENSOR_X_SIZE = 'd720,
    parameter SENSOR_Y_SIZE = 'd720,
    parameter DW    = 8
)(
);

localparam LW = DW + 1;


logic clk;
logic unsigned [LW-1:0]     line_buf_in[2:1];
logic unsigned [LW-1:0]     line_buf_out_0[2:1];
logic unsigned [LW-1:0]     line_buf_out_1[2:1];

logic lb_en, lb_we, lb_re;
logic unsigned [$clog2(SENSOR_X_SIZE/2)-1:0]     lb_ra, lb_wa;

GSR GSR_INST (.GSR_N('1), .CLK(clk));


dp_ram  #(
    .DW     (2*LW),
    .DEPTH  (SENSOR_X_SIZE/2)    // in bytes
) line_buf_0 (
    .wa     (lb_wa),
    .wd     ({line_buf_in[2], line_buf_in[1]}),
    .we     (lb_we),
    .ra     (lb_ra),
    .re     (lb_re),
    .rd     ({line_buf_out_0[2], line_buf_out_0[1]}),
    .*
);

ram_dp_w18_d360 line_buf_1 (
    .wr_addr_i  (lb_wa), 
    .wr_data_i  ({line_buf_in[2], line_buf_in[1]}), 
    .wr_en_i    (lb_we), 
    .wr_clk_en_i(lb_we), 
    .rd_addr_i  (lb_ra), 
    .rd_en_i    (lb_re), 
    .rd_clk_en_i(lb_re), 
    .rd_data_o  ({line_buf_out_1[2], line_buf_out_1[1]}), 
    .wr_clk_i   (clk), 
    .rd_clk_i   (clk), 
    .rst_i      (1'b0)
);


initial begin
    $dumpfile("dump.vcd");
    $dumpvars(); 
end

localparam Y_LINE_BUF_SIZE = SENSOR_X_SIZE;
localparam UV_LINE_BUF_SIZE = SENSOR_X_SIZE/2;
localparam Y_LINE_BUF_HEIGHT = 16;
localparam UV_LINE_BUF_HEIGHT = 8;
localparam integer depth[1:0] = {2*2*UV_LINE_BUF_SIZE*UV_LINE_BUF_HEIGHT/8, 2*Y_LINE_BUF_SIZE*Y_LINE_BUF_HEIGHT/8};

generate
for (genvar i=0; i<2; i++) begin : dp_ram_be
    logic unsigned [63:0]      wd;
    logic unsigned [7:0]       wbe;
    logic unsigned [$clog2(depth[i])-1:0] wa;
    logic unsigned              we;
    logic unsigned [$clog2(depth[i])-1:0] ra;
    logic unsigned              re;
    logic unsigned [63:0]       rd_0, rd_1;

    dp_ram_be  #(
        .DW     (8*8),
        .DEPTH  (depth[i])
    ) dp_ram_be (
        .rd (rd_0),
        .*
    );
    if (i ==0) 
        ram_dp_w64_b8_d2880 dp_ram_be_1 (
            .wr_addr_i  (wa), 
            .wr_data_i  (wd), 
            .wr_en_i    (we), 
            .wr_clk_en_i(we), 
            .rd_addr_i  (ra), 
            .rd_en_i    (re), 
            .rd_clk_en_i(re), 
            .rd_data_o  (rd_1), 
            .wr_clk_i   (clk), 
            .rd_clk_i   (clk), 
            .rst_i      (1'b0)
        );
    else 
        ram_dp_w64_b8_d1440 dp_ram_be_1 (
            .wr_addr_i  (wa), 
            .wr_data_i  (wd), 
            .wr_en_i    (we), 
            .wr_clk_en_i(we), 
            .rd_addr_i  (ra), 
            .rd_en_i    (re), 
            .rd_clk_en_i(re), 
            .rd_data_o  (rd_1), 
            .wr_clk_i   (clk), 
            .rd_clk_i   (clk), 
            .rst_i      (1'b0)
        );
        
end
endgenerate



endmodule
