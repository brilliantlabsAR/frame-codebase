module dp_ram #(
    parameter DW = 8*8,
    parameter DEPTH = 2*720*16/8        // in words (64bit/8bytes) 
)(
    input logic[DW-1:0]                 wd,
    input logic[$clog2(DEPTH/8)-1:0]    wa,
    input logic                         we,
    input logic[(DW/8)-1:0]             wbe,
    output logic[DW-1:0]                rd,
    input logic[$clog2(DEPTH/8)-1:0]    ra,
    input logic                         re,
    input logic                         clk
);

logic[DW-1:0]       mem[DEPTH-1:0]; /* add syn ramstyle */

always @(posedge clk)
for (int i=0; i<(DW/8); i++) begin
    // write
    if (we & wbe[i])
        mem[wa][i*8 +: 8] <= wd[i*8 +: 8];

    // read
    if (re)
        rd <= mem[ra];
end

endmodule
