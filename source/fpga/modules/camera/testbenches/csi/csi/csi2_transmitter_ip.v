// Verilog netlist produced by program LSE 
// Netlist written on Wed Mar 27 14:30:36 2024
// Source file index table: 
// Object locations will have the form @<file_index>(<first_ line>[<left_column>],<last_line>[<right_column>])
// file 0 "/opt/lscc/radiant/2023.2/ip/avant/fifo/rtl/lscc_fifo.v"
// file 1 "/opt/lscc/radiant/2023.2/ip/avant/fifo_dc/rtl/lscc_fifo_dc.v"
// file 2 "/opt/lscc/radiant/2023.2/ip/avant/ram_dp/rtl/lscc_ram_dp.v"
// file 3 "/opt/lscc/radiant/2023.2/ip/avant/ram_dp_true/rtl/lscc_ram_dp_true.v"
// file 4 "/opt/lscc/radiant/2023.2/ip/avant/ram_dq/rtl/lscc_ram_dq.v"
// file 5 "/opt/lscc/radiant/2023.2/ip/avant/rom/rtl/lscc_rom.v"
// file 6 "/opt/lscc/radiant/2023.2/ip/common/adder/rtl/lscc_adder.v"
// file 7 "/opt/lscc/radiant/2023.2/ip/common/adder_subtractor/rtl/lscc_add_sub.v"
// file 8 "/opt/lscc/radiant/2023.2/ip/common/complex_mult/rtl/lscc_complex_mult.v"
// file 9 "/opt/lscc/radiant/2023.2/ip/common/counter/rtl/lscc_cntr.v"
// file 10 "/opt/lscc/radiant/2023.2/ip/common/distributed_dpram/rtl/lscc_distributed_dpram.v"
// file 11 "/opt/lscc/radiant/2023.2/ip/common/distributed_rom/rtl/lscc_distributed_rom.v"
// file 12 "/opt/lscc/radiant/2023.2/ip/common/distributed_spram/rtl/lscc_distributed_spram.v"
// file 13 "/opt/lscc/radiant/2023.2/ip/common/mult_accumulate/rtl/lscc_mult_accumulate.v"
// file 14 "/opt/lscc/radiant/2023.2/ip/common/mult_add_sub/rtl/lscc_mult_add_sub.v"
// file 15 "/opt/lscc/radiant/2023.2/ip/common/mult_add_sub_sum/rtl/lscc_mult_add_sub_sum.v"
// file 16 "/opt/lscc/radiant/2023.2/ip/common/multiplier/rtl/lscc_multiplier.v"
// file 17 "/opt/lscc/radiant/2023.2/ip/common/ram_shift_reg/rtl/lscc_shift_register.v"
// file 18 "/opt/lscc/radiant/2023.2/ip/common/subtractor/rtl/lscc_subtractor.v"
// file 19 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_add.v"
// file 20 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_addsub.v"
// file 21 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_complex_mult.v"
// file 22 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_counter.v"
// file 23 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_distributed_dpram.v"
// file 24 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_distributed_rom.v"
// file 25 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_distributed_shift_reg.v"
// file 26 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_distributed_spram.v"
// file 27 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_fifo.v"
// file 28 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_fifo_dc.v"
// file 29 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_mac.v"
// file 30 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_mult.v"
// file 31 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_multaddsub.v"
// file 32 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_multaddsubsum.v"
// file 33 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_ram_dp.v"
// file 34 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_ram_dp_be.v"
// file 35 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_ram_dp_true.v"
// file 36 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_ram_dq.v"
// file 37 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_ram_dq_be.v"
// file 38 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_rom.v"
// file 39 "/opt/lscc/radiant/2023.2/ip/pmi/pmi_sub.v"
// file 40 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/ACC54.v"
// file 41 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/ADC.v"
// file 42 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/ALUREG.v"
// file 43 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/AON.v"
// file 44 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/BB_ADC.v"
// file 45 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/BB_CDR.v"
// file 46 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/BB_I3C_A.v"
// file 47 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/BB_PROGRAMN.v"
// file 48 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/BFD1P3KX.v"
// file 49 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/BFD1P3LX.v"
// file 50 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/BNKREF18.v"
// file 51 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/CONFIG_IP.v"
// file 52 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/CONFIG_LMMI.v"
// file 53 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/CONFIG_LMMIA.v"
// file 54 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/DDRDLL.v"
// file 55 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/DIFFIO18.v"
// file 56 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/DLLDEL.v"
// file 57 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/DP16K.v"
// file 58 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/DPHY.v"
// file 59 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/DPSC512K.v"
// file 60 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/DQSBUF.v"
// file 61 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/EBR.v"
// file 62 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/ECLKDIV.v"
// file 63 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/ECLKSYNC.v"
// file 64 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/FBMUX.v"
// file 65 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/FIFO16K.v"
// file 66 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/I2CFIFO.v"
// file 67 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/IFD1P3BX.v"
// file 68 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/IFD1P3DX.v"
// file 69 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/IFD1P3IX.v"
// file 70 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/IFD1P3JX.v"
// file 71 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/IOLOGIC.v"
// file 72 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/JTAG.v"
// file 73 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/LRAM.v"
// file 74 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/M18X36.v"
// file 75 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MIPI.v"
// file 76 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULT18.v"
// file 77 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULT18X18.v"
// file 78 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULT18X36.v"
// file 79 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULT36.v"
// file 80 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULT36X36.v"
// file 81 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULT9.v"
// file 82 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULT9X9.v"
// file 83 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULTADDSUB18X18.v"
// file 84 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULTADDSUB18X18WIDE.v"
// file 85 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULTADDSUB18X36.v"
// file 86 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULTADDSUB36X36.v"
// file 87 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULTADDSUB9X9WIDE.v"
// file 88 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULTIBOOT.v"
// file 89 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULTPREADD18X18.v"
// file 90 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/MULTPREADD9X9.v"
// file 91 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/OFD1P3BX.v"
// file 92 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/OFD1P3DX.v"
// file 93 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/OFD1P3IX.v"
// file 94 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/OFD1P3JX.v"
// file 95 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/OSC.v"
// file 96 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/OSCA.v"
// file 97 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/OSCD.v"
// file 98 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/PCIE.v"
// file 99 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/PDP16K.v"
// file 100 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/PDPSC16K.v"
// file 101 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/PDPSC512K.v"
// file 102 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/PLL.v"
// file 103 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/PLLA.v"
// file 104 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/PLLREFCS.v"
// file 105 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/PMU.v"
// file 106 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/PREADD9.v"
// file 107 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/REFMUX.v"
// file 108 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/REG18.v"
// file 109 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/SEDC.v"
// file 110 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/SEIO18.v"
// file 111 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/SEIO33.v"
// file 112 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/SGMIICDR.v"
// file 113 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/SIOLOGIC.v"
// file 114 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/SP16K.v"
// file 115 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/SP512K.v"
// file 116 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/TSALLA.v"
// file 117 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/USB23.v"
// file 118 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/lifcl/WDT.v"
// file 119 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/DPR16X4.v"
// file 120 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/FD1P3BX.v"
// file 121 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/FD1P3DX.v"
// file 122 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/FD1P3IX.v"
// file 123 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/FD1P3JX.v"
// file 124 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/GSR.v"
// file 125 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/IB.v"
// file 126 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/OB.v"
// file 127 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/OBZ.v"
// file 128 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/PCLKDIVSP.v"
// file 129 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/SPR16X4.v"
// file 130 "/opt/lscc/radiant/2023.2/cae_library/simulation/verilog/uaplatform/WIDEFN9.v"

//
// Verilog Description of module csi2_transmitter_ip
// module wrapper written out since it is a black-box. 
//

//

module csi2_transmitter_ip (ref_clk_i, reset_n_i, usrstdby_i, pd_dphy_i, 
            byte_or_pkt_data_i, byte_or_pkt_data_en_i, ready_o, vc_i, 
            dt_i, wc_i, clk_hs_en_i, d_hs_en_i, pll_lock_o, pix2byte_rstn_o, 
            pkt_format_ready_o, d_hs_rdy_o, byte_clk_o, c2d_ready_o, 
            phdr_xfr_done_o, ld_pyld_o, clk_p_io, clk_n_io, d_p_io, 
            d_n_io, sp_en_i, lp_en_i) /* synthesis cpe_box=1 */ ;
    input ref_clk_i;
    input reset_n_i;
    input usrstdby_i;
    input pd_dphy_i;
    input [7:0]byte_or_pkt_data_i;
    input byte_or_pkt_data_en_i;
    output ready_o;
    input [1:0]vc_i;
    input [5:0]dt_i;
    input [15:0]wc_i;
    input clk_hs_en_i;
    input d_hs_en_i;
    output pll_lock_o;
    output pix2byte_rstn_o;
    output pkt_format_ready_o;
    output d_hs_rdy_o;
    output byte_clk_o;
    output c2d_ready_o;
    output phdr_xfr_done_o;
    output ld_pyld_o;
    inout clk_p_io;
    inout clk_n_io;
    inout [0:0]d_p_io;
    inout [0:0]d_n_io;
    input sp_en_i;
    input lp_en_i;
    
    
    
endmodule
