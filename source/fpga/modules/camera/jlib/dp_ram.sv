module dp_ram #(
    parameter PS = 8,   // pixel size, eg 8 bits or 10 bits
    parameter NP = 8,   // Ns pixels/word, eg 8
    parameter DW = NP*PS,
    parameter DEPTH = 2*720*16/NP       // in words (64bit/8bytes) 
)(
    input logic[DW-1:0]                 wd,
    input logic[$clog2(DEPTH)-1:0]      wa,
    input logic                         we,
    input logic[(DW/PS)-1:0]            wbe,
    output logic[DW-1:0]                rd,
    input logic[$clog2(DEPTH)-1:0]      ra,
    input logic                         re,
    input logic                         clk
);

logic[DW-1:0]       mem[0:DEPTH-1]; /* synthesis syn_ramstyle=Block_RAM */

always @(posedge clk)
begin
    // write
    for (int i=0; i<(DW/PS); i++)
        if (we & wbe[i])
            mem[wa][i*PS +: PS] <= wd[i*PS +: PS];
    //if (we)
    //    mem[wa] <= wd;

    // read
    if (re)
        rd <= mem[ra];
end

endmodule
