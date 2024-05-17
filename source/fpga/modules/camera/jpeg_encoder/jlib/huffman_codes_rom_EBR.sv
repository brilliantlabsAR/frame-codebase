/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module huffman_codes_rom_EBR (rd_clk_i, 
        //rst_i, 
        rd_en_i, 
        //rd_clk_en_i, 
        rd_addr0_i, 
        rd_addr1_i, 
        rd_data0_o,
        rd_data1_o) ;
    input rd_clk_i ; 
    //input rst_i ; 
    input rd_en_i ; 
    //input rd_clk_en_i ; 
    input [8:0] rd_addr0_i ; 
    input [8:0] rd_addr1_i ; 
    output [17:0] rd_data0_o ; 
    output [17:0] rd_data1_o ; 

EBR_CORE EBR_inst(
        .DIA0   (1'b0),
        .DIA1   (1'b0),
        .DIA2   (1'b0),
        .DIA3   (1'b0),
        .DIA4   (1'b0),
        .DIA5   (1'b0),
        .DIA6   (1'b0),
        .DIA7   (1'b0),
        .DIA8   (1'b0),
        .DIA9   (1'b0),
        .DIA10  (1'b0),
        .DIA11  (1'b0),
        .DIA12  (1'b0),
        .DIA13  (1'b0),
        .DIA14  (1'b0),
        .DIA15  (1'b0),
        .DIA16  (1'b0),
        .DIA17  (1'b0),
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
        .ADA4   (rd_addr0_i[0]),
        .ADA5   (rd_addr0_i[1]),
        .ADA6   (rd_addr0_i[2]),
        .ADA7   (rd_addr0_i[3]),
        .ADA8   (rd_addr0_i[4]),
        .ADA9   (rd_addr0_i[5]),
        .ADA10  (rd_addr0_i[6]),
        .ADA11  (rd_addr0_i[7]),
        .ADA12  (rd_addr0_i[8]),
        .ADA13  (1'b0),
        .ADB0   (1'b1),
        .ADB1   (1'b1),
        .ADB2   (1'b1),
        .ADB3   (1'b1),
        .ADB4   (rd_addr1_i[0]),
        .ADB5   (rd_addr1_i[1]),
        .ADB6   (rd_addr1_i[2]),
        .ADB7   (rd_addr1_i[3]),
        .ADB8   (rd_addr1_i[4]),
        .ADB9   (rd_addr1_i[5]),
        .ADB10  (rd_addr1_i[6]),
        .ADB11  (rd_addr1_i[7]),
        .ADB12  (rd_addr1_i[8]),
        .ADB13  (1'b0),
        .CLKA   (rd_clk_i),
        .CLKB   (rd_clk_i),
        .CEA    (rd_en_i),
        .CEB    (rd_en_i),
        .CSA0   (rd_en_i),
        .CSA1   (rd_en_i),
        .CSA2   (rd_en_i),
        .CSB0   (rd_en_i),
        .CSB1   (rd_en_i),
        .CSB2   (rd_en_i),
        .RSTA   (1'b0),
        .RSTB   (1'b0),
        .DOA0   (rd_data0_o[0]),
        .DOA1   (rd_data0_o[1]),
        .DOA2   (rd_data0_o[2]),
        .DOA3   (rd_data0_o[3]),
        .DOA4   (rd_data0_o[4]),
        .DOA5   (rd_data0_o[5]),
        .DOA6   (rd_data0_o[6]),
        .DOA7   (rd_data0_o[7]),
        .DOA8   (rd_data0_o[8]),
        .DOA9   (rd_data0_o[9]),
        .DOA10  (rd_data0_o[10]),
        .DOA11  (rd_data0_o[11]),
        .DOA12  (rd_data0_o[12]),
        .DOA13  (rd_data0_o[13]),
        .DOA14  (rd_data0_o[14]),
        .DOA15  (rd_data0_o[15]),
        .DOA16  (rd_data0_o[16]),
        .DOA17  (rd_data0_o[17]),
        .DOB0   (rd_data1_o[0]),
        .DOB1   (rd_data1_o[1]),
        .DOB2   (rd_data1_o[2]),
        .DOB3   (rd_data1_o[3]),
        .DOB4   (rd_data1_o[4]),
        .DOB5   (rd_data1_o[5]),
        .DOB6   (rd_data1_o[6]),
        .DOB7   (rd_data1_o[7]),
        .DOB8   (rd_data1_o[8]),
        .DOB9   (rd_data1_o[9]),
        .DOB10  (rd_data1_o[10]),
        .DOB11  (rd_data1_o[11]),
        .DOB12  (rd_data1_o[12]),
        .DOB13  (rd_data1_o[13]),
        .DOB14  (rd_data1_o[14]),
        .DOB15  (rd_data1_o[15]),
        .DOB16  (rd_data1_o[16]),
        .DOB17  (rd_data1_o[17]),
        .ONEERR ( ),
        .TWOERR ( ),
        .WEA    (1'b0),
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
defparam EBR_inst.EBR_MODE = "SP";
// autogenerated
defparam EBR_inst.INITVAL_00 = "0x1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD2000074000";
defparam EBR_inst.INITVAL_01 = "0x3FC805FD201BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD";
defparam EBR_inst.INITVAL_02 = "0x5E8007F4005E4005EC003D8005E8003D0003D8001B0003D0001A0001C00076000780002800020000";
defparam EBR_inst.INITVAL_03 = "0x5FD867FDF53FD807FDEB5FD205FD001F9003FC801F8803FC401F8001F9001F5801F8807F1001F800";
defparam EBR_inst.INITVAL_04 = "0x5FD007FD705FCE07FD603FC405FCE01F5003FC007F0001F5807ED007F1003C8001B0005000028000";
defparam EBR_inst.INITVAL_05 = "0x7FDF67FDF67FDED7FDEC7FDE47FDE27FDDB7FDD97FDD27FDD07FDC97FDC77FDC07FDBE7FDB75FD80";
defparam EBR_inst.INITVAL_06 = "0x7FDAF7FDAE7FDA77FDA67FD9F7FD9E7FD977FD963FC007FD503F9C03F9C07EC005E4007400050000";
defparam EBR_inst.INITVAL_07 = "0x7FDF77FDF77FDEE7FDED7FDE57FDE37FDDC7FDDA7FDD37FDD17FDCA7FDC87FDC17FDBF7FDB87FDB6";
defparam EBR_inst.INITVAL_08 = "0x7FDB07FDAF7FDA87FDA77FDA07FD9F7FD987FD977FD707FD8F7FD607FD401F4801F5001800076000";
defparam EBR_inst.INITVAL_09 = "0x7FDF87FDF87FDEF7FDEE7FDE67FDE47FDDD7FDDB7FDD47FDD27FDCB7FDC97FDC27FDC07FDB97FDB7";
defparam EBR_inst.INITVAL_0A = "0x7FDB17FDB07FDA97FDA87FDA17FDA07FD997FD987FD917FD905FD847FD895FCC05FCC0190001A000";
defparam EBR_inst.INITVAL_0B = "0x7FDF97FDF97FDF07FDEF7FDE77FDE57FDDE7FDDC7FDD57FDD37FDCC7FDCA7FDC37FDC17FDBA7FDB8";
defparam EBR_inst.INITVAL_0C = "0x7FDB27FDB17FDAA7FDA97FDA27FDA17FD9A7FD997FD927FD917FD8C7FD8A7FD507FD843C0005E000";
defparam EBR_inst.INITVAL_0D = "0x7FDFA7FDFA7FDF17FDF07FDE87FDE67FDDF7FDDD7FDD67FDD47FDCD7FDCB7FDC47FDC27FDBB7FDB9";
defparam EBR_inst.INITVAL_0E = "0x7FDB37FDB27FDAB7FDAA7FDA37FDA27FD9B7FD9A7FD937FD927FD8D7FD8B7FD887FD855E0007F000";
defparam EBR_inst.INITVAL_0F = "0x7FDFB7FDFB7FDF27FDF17FDE97FDE77FDE07FDDE7FDD77FDD57FDCE7FDCC7FDC57FDC37FDBC7FDBA";
defparam EBR_inst.INITVAL_10 = "0x7FDB47FDB37FDAC7FDAB7FDA47FDA37FD9C7FD9B7FD947FD937FD8E7FD8C7FD897FD861F4003F980";
defparam EBR_inst.INITVAL_11 = "0x7FDFC7FDFC7FDF37FDF27FDEA7FDE87FDE17FDDF7FDD87FDD67FDCF7FDCD7FDC67FDC47FDBD7FDBB";
defparam EBR_inst.INITVAL_12 = "0x7FDB57FDB47FDAD7FDAC7FDA57FDA47FD9D7FD9C7FD957FD947FD8F7FD8D7FD8A7FD873F9807FD82";
defparam EBR_inst.INITVAL_13 = "0x7FDFD7FDFD7FDF47FDF37FDEB7FDE97FDE27FDE07FDD97FDD77FDD07FDCE7FDC77FDC57FDBE7FDBC";
defparam EBR_inst.INITVAL_14 = "0x7FDB67FDB57FDAE7FDAD7FDA67FDA57FD9E7FD9D7FD967FD957FD907FD8E7FD8B7FD887FD407FD83";
defparam EBR_inst.INITVAL_15 = "0x7FDFE7FDFE7FDF57FDF47FDEC7FDEA7FDE37FDE17FDDA7FDD87FDD17FDCF7FDC87FDC67FDBF7FDBD";
defparam EBR_inst.INITVAL_16 = "0x5F8001E0003F0007C0001E000580007C000540005800050000300004C00028000480002000020000";
defparam EBR_inst.INITVAL_17 = "0x1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD1BCAD5FDC01FD003FD807FC001FD005F8007FC003F000";

endmodule