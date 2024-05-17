/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module ram_dp_w32_b4_d64_EBR (wr_clk_i, 
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
    input [3:0] ben_i ; 
    input [31:0] wr_data_i ; 
    input [5:0] wr_addr_i ; 
    input [5:0] rd_addr_i ; 
    output [31:0] rd_data_o ; 
    parameter MEM_ID = "ram_dp_w32_b4_d64_EBR" ; 

wire VDD, VSS;
VLO INST1( .Z(VSS));
VHI INST2( .Z(VDD));
EBR_CORE EBR_inst(
        .DIA0   (wr_data_i[0]),
        .DIA1   (wr_data_i[1]),
        .DIA2   (wr_data_i[2]),
        .DIA3   (wr_data_i[3]),
        .DIA4   (wr_data_i[4]),
        .DIA5   (wr_data_i[5]),
        .DIA6   (wr_data_i[6]),
        .DIA7   (wr_data_i[7]),
        .DIA8   (VSS),
        .DIA9   (wr_data_i[8]),
        .DIA10  (wr_data_i[9]),
        .DIA11  (wr_data_i[10]),
        .DIA12  (wr_data_i[11]),
        .DIA13  (wr_data_i[12]),
        .DIA14  (wr_data_i[13]),
        .DIA15  (wr_data_i[14]),
        .DIA16  (wr_data_i[15]),
        .DIA17  (VSS),
        .DIB0   (wr_data_i[16]),
        .DIB1   (wr_data_i[17]),
        .DIB2   (wr_data_i[18]),
        .DIB3   (wr_data_i[19]),
        .DIB4   (wr_data_i[20]),
        .DIB5   (wr_data_i[21]),
        .DIB6   (wr_data_i[22]),
        .DIB7   (wr_data_i[23]),
        .DIB8   (VSS),
        .DIB9   (wr_data_i[24]),
        .DIB10  (wr_data_i[25]),
        .DIB11  (wr_data_i[26]),
        .DIB12  (wr_data_i[27]),
        .DIB13  (wr_data_i[28]),
        .DIB14  (wr_data_i[29]),
        .DIB15  (wr_data_i[30]),
        .DIB16  (wr_data_i[31]),
        .DIB17  (VSS),
        .ADA0   (ben_i[0]),
        .ADA1   (ben_i[1]),
        .ADA2   (ben_i[2]),
        .ADA3   (ben_i[3]),
        .ADA4   (VDD),
        .ADA5   (wr_addr_i[0]),
        .ADA6   (wr_addr_i[1]),
        .ADA7   (wr_addr_i[2]),
        .ADA8   (wr_addr_i[3]),
        .ADA9   (wr_addr_i[4]),
        .ADA10  (wr_addr_i[5]),
        .ADA11  (VSS),
        .ADA12  (VSS),
        .ADA13  (VSS),
        .ADB0   (VDD),
        .ADB1   (VDD),
        .ADB2   (VDD),
        .ADB3   (VDD),
        .ADB4   (VDD),
        .ADB5   (rd_addr_i[0]),
        .ADB6   (rd_addr_i[1]),
        .ADB7   (rd_addr_i[2]),
        .ADB8   (rd_addr_i[3]),
        .ADB9   (rd_addr_i[4]),
        .ADB10  (rd_addr_i[5]),
        .ADB11  (VSS),
        .ADB12  (VSS),
        .ADB13  (VSS),
        .CLKA   (wr_clk_i),
        .CLKB   (rd_clk_i),
        .CEA    (wr_en_i),
        .CEB    (rd_en_i),
        .CSA0   (wr_en_i),
        .CSA1   (wr_en_i),
        .CSA2   (wr_en_i),
        .CSB0   (rd_en_i),
        .CSB1   (rd_en_i),
        .CSB2   (rd_en_i),
        .RSTA   (VSS),
        .RSTB   (VSS),
        .DOB0   (rd_data_o[0]),
        .DOB1   (rd_data_o[1]),
        .DOB2   (rd_data_o[2]),
        .DOB3   (rd_data_o[3]),
        .DOB4   (rd_data_o[4]),
        .DOB5   (rd_data_o[5]),
        .DOB6   (rd_data_o[6]),
        .DOB7   (rd_data_o[7]),
        .DOB8   ( ),
        .DOB9   (rd_data_o[8]),
        .DOB10  (rd_data_o[9]),
        .DOB11  (rd_data_o[10]),
        .DOB12  (rd_data_o[11]),
        .DOB13  (rd_data_o[12]),
        .DOB14  (rd_data_o[13]),
        .DOB15  (rd_data_o[14]),
        .DOB16  (rd_data_o[15]),
        .DOB17  ( ),
        .DOA0   (rd_data_o[16]),
        .DOA1   (rd_data_o[17]),
        .DOA2   (rd_data_o[18]),
        .DOA3   (rd_data_o[19]),
        .DOA4   (rd_data_o[20]),
        .DOA5   (rd_data_o[21]),
        .DOA6   (rd_data_o[22]),
        .DOA7   (rd_data_o[23]),
        .DOA8   ( ),
        .DOA9   (rd_data_o[24]),
        .DOA10  (rd_data_o[25]),
        .DOA11  (rd_data_o[26]),
        .DOA12  (rd_data_o[27]),
        .DOA13  (rd_data_o[28]),
        .DOA14  (rd_data_o[29]),
        .DOA15  (rd_data_o[30]),
        .DOA16  (rd_data_o[31]),
        .DOA17  ( ),
        .ONEERR ( ),
        .TWOERR ( ),
        .WEA    (VDD),
        .WEB    (VSS),
`ifdef COCOTB_MODELSIM
        .DWS0   (VDD),
        .DWS1   (VDD),
        .DWS2   (VDD),
        .DWS3   (VDD),
        .DWS4   (VDD),
`endif
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

endmodule
