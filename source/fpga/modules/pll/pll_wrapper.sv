/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
 *
 * Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Raj Nakarja / Brilliant Labs Limited (raj@brilliant.xyz)
 *
 * CERN Open Hardware Licence Version 2 - Permissive
 *
 * Copyright © 2023 Brilliant Labs Limited
 */

module pll_wrapper (
    input logic clki_i,
    output logic clkop_o,
    output logic clkos_o,
    output logic clkos2_o,
    output logic clkos3_o,
    output logic clkos4_o,
    output logic clkos5_o,
    output logic lock_o
);

logic feedback_w;
assign feedback_w = clkos5_o;

PLL #(
    .BW_CTL_BIAS("0b1111"),
    .CLKMUX_FB("CMUX_CLKOS5"),
    .CRIPPLE("1P"),
    .CSET("8P"),
    .DELA("59"),
    .DELB("39"),
    .DELC("9"),
    .DELD("28"),
    .DELE("14"),
    .DELF("3"),
    .DIV_DEL("0b0000011"),
    .DIVA("59"),
    .DIVB("39"),
    .DIVC("9"),
    .DIVD("28"),
    .DIVE("14"),
    .DIVF("3"),
    .ENCLK_CLKOP("ENABLED"),
    .ENCLK_CLKOS("ENABLED"),
    .ENCLK_CLKOS2("ENABLED"),
    .ENCLK_CLKOS3("ENABLED"),
    .ENCLK_CLKOS4("ENABLED"),
    .ENCLK_CLKOS5("ENABLED"),
    .FBK_INTEGER_MODE("ENABLED"),
    .FBK_MASK("0b00000000"),
    .FBK_MMD_DIG("20"),
    .FBK_MMD_PULS_CTL("0b0001"),
    .IPI_CMP("0b1100"),
    .IPI_CMPN("0b0011"),
    .IPP_CTRL("0b0110"),
    .IPP_SEL("0b1111"),
    .KP_VCO("0b00011"),
    .PHIA("0"),
    .PHIB("0"),
    .PHIC("0"),
    .PHID("0"),
    .PHIE("0"),
    .PHIF("0"),
    .PLLPD_N("USED"),
    .REF_INTEGER_MODE("ENABLED"),
    .REF_MMD_DIG("1"),
    .SEL_FBK("DIVF"),
    .SSC_N_CODE("0b000000000"),
    .SSC_ORDER("SDM_ORDER1"),
    .V2I_1V_EN("ENABLED"),
    .V2I_KVCO_SEL("60"),
    .V2I_PP_ICTRL("0b11111"),
    .V2I_PP_RES("9K")
) pll (
    .FBKCK(feedback_w),
    .PLLRESET(0),
    .REFCK(clki_i),
    .CLKOP(clkop_o),
    .CLKOS(clkos_o),
    .CLKOS2(clkos2_o),
    .CLKOS3(clkos3_o),
    .CLKOS4(clkos4_o),
    .CLKOS5(clkos5_o),
    .LOCK(lock_o)
);

endmodule