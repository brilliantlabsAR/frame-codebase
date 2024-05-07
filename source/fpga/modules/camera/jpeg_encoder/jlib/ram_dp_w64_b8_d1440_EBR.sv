/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module ram_dp_w64_b8_d1440_EBR (wr_clk_i, 
        rd_clk_i, 
        //rst_i, 
        //wr_clk_en_i, 
        rd_en_i, 
        //rd_clk_en_i, 
        wr_en_i, 
        ben_i, 
        wr_data_i, 
        wr_addr_i, 
        rd_addr_i, 
        rd_data_o) ;
    input wr_clk_i ; 
    input rd_clk_i ; 
    //input rst_i ; 
    //input wr_clk_en_i ; 
    input rd_en_i ; 
    //input rd_clk_en_i ; 
    input wr_en_i ; 
    input [7:0] ben_i ; 
    input [63:0] wr_data_i ; 
    input [10:0] wr_addr_i ; 
    input [10:0] rd_addr_i ; 
    output [63:0] rd_data_o ; 
    parameter MEM_ID = "ram_dp_w64_b8_d1440_EBR" ; 

parameter W = 2; // = 64/32
parameter D = 3; // = ceil(1440/512) = 3

logic [63:0] rd_data[D-1:0]; 
logic [63:0] rd_data_z[D-1:0]; 
logic [D-1:0] wr_en, rd_en, rd_en_z; 

always_comb for (int i = 0; i<D; i++) wr_en[i] = wr_en_i & wr_addr_i[10:9]==i;
always_comb for (int i = 0; i<D; i++) rd_en[i] = rd_en_i & rd_addr_i[10:9]==i;
always @(posedge rd_clk_i) for (int i = 0; i<D; i++) if (rd_en_i) rd_en_z[i] = rd_addr_i[10:9]==i;
always_comb for (int i = 0; i<D; i++) rd_data[i] = {64{rd_en_z[i]}} & rd_data_z[i];

assign rd_data_o = rd_data[0] | rd_data[1] | rd_data[2];

generate
for (genvar i = 0; i<D; i++) begin : D1440
for (genvar j = 0; j<W; j++) begin : W64
EBR_CORE EBR_inst(
        .DIA0   (wr_data_i[32*j + 0]),
        .DIA1   (wr_data_i[32*j + 1]),
        .DIA2   (wr_data_i[32*j + 2]),
        .DIA3   (wr_data_i[32*j + 3]),
        .DIA4   (wr_data_i[32*j + 4]),
        .DIA5   (wr_data_i[32*j + 5]),
        .DIA6   (wr_data_i[32*j + 6]),
        .DIA7   (wr_data_i[32*j + 7]),
        .DIA8   (1'b0),
        .DIA9   (wr_data_i[32*j + 8]),
        .DIA10  (wr_data_i[32*j + 9]),
        .DIA11  (wr_data_i[32*j + 10]),
        .DIA12  (wr_data_i[32*j + 11]),
        .DIA13  (wr_data_i[32*j + 12]),
        .DIA14  (wr_data_i[32*j + 13]),
        .DIA15  (wr_data_i[32*j + 14]),
        .DIA16  (wr_data_i[32*j + 15]),
        .DIA17  (1'b0),
        .DIB0   (wr_data_i[32*j + 16]),
        .DIB1   (wr_data_i[32*j + 17]),
        .DIB2   (wr_data_i[32*j + 18]),
        .DIB3   (wr_data_i[32*j + 19]),
        .DIB4   (wr_data_i[32*j + 20]),
        .DIB5   (wr_data_i[32*j + 21]),
        .DIB6   (wr_data_i[32*j + 22]),
        .DIB7   (wr_data_i[32*j + 23]),
        .DIB8   (1'b0),
        .DIB9   (wr_data_i[32*j + 24]),
        .DIB10  (wr_data_i[32*j + 25]),
        .DIB11  (wr_data_i[32*j + 26]),
        .DIB12  (wr_data_i[32*j + 27]),
        .DIB13  (wr_data_i[32*j + 28]),
        .DIB14  (wr_data_i[32*j + 29]),
        .DIB15  (wr_data_i[32*j + 30]),
        .DIB16  (wr_data_i[32*j + 31]),
        .DIB17  (1'b0),
        .ADA0   (ben_i[4*j + 0]),
        .ADA1   (ben_i[4*j + 1]),
        .ADA2   (ben_i[4*j + 2]),
        .ADA3   (ben_i[4*j + 3]),
        .ADA4   (1'b1),
        .ADA5   (wr_addr_i[0]),
        .ADA6   (wr_addr_i[1]),
        .ADA7   (wr_addr_i[2]),
        .ADA8   (wr_addr_i[3]),
        .ADA9   (wr_addr_i[4]),
        .ADA10  (wr_addr_i[5]),
        .ADA11  (wr_addr_i[6]),
        .ADA12  (wr_addr_i[7]),
        .ADA13  (wr_addr_i[8]),
        .ADB0   (1'b1),
        .ADB1   (1'b1),
        .ADB2   (1'b1),
        .ADB3   (1'b1),
        .ADB4   (1'b1),
        .ADB5   (rd_addr_i[0]),
        .ADB6   (rd_addr_i[1]),
        .ADB7   (rd_addr_i[2]),
        .ADB8   (rd_addr_i[3]),
        .ADB9   (rd_addr_i[4]),
        .ADB10  (rd_addr_i[5]),
        .ADB11  (rd_addr_i[6]),
        .ADB12  (rd_addr_i[7]),
        .ADB13  (rd_addr_i[8]),
        .CLKA   (wr_clk_i),
        .CLKB   (rd_clk_i),
        .CEA    (wr_en[i]),
        .CEB    (rd_en[i]),
        .CSA0   (wr_en[i]),
        .CSA1   (wr_en[i]),
        .CSA2   (wr_en[i]),
        .CSB0   (rd_en[i]),
        .CSB1   (rd_en[i]),
        .CSB2   (rd_en[i]),
        .RSTA   (1'b0),
        .RSTB   (1'b0),
        .DOB0   (rd_data_z[i][32*j + 0]),
        .DOB1   (rd_data_z[i][32*j + 1]),
        .DOB2   (rd_data_z[i][32*j + 2]),
        .DOB3   (rd_data_z[i][32*j + 3]),
        .DOB4   (rd_data_z[i][32*j + 4]),
        .DOB5   (rd_data_z[i][32*j + 5]),
        .DOB6   (rd_data_z[i][32*j + 6]),
        .DOB7   (rd_data_z[i][32*j + 7]),
        .DOB8   ( ),
        .DOB9   (rd_data_z[i][32*j + 8]),
        .DOB10  (rd_data_z[i][32*j + 9]),
        .DOB11  (rd_data_z[i][32*j + 10]),
        .DOB12  (rd_data_z[i][32*j + 11]),
        .DOB13  (rd_data_z[i][32*j + 12]),
        .DOB14  (rd_data_z[i][32*j + 13]),
        .DOB15  (rd_data_z[i][32*j + 14]),
        .DOB16  (rd_data_z[i][32*j + 15]),
        .DOB17  ( ),
        .DOA0   (rd_data_z[i][32*j + 16]),
        .DOA1   (rd_data_z[i][32*j + 17]),
        .DOA2   (rd_data_z[i][32*j + 18]),
        .DOA3   (rd_data_z[i][32*j + 19]),
        .DOA4   (rd_data_z[i][32*j + 20]),
        .DOA5   (rd_data_z[i][32*j + 21]),
        .DOA6   (rd_data_z[i][32*j + 22]),
        .DOA7   (rd_data_z[i][32*j + 23]),
        .DOA8   ( ),
        .DOA9   (rd_data_z[i][32*j + 24]),
        .DOA10  (rd_data_z[i][32*j + 25]),
        .DOA11  (rd_data_z[i][32*j + 26]),
        .DOA12  (rd_data_z[i][32*j + 27]),
        .DOA13  (rd_data_z[i][32*j + 28]),
        .DOA14  (rd_data_z[i][32*j + 29]),
        .DOA15  (rd_data_z[i][32*j + 30]),
        .DOA16  (rd_data_z[i][32*j + 31]),
        .DOA17  ( ),
        .ONEERR ( ),
        .TWOERR ( ),
        .WEA    (1'b1),
        .WEB    (1'b0),
        .DWS0   (1'b1),
        .DWS1   (1'b1),
        .DWS2   (1'b1),
        .DWS3   (1'b1),
        .DWS4   (1'b1),
        .FULLF  (),
        .AFULL  (),
        .EMPTYF (),
        .AEMPTY ()
    );

defparam EBR_inst.DATA_WIDTH_A = "X36";
defparam EBR_inst.DATA_WIDTH_B = "X36";
defparam EBR_inst.REGMODE_B = "BYPASSED";
defparam EBR_inst.REGMODE_A = "BYPASSED";
defparam EBR_inst.RESETMODE_A = "SYNC";
defparam EBR_inst.RESETMODE_B = "SYNC";
defparam EBR_inst.GSR = "ENABLED";
defparam EBR_inst.ECC = "DISABLED";
defparam EBR_inst.CSDECODE_A = "000";
defparam EBR_inst.CSDECODE_B = "000";
defparam EBR_inst.ASYNC_RESET_RELEASE_A = "SYNC";
defparam EBR_inst.ASYNC_RESET_RELEASE_B = "SYNC";
defparam EBR_inst.INIT_DATA = "DYNAMIC";
defparam EBR_inst.EBR_MODE = "DP";

end // D1440
end // W64
endgenerate
endmodule
