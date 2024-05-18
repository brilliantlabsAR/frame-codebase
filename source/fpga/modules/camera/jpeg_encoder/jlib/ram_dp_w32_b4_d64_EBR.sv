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
PDP16K_MODE EBR_inst(
        .DI0    (wr_data_i[0]),
        .DI1    (wr_data_i[1]),
        .DI2    (wr_data_i[2]),
        .DI3    (wr_data_i[3]),
        .DI4    (wr_data_i[4]),
        .DI5    (wr_data_i[5]),
        .DI6    (wr_data_i[6]),
        .DI7    (wr_data_i[7]),
        .DI8    (VSS),
        .DI9    (wr_data_i[8]),
        .DI10   (wr_data_i[9]),
        .DI11   (wr_data_i[10]),
        .DI12   (wr_data_i[11]),
        .DI13   (wr_data_i[12]),
        .DI14   (wr_data_i[13]),
        .DI15   (wr_data_i[14]),
        .DI16   (wr_data_i[15]),
        .DI17   (VSS),
        .DI18   (wr_data_i[16]),
        .DI19   (wr_data_i[17]),
        .DI20   (wr_data_i[18]),
        .DI21   (wr_data_i[19]),
        .DI22   (wr_data_i[20]),
        .DI23   (wr_data_i[21]),
        .DI24   (wr_data_i[22]),
        .DI25   (wr_data_i[23]),
        .DI26   (VSS),
        .DI27   (wr_data_i[24]),
        .DI28   (wr_data_i[25]),
        .DI29   (wr_data_i[26]),
        .DI30   (wr_data_i[27]),
        .DI31   (wr_data_i[28]),
        .DI32   (wr_data_i[29]),
        .DI33   (wr_data_i[30]),
        .DI34   (wr_data_i[31]),
        .DI35   (VSS),
        .ADW0   (ben_i[0]),
        .ADW1   (ben_i[1]),
        .ADW2   (ben_i[2]),
        .ADW3   (ben_i[3]),
        .ADW4   (VDD),
        .ADW5   (wr_addr_i[0]),
        .ADW6   (wr_addr_i[1]),
        .ADW7   (wr_addr_i[2]),
        .ADW8   (wr_addr_i[3]),
        .ADW9   (wr_addr_i[4]),
        .ADW10  (wr_addr_i[5]),
        .ADW11  (VSS),
        .ADW12  (VSS),
        .ADW13  (VSS),
        .ADR0   (VDD),
        .ADR1   (VDD),
        .ADR2   (VDD),
        .ADR3   (VDD),
        .ADR4   (VDD),
        .ADR5   (rd_addr_i[0]),
        .ADR6   (rd_addr_i[1]),
        .ADR7   (rd_addr_i[2]),
        .ADR8   (rd_addr_i[3]),
        .ADR9   (rd_addr_i[4]),
        .ADR10  (rd_addr_i[5]),
        .ADR11  (VSS),
        .ADR12  (VSS),
        .ADR13  (VSS),
        .CLKW   (wr_clk_i),
        .CLKR   (rd_clk_i),
        .CEW    (wr_en_i),
        .CER    (rd_en_i),
        .CSW0   (wr_en_i),
        .CSW1   (wr_en_i),
        .CSW2   (wr_en_i),
        .CSR0   (rd_en_i),
        .CSR1   (rd_en_i),
        .CSR2   (rd_en_i),
        .RST    (VSS),
        .DO0    (rd_data_o[0]),
        .DO1    (rd_data_o[1]),
        .DO2    (rd_data_o[2]),
        .DO3    (rd_data_o[3]),
        .DO4    (rd_data_o[4]),
        .DO5    (rd_data_o[5]),
        .DO6    (rd_data_o[6]),
        .DO7    (rd_data_o[7]),
        .DO8    ( ),
        .DO9    (rd_data_o[8]),
        .DO10   (rd_data_o[9]),
        .DO11   (rd_data_o[10]),
        .DO12   (rd_data_o[11]),
        .DO13   (rd_data_o[12]),
        .DO14   (rd_data_o[13]),
        .DO15   (rd_data_o[14]),
        .DO16   (rd_data_o[15]),
        .DO17   ( ),
        .DO18   (rd_data_o[16]),
        .DO19   (rd_data_o[17]),
        .DO20   (rd_data_o[18]),
        .DO21   (rd_data_o[19]),
        .DO22   (rd_data_o[20]),
        .DO23   (rd_data_o[21]),
        .DO24   (rd_data_o[22]),
        .DO25   (rd_data_o[23]),
        .DO26   ( ),
        .DO27   (rd_data_o[24]),
        .DO28   (rd_data_o[25]),
        .DO29   (rd_data_o[26]),
        .DO30   (rd_data_o[27]),
        .DO31   (rd_data_o[28]),
        .DO32   (rd_data_o[29]),
        .DO33   (rd_data_o[30]),
        .DO34   (rd_data_o[31]),
        .DO35   ( ),
        .ONEBITERR ( ),
        .TWOBITERR ( )
    );

defparam EBR_inst.DATA_WIDTH_W = "X36";
defparam EBR_inst.DATA_WIDTH_R = "X36";
defparam EBR_inst.OUTREG = "BYPASSED";
defparam EBR_inst.RESETMODE = "SYNC";
defparam EBR_inst.GSR = "DISABLED";
defparam EBR_inst.ECC = "DISABLED";
defparam EBR_inst.CSDECODE_W = "000";
defparam EBR_inst.CSDECODE_R = "000";
defparam EBR_inst.ASYNC_RST_RELEASE = "SYNC";

endmodule
