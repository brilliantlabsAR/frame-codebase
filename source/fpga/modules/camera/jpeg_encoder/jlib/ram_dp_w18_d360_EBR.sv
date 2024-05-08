/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module ram_dp_w18_d360_EBR (wr_clk_i, 
        rd_clk_i, 
        //rst_i, 
        //wr_clk_en_i, 
        rd_en_i, 
        //rd_clk_en_i, 
        wr_en_i, 
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
    input [17:0] wr_data_i ; 
    input [8:0] wr_addr_i ; 
    input [8:0] rd_addr_i ; 
    output [17:0] rd_data_o ; 
    parameter MEM_ID = "ram_dp_w18_d360_EBR" ; 

EBR_CORE EBR_inst(
        .DIA0   (wr_data_i[0]),
        .DIA1   (wr_data_i[1]),
        .DIA2   (wr_data_i[2]),
        .DIA3   (wr_data_i[3]),
        .DIA4   (wr_data_i[4]),
        .DIA5   (wr_data_i[5]),
        .DIA6   (wr_data_i[6]),
        .DIA7   (wr_data_i[7]),
        .DIA8   (wr_data_i[8]),
        .DIA9   (wr_data_i[9]),
        .DIA10  (wr_data_i[10]),
        .DIA11  (wr_data_i[11]),
        .DIA12  (wr_data_i[12]),
        .DIA13  (wr_data_i[13]),
        .DIA14  (wr_data_i[14]),
        .DIA15  (wr_data_i[15]),
        .DIA16  (wr_data_i[16]),
        .DIA17  (wr_data_i[17]),
        .DIB0   (1'b0),
        .DIB1   (1'b0),
        .DIB2   (1'b0),
        .DIB3   (1'b0),
        .DIB4   (1'b0),
        .DIB5   (1'b0),
        .DIB6   (1'b0),
        .DIB7   (1'b0),
        .DIB8   (1'b0),
        .DIB9   (1'b0),
        .DIB10  (1'b0),
        .DIB11  (1'b0),
        .DIB12  (1'b0),
        .DIB13  (1'b0),
        .DIB14  (1'b0),
        .DIB15  (1'b0),
        .DIB16  (1'b0),
        .DIB17  (1'b0),
        .ADA0   (1'b1),
        .ADA1   (1'b1),
        .ADA2   (1'b1),
        .ADA3   (1'b1),
        .ADA4   (wr_addr_i[0]),
        .ADA5   (wr_addr_i[1]),
        .ADA6   (wr_addr_i[2]),
        .ADA7   (wr_addr_i[3]),
        .ADA8   (wr_addr_i[4]),
        .ADA9   (wr_addr_i[5]),
        .ADA10  (wr_addr_i[6]),
        .ADA11  (wr_addr_i[7]),
        .ADA12  (wr_addr_i[8]),
        .ADA13  (1'b0),
        .ADB0   (1'b1),
        .ADB1   (1'b1),
        .ADB2   (1'b1),
        .ADB3   (1'b1),
        .ADB4   (rd_addr_i[0]),
        .ADB5   (rd_addr_i[1]),
        .ADB6   (rd_addr_i[2]),
        .ADB7   (rd_addr_i[3]),
        .ADB8   (rd_addr_i[4]),
        .ADB9   (rd_addr_i[5]),
        .ADB10  (rd_addr_i[6]),
        .ADB11  (rd_addr_i[7]),
        .ADB12  (rd_addr_i[8]),
        .ADB13  (1'b0),
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
        .RSTA   (1'b0),
        .RSTB   (1'b0),
        .DOB0   (rd_data_o[0]),
        .DOB1   (rd_data_o[1]),
        .DOB2   (rd_data_o[2]),
        .DOB3   (rd_data_o[3]),
        .DOB4   (rd_data_o[4]),
        .DOB5   (rd_data_o[5]),
        .DOB6   (rd_data_o[6]),
        .DOB7   (rd_data_o[7]),
        .DOB8   (rd_data_o[8]),
        .DOB9   (rd_data_o[9]),
        .DOB10  (rd_data_o[10]),
        .DOB11  (rd_data_o[11]),
        .DOB12  (rd_data_o[12]),
        .DOB13  (rd_data_o[13]),
        .DOB14  (rd_data_o[14]),
        .DOB15  (rd_data_o[15]),
        .DOB16  (rd_data_o[16]),
        .DOB17  (rd_data_o[17]),
        .DOA0   ( ),
        .DOA1   ( ),
        .DOA2   ( ),
        .DOA3   ( ),
        .DOA4   ( ),
        .DOA5   ( ),
        .DOA6   ( ),
        .DOA7   ( ),
        .DOA8   ( ),
        .DOA9   ( ),
        .DOA10  ( ),
        .DOA11  ( ),
        .DOA12  ( ),
        .DOA13  ( ),
        .DOA14  ( ),
        .DOA15  ( ),
        .DOA16  ( ),
        .DOA17  ( ),
        .ONEERR ( ),
        .TWOERR ( ),
        .WEA    (1'b1),
        .WEB    (1'b0),
`ifdef COCOTB_MODELSIM
        .DWS0   (1'b1),
        .DWS1   (1'b1),
        .DWS2   (1'b1),
        .DWS3   (1'b1),
        .DWS4   (1'b1),
`endif
        .FULLF  (),
        .AFULL  (),
        .EMPTYF (),
        .AEMPTY ()
    );

defparam EBR_inst.DATA_WIDTH_A = "X18";
defparam EBR_inst.DATA_WIDTH_B = "X18";
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
