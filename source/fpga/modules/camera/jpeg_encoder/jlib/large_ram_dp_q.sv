module large_ram_dp_q (
    input logic[31:0]                   wd,
    input logic[13:0]                   wa,
    input logic                         we,
    output logic[31:0]                  rd,
    input logic[13:0]                   ra,
    input logic                         clk
);

logic[31:0]         mem[0:16383]; /* synthesis syn_ramstyle="Block_RAM" */
logic[13:0]         ra_i;
always @(posedge clk)
begin
    // write
    if (we)
        mem[wa] <= wd;
end
always @(posedge clk)
begin
    // read - no read enable in this version, but register out
    // if (re)
    ra_i <= ra;
    rd <= mem[ra_i];
end

endmodule
