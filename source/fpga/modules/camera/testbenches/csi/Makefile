WORKDIR = work

TOP = csi_tb
SIM_SRCS += source/csi/csi_tb.sv

SRCH_PATH = \
 source/csi/reset.sv \
 source/csi/image_gen.sv \
 source/csi/pll_sim_ip/rtl/pll_sim_ip.v \
 source/csi/pixel_to_byte_ip/rtl/pixel_to_byte_ip.v \
 source/csi/csi2_transmitter_ip/rtl/csi2_transmitter_ip.v \
 source/csi/byte_to_pixel_ip/rtl/byte_to_pixel_ip.v \
 source/csi/csi2_receiver_ip/rtl/csi2_receiver_ip.v

# vsim-8233 = array out of bounds, fix later
VLOG_OPTS = -93 -sv -warning vlog-2388 -suppress 2388 -lint=full -pedanticerrors -fsmverbose w +libext+.v+.vl+.sv +libext+.sv $(SRCH_PATH)

VSIM_OPTS = -warning vsim-3009 -t 100fs -voptargs="+acc" -L lifcl -L ovi_lifcl -L pmi_work \
 -suppress vsim-7033,vsim-8630,3009,3389,vsim-8233

.PHONY: compile sim clean

all: clean compile sim

compile: $(WORKDIR) $(SIM_SRCS)
	vlog $(VLOG_OPTS) $(SIM_SRCS)

sim:
	vsim -gui $(VSIM_OPTS) work.$(TOP)

$(WORKDIR):
	vlib work

clean:
	rm -rf transcript $(WORKDIR) *.wlf wlf* *.tap *.hex