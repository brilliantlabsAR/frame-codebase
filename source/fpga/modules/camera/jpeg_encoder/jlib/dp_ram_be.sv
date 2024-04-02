module dp_ram_be #(
    parameter DW = 64,
    parameter DEPTH = 2880 // in words
)(
    input logic[DW-1:0]                 wd,
    input logic[$clog2(DEPTH)-1:0]      wa,
    input logic                         we,
    input logic[(DW/8)-1:0]             wbe,
    output logic[DW-1:0]                rd,
    input logic[$clog2(DEPTH)-1:0]      ra,
    input logic                         re,
    input logic                         wclk,
    input logic                         rclk
);

logic[DW-1:0]       mem[0:DEPTH-1]; /* synthesis syn_ramstyle="Block_RAM" */

always @(posedge wclk)
begin
    // write
    for (int i=0; i<(DW/8); i++)
        if (we & wbe[i])
            mem[wa][i*8 +: 8] <= wd[i*8 +: 8];
end
always @(posedge rclk)
begin
    // read
    if (re)
        rd <= mem[ra];
end

endmodule
