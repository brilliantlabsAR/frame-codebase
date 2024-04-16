/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module entropy (
    input   logic signed[10:0]      q[1:0], 
    input   logic                   q_valid,
    output  logic                   q_hold,
    input   logic [4:0]             q_cnt,
    input   logic [1:0]             q_chroma,
    input   logic                   q_last_mcu,

    //packed code+coeff
    output  logic [5:0]             out_codecoeff_length,
    output  logic [51:0]            out_codecoeff,
    output  logic                   out_tlast,
    output  logic                   out_valid,
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
logic signed[10:0]          previousDC[2:0];
always @(posedge clk)
if (!resetn)
    previousDC <= {'0, '0, '0};
else if (q_valid & !q_hold)
    if (q_last_mcu & &q_cnt)  //  EOF reset
        previousDC <= {'0, '0, '0};
    else if (q_cnt == 0)
        previousDC[q_chroma] <= q[0];
    
// AC runlengths (RLE)
logic unsigned[3:0]     rl[1:0], next_rl[1:0], rl_stored;
logic unsigned[1:0]     rl16[1:0], next_rl16[1:0], rl16_stored;
logic                   rl_valid[1:0];

always @(posedge clk) if (q_valid & !q_hold) rl_stored <= next_rl[1];
always @(posedge clk) if (q_valid & !q_hold) rl16_stored <= next_rl16[1];

always_comb
    for (int i=0; i<2; i++) begin
        rl[i] = i==0 ? rl_stored : next_rl[i-1];
        rl16[i] = i==0 ? rl16_stored : next_rl16[i-1];

        if (i==0 & q_cnt==0 || q[i] != 0) begin // DC, or non-zero AC. Also insert any outstanding ZRL if q==0 and not DC
            rl_valid[i] = 1;
            next_rl[i] = 0;
            next_rl16[i] = 0;
        end
        else if(i==1 & &q_cnt) begin        // coeff==0 case: Insert EOB, but do not send ZRL
            rl_valid[i] = 1;
            next_rl[1] = 0;                 // dont care
            next_rl[0] = 0;                 // dont care
            next_rl16[1] = 0;
            next_rl16[0] = 0;
        end
        else if(rl[i]==15) begin            // keep track of 16-long runlengths
            rl_valid[i] = 0;
            next_rl[i] = 0;
            next_rl16[i] = rl16[i] + 1;
        end
        else begin                          // coeff[i] == 0, count run length
            rl_valid[i] = 0;
            next_rl[i] = rl[i] + 1;
            next_rl16[i] = rl16[i];
        end
    end

// Generate code words
logic signed[11:0]          tmp_coeff[1:0];     // 12 bits
logic unsigned[10:0]        coeff[1:0];         // 11 bits
logic unsigned[3:0]         coeff_length[1:0];
always_comb
    for (int i=0; i<2; i++) begin
        tmp_coeff[i] = (i==0 & q_cnt==0) ? q[i] - previousDC[q_chroma] : q[i];
        coeff_length[i] = bit_length(tmp_coeff[i] < 0 ? -tmp_coeff[i] : tmp_coeff[i]);
        if (tmp_coeff[i] < 0)
            coeff[i] = tmp_coeff[i] + ~('1 << coeff_length[i]);
        else 
            coeff[i] = tmp_coeff[i];
    end


// Read Huffman tables
logic [7:0]         ht_symbol[1:0];  // for debug
logic [3:0]         ht_rl[1:0], ht_coeff_length[1:0];
logic [1:0]         ht_re;
logic [1:0]         ht_chroma;
logic [1:0]         ht_ac;
logic [4:0]         code_length0[1:0];
logic [15:0]        code0[1:0];

always_comb for (int i=0; i<2; i++) begin
    ht_rl[i]            =  rl_valid[i] ? ((q[i]==0 & i==1 & &q_cnt) ?  4'h0 :           rl[i]) : 8'hf;
    ht_coeff_length[i]  =  rl_valid[i] ? ((q[i]==0 & i==1 & &q_cnt) ?  4'h0 : coeff_length[i]) : 4'h0;
    ht_symbol[i] = {ht_rl[i], ht_coeff_length[i]}; // for debug

    ht_re[i] = q_valid & !q_hold & (rl_valid[i] | rl[i]==13-i | rl[i]==12-i); // Read 0xF0: i==1: 11|12, i==0: 12|13
    ht_chroma[i] = |q_chroma;
    ht_ac[i] = ~(i==0 & q_cnt==0);
end

generate
for (genvar i=0; i<2; i++) begin
`ifdef INFER_HUFFMAN_CODES_ROM
huff_tables ht (
    .rl         (ht_rl[i]),
    .coeff_length (ht_coeff_length[i]),
    .re         (~out_hold),
    .chroma     (ht_chroma[i]),
    .ac         (ht_ac[i]),
    .len        (code_length0[i]),
    .code       (code0[i]),
    .clk
);
`else
logic [4:0] len;
huff_tables ht (
    .rl         (ht_rl[i]),
    .coeff_length (ht_coeff_length[i]),
    .re         (~out_hold),
    .chroma     (ht_chroma[i]),
    .ac         (ht_ac[i]),
    .len        (len),
    .code       ( ),
    .clk
);

logic [17:0] rom_rd;
logic [8:0] rom_addr;
always_comb rom_addr[8:5] = ht_ac[i] ? ht_coeff_length[i]  : 4'hb;  
always_comb rom_addr[4:1] = ht_ac[i] ? ht_rl[i] : ht_coeff_length[i];  
always_comb rom_addr[0] =  ht_chroma[i];

huffman_codes_rom huffman_codes_rom (
    .rd_clk_i   (clk), 
    .rst_i      (1'b0), 
    .rd_en_i    (~out_hold), 
    .rd_clk_en_i(~out_hold), 
    .rd_addr_i  (rom_addr), 
    .rd_data_o  (rom_rd)
);
always_comb code_length0[i][4:2] = len[4:2];
always_comb code_length0[i][1:0] = 1 + rom_rd[17:16];
always_comb code0[i] = rom_rd[15:0];
`endif
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
/* packer:
    {code, code_len},{coeff, coeff_len} 
    code is (DC) 11-bit left aligned (AC) 16-bit left aligned 
    coeff is (DC) 11-bit right aligned (AC) 10-bit right aligned 
    
    DC: 11+11=22 or AC: 16+10=26 
    
    (code << 10) | (coeff << (16 - code_len + 10 - coeff_len)
    (code << 10) | (coeff << (26 - code_len - coeff_len)
    (code << 10) | (coeff << (26 - (code_len + coeff_len))
        min=1
        max=26
        
    unsigned
    codecoeff_len = code_len + coeff_len
    if (codecoeff_len > 26 | codecoeff_len < 1)
        codecoeff = 'hx;
    else
        codecoeff = (code << 10) | (coeff << (26 - codecoeff_len))
*/
// pipeline data out
// coeff
logic unsigned[10:0]        coeff0[1:0];        // 11 bits
logic unsigned[10:0]        coeff1[1:0];        // 11 bits
logic unsigned[10:0]        coeff2[1:0];        // 11 bits
logic unsigned[3:0]         coeff_length0[1:0];
logic unsigned[3:0]         coeff_length1[1:0];
logic unsigned[3:0]         coeff_length2[1:0];
// code
logic unsigned[15:0]        code1[1:0];
logic unsigned[15:0]        code2[1:0];
logic unsigned[4:0]         code_length1[1:0];
logic unsigned[4:0]         code_length2[1:0];
// code+coeff
logic [4:0]                 codecoeff_length3[1:0];
logic [25:0]                codecoeff3[1:0];
// valid
logic [1:0]                 out_valid0, out_valid1, out_valid2, out_valid3;
logic [3:0]                 last_mcu;

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
            coeff2[i] <= coeff1[i];
            coeff_length2[i] <= coeff_length1[i];
        end else if (i==1 & q_valid & (rl_valid[0] & q[0]!=0 & rl16[0][0]) | (rl_valid[1] & q[1]!=0 & rl16[1][0]))
            coeff_length2[i] <= 0; // ZRL insertion into [1] (1x), no coeff

        // Code
        if (out_valid0[i] | (q_valid & (rl_valid[0] & q[0]!=0 & rl16[0][1]) | (rl_valid[1] & q[1]!=0 & rl16[1][1]))) begin  // ZRL insertion into [1:0] (2x)
            code1[i] <= code0[i];
            code_length1[i] <= code_length0[i];
        end
    
        if(out_valid1[i]) begin
            code2[i] <= code1[i];
            code_length2[i] <= code_length1[i];
        end
        else if(i==1 & q_valid & (rl_valid[0] & q[0]!=0 & rl16[0][0]) | (rl_valid[1] & q[1]!=0 & rl16[1][0])) begin // ZRL insertion into [1] (1x)
            code2[i] <= code0[i];
            code_length2[i] <= code_length0[i];
        end
        
        // Code + Coeff
        if (out_valid2[i]) begin
            logic [4:0] tmp_codecoeff_length;
            tmp_codecoeff_length = code_length2[i] + coeff_length2[i];
            codecoeff_length3[i] <= tmp_codecoeff_length;
            if (tmp_codecoeff_length > 26 | tmp_codecoeff_length < 1)
                codecoeff3[i] <= 'hx;
            else
                codecoeff3[i] <= (code_length2[i] != 0 ? (code2[i] << 10) : 0) | (coeff_length2[i] != 0 ? (coeff2[i] << (26 - tmp_codecoeff_length)) : 0);
        end
    end

// Final
logic [4:0] tmp_codecoeff_length0;
logic [4:0] tmp_codecoeff_length1;
logic [5:0] tmp_codecoeff_length;
always_comb tmp_codecoeff_length0 = out_valid3[0] ? codecoeff_length3[0] : 0;
always_comb tmp_codecoeff_length1 = out_valid3[1] ? codecoeff_length3[1] : 0;
always_comb tmp_codecoeff_length = tmp_codecoeff_length0 + tmp_codecoeff_length1;

always @(posedge clk)
if (|out_valid3 & !out_hold) begin
    out_codecoeff_length <= tmp_codecoeff_length;
    if (tmp_codecoeff_length > 52 | tmp_codecoeff_length < 2)
        out_codecoeff <= {52{1'hx}};
    else
        out_codecoeff <= 
            (out_valid3[0] ? (codecoeff3[0] << 26) : 0) | 
            (out_valid3[1] ? (codecoeff3[1] << (26 - tmp_codecoeff_length0)) : 0);
end

// end of stream
always @(posedge clk)
if (!out_hold) begin
    if (q_valid) last_mcu[0] <= q_last_mcu & &q_cnt;
    if (out_valid0) last_mcu[1] <= last_mcu[0];
    if (out_valid1) last_mcu[2] <= last_mcu[1];
    if (out_valid2) last_mcu[3] <= last_mcu[2];
    if (out_valid3) out_tlast <= last_mcu[3];
end

always @(posedge clk)
if (!resetn)  begin
    out_valid0 <= 0;
    out_valid1 <= 0;
    out_valid2 <= 0;
    out_valid3 <= 0;
    out_valid <= 0;
end
else if (!out_hold) begin
    out_valid0[0] <= q_valid & rl_valid[0];
    out_valid0[1] <= q_valid & rl_valid[1];

    if (q_valid & ((rl_valid[0] & q[0]!=0 & rl16[0][1]) | (rl_valid[1] & q[1]!=0 & rl16[1][1]))) // ZRL insertion into [1:0] (2x)
        out_valid1 <= {1'b1, 1'b1};
    else
        out_valid1 <= out_valid0;

    if (q_valid & ((rl_valid[0] & q[0]!=0 & rl16[0][0]) | (rl_valid[1] & q[1]!=0 & rl16[1][0]))) // ZRL insertion into [1] (1x)
        out_valid2[1] <= '1;
    else
        out_valid2 <= out_valid1;

    out_valid3 <= out_valid2;

    // Final one
    out_valid <= |out_valid3;
end

endmodule



/*
Y-Coeffs:
15  0   -1  0
-2  -1  0   0
-1  -1  0   0
-1* 0   0   0

Zig Zag
15, 0, -2, -1, -1, -1, 0, 0, -1, -1

Codes
(4)(15)     (1,2)(-2)   (0,1)(-1)   (0,1)(-1)   (0,1)(-1)   (2,1)(-1)   (0,1)(-1)   (0,0)
101 1111    11011 01    00 0        00 0        00 0        11100 0     00 0        1010

1011111-    1101101+000             000+000     --          111000+000              -1010
7           7+3                     3+3                     6+3                     4       

1011111     1101101000              000000      --          111000000               1010
7           10                      6                       9                       4

*/
/*
Y-Coeffs:
15  0   -1  0
-2  -1  0   0
-1  -1  0   0
-1* 0   0   0

Zig Zag
0, 0, -2, -1, -1, -1, 0, 0, -1, -1

Codes
(0)(0)      (1,2)(-2)   (0,1)(-1)   (0,1)(-1)   (0,1)(-1)   (2,1)(-1)   (0,1)(-1)   (0,0)
00 -        11011 01    00 0        00 0        00 0        11100 0     00 0        1010

00-         1101101+000             000+000     --          111000+000              -1010
2           7+3                     3+3                     6+3                     4       

00          1101101000              000000      --          111000000               1010
2           10                      6                       9                       4

*/


/*
UV-Coeffs:
14  0   0*  0
-1  -1  0   0
0   0   0   0
0   0   0   0

Zig Zag
14, 0, -1, 0, -1

Codes
(4)(14)     (1,1)(-1)   (1,1)(-1)   (0,0)
1110 1110   1011 0      1011 0      00

11101110-   10110-      10110-      -00
8           5           5           2

11101110    10110       10110       00
8           5           5           2

*/








