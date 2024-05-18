/*
 * Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright (C) 2024 Robert Metchev
 */
module ram_dp_w64_b8_d2880_EBR (wr_clk_i, 
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
    input [11:0] wr_addr_i ; 
    input [11:0] rd_addr_i ; 
    output [63:0] rd_data_o ; 
    parameter MEM_ID = "ram_dp_w64_b8_d2880_EBR" ; 

parameter W = 2; // = 64/32
parameter D = 6; // = ceil(2880/512) = 6

logic [63:0] rd_data[D-1:0]; 
logic [63:0] rd_data_z[D-1:0]; 
logic [D-1:0] wr_en, rd_en, rd_en_z; 

always_comb for (int i = 0; i<D; i++) wr_en[i] = wr_en_i & wr_addr_i[11:9]==i;
always_comb for (int i = 0; i<D; i++) rd_en[i] = rd_en_i & rd_addr_i[11:9]==i;
always @(posedge rd_clk_i) for (int i = 0; i<D; i++) if (rd_en_i) rd_en_z[i] = rd_addr_i[11:9]==i;
always_comb for (int i = 0; i<D; i++) rd_data[i] = {64{rd_en_z[i]}} & rd_data_z[i];

assign rd_data_o = rd_data[0] | rd_data[1] | rd_data[2] | rd_data[3] | rd_data[4] | rd_data[5];

wire VDD, VSS;
VLO INST1( .Z(VSS));
VHI INST2( .Z(VDD));

generate
for (genvar i = 0; i<D; i++) begin : D2880
for (genvar j = 0; j<W; j++) begin : W64
PDP16K_MODE EBR_inst(
        .DI0    (wr_data_i[32*j + 0]),
        .DI1    (wr_data_i[32*j + 1]),
        .DI2    (wr_data_i[32*j + 2]),
        .DI3    (wr_data_i[32*j + 3]),
        .DI4    (wr_data_i[32*j + 4]),
        .DI5    (wr_data_i[32*j + 5]),
        .DI6    (wr_data_i[32*j + 6]),
        .DI7    (wr_data_i[32*j + 7]),
        .DI8    (VSS),
        .DI9    (wr_data_i[32*j + 8]),
        .DI10   (wr_data_i[32*j + 9]),
        .DI11   (wr_data_i[32*j + 10]),
        .DI12   (wr_data_i[32*j + 11]),
        .DI13   (wr_data_i[32*j + 12]),
        .DI14   (wr_data_i[32*j + 13]),
        .DI15   (wr_data_i[32*j + 14]),
        .DI16   (wr_data_i[32*j + 15]),
        .DI17   (VSS),
        .DI18   (wr_data_i[32*j + 16]),
        .DI19   (wr_data_i[32*j + 17]),
        .DI20   (wr_data_i[32*j + 18]),
        .DI21   (wr_data_i[32*j + 19]),
        .DI22   (wr_data_i[32*j + 20]),
        .DI23   (wr_data_i[32*j + 21]),
        .DI24   (wr_data_i[32*j + 22]),
        .DI25   (wr_data_i[32*j + 23]),
        .DI26   (VSS),
        .DI27   (wr_data_i[32*j + 24]),
        .DI28   (wr_data_i[32*j + 25]),
        .DI29   (wr_data_i[32*j + 26]),
        .DI30   (wr_data_i[32*j + 27]),
        .DI31   (wr_data_i[32*j + 28]),
        .DI32   (wr_data_i[32*j + 29]),
        .DI33   (wr_data_i[32*j + 30]),
        .DI34   (wr_data_i[32*j + 31]),
        .DI35   (VSS),
        .ADW0   (ben_i[4*j + 0]),
        .ADW1   (ben_i[4*j + 1]),
        .ADW2   (ben_i[4*j + 2]),
        .ADW3   (ben_i[4*j + 3]),
        .ADW4   (VDD),
        .ADW5   (wr_addr_i[0]),
        .ADW6   (wr_addr_i[1]),
        .ADW7   (wr_addr_i[2]),
        .ADW8   (wr_addr_i[3]),
        .ADW9   (wr_addr_i[4]),
        .ADW10  (wr_addr_i[5]),
        .ADW11  (wr_addr_i[6]),
        .ADW12  (wr_addr_i[7]),
        .ADW13  (wr_addr_i[8]),
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
        .ADR11  (rd_addr_i[6]),
        .ADR12  (rd_addr_i[7]),
        .ADR13  (rd_addr_i[8]),
        .CLKW   (wr_clk_i),
        .CLKR   (rd_clk_i),
        .CEW    (wr_en[i]),
        .CER    (rd_en[i]),
        .CSW0   (wr_en[i]),
        .CSW1   (wr_en[i]),
        .CSW2   (wr_en[i]),
        .CSR0   (rd_en[i]),
        .CSR1   (rd_en[i]),
        .CSR2   (rd_en[i]),
        .RST    (VSS),
        .DO0    (rd_data_z[i][32*j + 0]),
        .DO1    (rd_data_z[i][32*j + 1]),
        .DO2    (rd_data_z[i][32*j + 2]),
        .DO3    (rd_data_z[i][32*j + 3]),
        .DO4    (rd_data_z[i][32*j + 4]),
        .DO5    (rd_data_z[i][32*j + 5]),
        .DO6    (rd_data_z[i][32*j + 6]),
        .DO7    (rd_data_z[i][32*j + 7]),
        .DO8    ( ),
        .DO9    (rd_data_z[i][32*j + 8]),
        .DO10   (rd_data_z[i][32*j + 9]),
        .DO11   (rd_data_z[i][32*j + 10]),
        .DO12   (rd_data_z[i][32*j + 11]),
        .DO13   (rd_data_z[i][32*j + 12]),
        .DO14   (rd_data_z[i][32*j + 13]),
        .DO15   (rd_data_z[i][32*j + 14]),
        .DO16   (rd_data_z[i][32*j + 15]),
        .DO17   ( ),
        .DO18   (rd_data_z[i][32*j + 16]),
        .DO19   (rd_data_z[i][32*j + 17]),
        .DO20   (rd_data_z[i][32*j + 18]),
        .DO21   (rd_data_z[i][32*j + 19]),
        .DO22   (rd_data_z[i][32*j + 20]),
        .DO23   (rd_data_z[i][32*j + 21]),
        .DO24   (rd_data_z[i][32*j + 22]),
        .DO25   (rd_data_z[i][32*j + 23]),
        .DO26   ( ),
        .DO27   (rd_data_z[i][32*j + 24]),
        .DO28   (rd_data_z[i][32*j + 25]),
        .DO29   (rd_data_z[i][32*j + 26]),
        .DO30   (rd_data_z[i][32*j + 27]),
        .DO31   (rd_data_z[i][32*j + 28]),
        .DO32   (rd_data_z[i][32*j + 29]),
        .DO33   (rd_data_z[i][32*j + 30]),
        .DO34   (rd_data_z[i][32*j + 31]),
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

end // D2880
end // W64
endgenerate
endmodule
