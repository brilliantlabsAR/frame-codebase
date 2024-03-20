WORKDIR = work

MODULES = ../../../modules
RADIANT = ../../../radiant

TOP = tb_top
SIM_SRCS += ../top_sim/tb_top.sv


SRCH_PATH = $(RADIANT)/frame/frame_frame_vo.vo \
 $(MODULES)/reset/reset_sync.sv \
 $(MODULES)/reset/reset_global.sv \
 $(MODULES)/camera/testbenches/image_gen.sv \
 $(RADIANT)/sim_only/pll_sim_ip/rtl/pll_sim_ip.v \
 $(RADIANT)/sim_only/pixel_to_byte_ip/rtl/pixel_to_byte_ip.v \
 $(RADIANT)/sim_only/csi2_transmitter_ip/rtl/csi2_transmitter_ip.v

# vsim-8233 = array out of bounds, fix later
VLOG_OPTS = -93 -sv -warning vlog-2388 -suppress 2388 -lint=full -pedanticerrors -fsmverbose w +libext+.v+.vl+.sv +libext+.sv \
 +define+RADIANT +define+MODELSIM +define+TOP_SIM +define+INFER_LARGE_RAM \
 $(SRCH_PATH) 

VSIM_OPTS = -warning vsim-3009 -t 100fs -voptargs="+acc" -L lifcl -L ovi_lifcl -L pmi_work \
 -suppress vsim-7033,vsim-8630,3009,3389,vsim-8233 \
 +define+RADIANT +define+MODELSIM +define+TOP_SIM +define+INFER_LARGE_RAM

.PHONY: compile sim lib clean

compile: $(WORKDIR) $(SIM_SRCS)
	vlog $(VLOG_OPTS) $(SIM_SRCS)

sim_gui:
	vsim -gui $(VSIM_OPTS) work.$(TOP) -sdfmin /tb_top/dut=$(RADIANT)/frame/frame_frame_vo.sdf

$(WORKDIR):
	vlib work

clean:
	rm -rf transcript $(WORKDIR) *.wlf wlf* *.tap *.hex
