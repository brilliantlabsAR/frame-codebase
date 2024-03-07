WORKDIR = work

MODULES = ../../../modules
RADIANT = ../../../radiant

TOP = tb_top
SIM_SRCS += tb_top.sv


SRCH_PATH = $(MODULES)/../top.sv \
 $(MODULES)/pll/pll_wrapper.sv \
 $(RADIANT)/pll_ip/rtl/pll_ip.v \
 $(MODULES)/reset/reset_sync.sv \
 $(MODULES)/reset/reset_global.sv \
 $(RADIANT)/byte_to_pixel_ip/rtl/byte_to_pixel_ip.v \
 $(RADIANT)/csi2_receiver_ip/rtl/csi2_receiver_ip.v \
 $(MODULES)/camera/camera.sv \
 $(MODULES)/camera/crop.sv \
 $(MODULES)/camera/debayer.sv \
 $(MODULES)/camera/dumper.v \
 $(MODULES)/camera/image_buffer.sv \
 $(MODULES)/camera/jenc_cdc.sv \
 $(MODULES)/camera/metering.sv \
 $(MODULES)/camera/rgb_cdc.sv \
 $(MODULES)/camera/jisp/jisp.sv \
 $(MODULES)/camera/jisp/mcu_buffer.sv \
 $(MODULES)/camera/jisp/rgb2yuv.sv \
 $(MODULES)/camera/jisp/subsample.sv \
 $(MODULES)/camera/testbenches/image_gen.sv \
 $(MODULES)/camera/jenc/jenc.sv \
 $(MODULES)/camera/jenc/bitpacker.sv \
 $(MODULES)/camera/jenc/bytepacker.sv \
 $(MODULES)/camera/jenc/dct_1d_aan.sv \
 $(MODULES)/camera/jenc/dct_2d.sv \
 $(MODULES)/camera/jenc/entropy.sv \
 $(MODULES)/camera/jenc/huff_tables.sv \
 $(MODULES)/camera/jenc/quant_seq_mult_15x13_p4.sv \
 $(MODULES)/camera/jenc/quant_tables.sv \
 $(MODULES)/camera/jenc/quant.sv \
 $(MODULES)/camera/jenc/transpose.sv \
 $(MODULES)/camera/jenc/zigzag.sv \
 $(RADIANT)/jenc/ram_dp_w32_b4_d64/rtl/ram_dp_w32_b4_d64.v \
 $(RADIANT)/jisp/ram_dp_w18_d360/rtl/ram_dp_w18_d360.v \
 $(RADIANT)/jisp/ram_dp_w64_b8_d1440/rtl/ram_dp_w64_b8_d1440.v \
 $(RADIANT)/jisp/ram_dp_w64_b8_d2880/rtl/ram_dp_w64_b8_d2880.v \
 $(RADIANT)/sim_only/pll_sim_ip/rtl/pll_sim_ip.v \
 $(RADIANT)/sim_only/pixel_to_byte_ip/rtl/pixel_to_byte_ip.v \
 $(RADIANT)/sim_only/csi2_transmitter_ip/rtl/csi2_transmitter_ip.v \
 $(MODULES)/graphics/color_palette.sv \
 $(MODULES)/graphics/display_buffers.sv \
 $(MODULES)/graphics/display_driver.sv \
 $(MODULES)/graphics/graphics.sv \
 $(MODULES)/graphics/sprite_engine.sv \
 $(MODULES)/spi/spi_peripheral.sv \
 $(MODULES)/spi/spi_register.sv

# vsim-8233 = array out of bounds, fix later
VLOG_OPTS = -93 -sv -warning vlog-2388 -suppress 2388 -lint=full -pedanticerrors -fsmverbose w +libext+.v+.vl+.sv +libext+.sv \
 +define+RADIANT +define+MODELSIM +define+TOP_SIM +define+USE_LATTICE_EBR $(MODULES)/camera/jlib/jlib.vh $(MODULES)/camera/jenc/zigzag.vh $(SRCH_PATH) 

VSIM_OPTS = -warning vsim-3009 -t 100fs -voptargs="+acc" -L lifcl -L ovi_lifcl -L pmi_work -suppress vsim-7033,vsim-8630,3009,3389,vsim-8233 +define+RADIANT +define+MODELSIM +define+TOP_SIM +define+USE_LATTICE_EBR $(MODULES)/camera/jlib/jlib.vh $(MODULES)/camera/jenc/zigzag.vh

.PHONY: compile sim lib clean

compile: $(WORKDIR) $(SIM_SRCS)
	vlog $(VLOG_OPTS) $(SIM_SRCS)

sim:
	vsim -c $(VSIM_OPTS) -do "run -500ns; quit" work.$(TOP)

sim_gui:
	vsim -gui $(VSIM_OPTS) work.$(TOP)

$(WORKDIR):
	vlib work

clean:
	rm -rf transcript $(WORKDIR) *.wlf wlf* *.tap *.hex
