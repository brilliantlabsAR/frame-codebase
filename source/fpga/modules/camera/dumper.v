module dumper;
initial begin
    $dumpfile("dump.vcd");
    $dumpvars(); 
end
endmodule
