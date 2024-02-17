module entropy (
    input   logic signed[10:0]      q[1:0], 
    input   logic                   q_valid,
    output  logic                   q_hold,
    input   logic [4:0]             q_cnt,
    input   logic                   q_chroma,

    output  logic [3:0]             out_coeff_length[1:0],
    output  logic [11:0]            out_coeff[1:0],
    output  logic [4:0]             out_code_length[1:0],
    output  logic [15:0]            out_code[1:0],
    output  logic                   out_valid[1:0],
    input   logic                   out_hold,


    input   logic                   clk,
    input   logic                   resetn
);

always_comb q_hold = out_hold;

// return size of signal
function automatic [3:0] bit_length(input logic[11:0] coeff);
    int length = 0;
    for (int v = coeff ; v > 0; v = v >> 1)
        length++;
    bit_length = length;
endfunction

// encode DC value (DPCM)
logic signed[10:0]          previousDC;
always @(posedge clk)
if (!resetn || 1'b0) // To Do: Add EOF reset
    previousDC <= 0;
else if (q_valid & !q_hold)
    previousDC <= q[0];
    
// AC runlengths (RLE)
logic unsigned[3:0]     rl[1:0], next_rl[1:0], rl_stored;
logic unsigned[1:0]     rl16[1:0], next_rl16[1:0], rl16_stored;
logic                   rl_valid[1:0];

always @(posedge clk) if (q_valid & !q_hold) rl_stored <= next_rl[1];
always @(posedge clk) if (q_valid & !q_hold) rl16_stored <= next_rl16[1];

always_comb
    for (int i=0; i<2; i++) begin
        rl[i] = i==0 ? rl_stored : next_rl[i];
        rl16[i] = i==0 ? rl16_stored : next_rl16[i];

        rl_valid[i] = 0;
        next_rl16[i] = rl16[i];
        if (i==0 & q_cnt==0 || q[i] != 0) begin // DC, or non-zero AC. Also insert any outstanding ZRL if q==0 and not DC
            rl_valid[i] = 1;
            next_rl[i] = 0;
            next_rl16[i] = 0;
        end
        else if(i==1 & &q_cnt) begin              // coeff==0 case: Insert EOB, but do not send ZRL
            rl_valid[i] = 1;
            next_rl[i] = 'x;                    // dont care
        end
        else if(rl[i]==15) begin                // keep track of 16-long runlengths
            next_rl[i] = 0;
            next_rl16[i] = rl16[i] + 1;
        end
        else                                    // coeff[i] == 0
            next_rl[i] = rl[i] + 1;

    end

// Generate code words
logic signed[11:0]          coeff[1:0]; // 12 bits
logic unsigned[3:0]         coeff_length[1:0];
always_comb
    for (int i=0; i<2; i++) begin
        coeff[i] = (i==0 & q_cnt==0) ? q[i] - previousDC : q[i];
        coeff_length[i] = bit_length(coeff[i] < 0 ? -coeff[i] : coeff[i]);
        if (coeff[i] < 0)
            coeff[i] = coeff[i] + ~('1 << coeff_length[i]);
    end


// Read Huffman tables
logic [4:0]         code_length0[1:0];
logic [15:0]        code0[1:0];

generate 
for (genvar i=0; i<2; i++) begin : ht
    logic [7:0]     symbol =  rl_valid[i] ? 
                                ((q[i]==0 & i==1 & &q_cnt) ?  8'h00 : {rl[i], coeff_length[i]}) : 
                                8'hf0;
    logic           re = q_valid & !q_hold & (rl_valid[i] | rl[i]==13-i | rl[i]==12-i); // Read 0xF0: i==1: 11|12, i==0: 12|13
    logic [1:0]     sel;
    always_comb sel[0] = q_chroma;
    always_comb sel[1] = ~(i==0 & q_cnt==0); // DC table
    huff_tables ht (
        .len        (code_length0[i]),
        .code       (code0[i]),
        .*
    );
end

endgenerate

/*
ZRL insertion
            run lengths
Coeff # 0 - 14      12*     10
Coeff # 1 - 15      13*     11*

Coeff # 0 - 15      13*     11
Coeff # 1 - xx      14*     12*

* = when to read out ZRL
                    Insert to Coeff pipe
run of 16 = 1       0       1
run of 16 = 2       1       0
run of 16 = 3       1       1
*/
// pipeline data out
// coeff
logic unsigned[11:0]        coeff0[1:0];        // 12 bits
logic unsigned[11:0]        coeff1[1:0];        // 12 bits
logic unsigned[3:0]         coeff_length0[1:0];
logic unsigned[3:0]         coeff_length1[1:0];
// code
logic unsigned[15:0]        code1[1:0];
logic unsigned[4:0]         code_length1[1:0];
// valid
logic                       out_valid0[1:0], out_valid1[1:0];

always @(posedge clk)
for (int i=0; i<2; i++)
    if (!out_hold) begin
        // Coeff
        if(q_valid & rl_valid[i]) begin
            coeff0[i] <= coeff[i];
            coeff_length0[i] <= coeff_length[i];
        end    

        if(out_valid0[i]) begin
            coeff1[i] <= coeff0[i];
            coeff_length1[i] <= coeff_length0[i];
        end else if (q_valid & (rl_valid[0] & q[0]!=0 & rl16[0][1]) | (rl_valid[1] & q[1]!=0 & rl16[1][1]))
            coeff_length1[i] <= 0; // ZRL insertion into [1:0] (2x), no coeff

        if(out_valid1[i]) begin
            out_coeff[i] <= coeff1[i];
            out_coeff_length[i] <= coeff_length1[i];
        end else if (i==1 & q_valid & (rl_valid[0] & q[0]!=0 & rl16[0][0]) | (rl_valid[1] & q[1]!=0 & rl16[1][0]))
            out_coeff_length[i] <= 0; // ZRL insertion into [1] (1x), no coeff

        // Code
        if (out_valid0[i] | (q_valid & (rl_valid[0] & q[0]!=0 & rl16[0][1]) | (rl_valid[1] & q[1]!=0 & rl16[1][1]))) begin  // ZRL insertion into [1:0] (2x)
            code1[i] <= code0[i];
            code_length1[i] <= code_length0[i];
        end
    
        if(out_valid1[i]) begin
            out_code[i] <= code1[i];
            out_code_length[i] <= code_length1[i];
        end
        else if(i==1 & q_valid & (rl_valid[0] & q[0]!=0 & rl16[0][1]) | (rl_valid[1] & q[1]!=0 & rl16[1][1])) begin // ZRL insertion into [1] (1x)
            out_code[i] <= code0[i];
            out_code_length[i] <= code_length0[i];
        end
    end

always @(posedge clk)
if (!resetn)  begin
    out_valid0 <= {1'b0, 1'b0};
    out_valid1 <= {1'b0, 1'b0};
    out_valid <= {1'b0, 1'b0};
end
else if (!out_hold) begin
    out_valid0[0] <= q_valid & rl_valid[0];
    out_valid0[1] <= q_valid & rl_valid[1];

    if (q_valid & ((rl_valid[0] & q[0]!=0 & rl16[0][1]) | (rl_valid[1] & q[1]!=0 & rl16[1][1]))) // ZRL insertion into [1:0] (2x)
        out_valid1 <= {1'b1, 1'b1};
    else
        out_valid1 <= out_valid0;

    if (q_valid & ((rl_valid[0] & q[0]!=0 & rl16[0][0]) | (rl_valid[1] & q[1]!=0 & rl16[1][0]))) // ZRL insertion into [1] (1x)
        out_valid[1] <= '1;
    else
        out_valid <= out_valid1;
end

endmodule














