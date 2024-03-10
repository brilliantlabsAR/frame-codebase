# defaults
#SIM ?= verilator
SIM ?= modelsim
export SIM := $(SIM)
TOPLEVEL_LANG ?= verilog

# JISP
VERILOG_FILES += \
        ../../jisp/jisp.sv \
        ../../jisp/mcu_buffer.sv \
        ../../jisp/rgb2yuv.sv \
        ../../jisp/subsample.sv

# JENC
VERILOG_FILES += \
        ../../jenc/jenc.sv \
        ../../jenc/dct_1d_aan.sv \
        ../../jenc/dct_2d.sv \
        ../../jenc/transpose.sv \
        ../../jenc/zigzag.sv \
        ../../jenc/quant_seq_mult_15x13_p4.sv \
        ../../jenc/quant.sv \
        ../../jenc/quant_tables.sv \
        ../../jenc/entropy.sv \
        ../../jenc/huff_tables.sv \
        ../../jenc/bitpacker.sv \
        ../../jenc/bytepacker.sv

# Camera + Top
VERILOG_FILES += \
        ../../image_buffer.sv \
        ../../rgb_cdc.sv \
        ../../jenc_cdc.sv \
        ../../crop.sv \
        ../../debayer.sv \
        ../../metering.sv \
        ../../camera.sv \
        ../../../reset/reset_sync.sv \
        ../../../reset/reset_global.sv
 
ifeq ($(SIM),verilator)
# inferrable RAM models
VERILOG_FILES += \
        ../../jlib/dp_ram.sv \
        ../../jlib/dp_ram_be.sv
endif

ifeq ($(SIM),modelsim)
# Lattice models
VERILOG_FILES += \
        ../../../../radiant/jenc/ram_dp_w32_b4_d64/rtl/ram_dp_w32_b4_d64.v \
        ../../../../radiant/jisp/ram_dp_w18_d360/rtl/ram_dp_w18_d360.v \
        ../../../../radiant/jisp/ram_dp_w64_b8_d2880/rtl/ram_dp_w64_b8_d2880.v \
        ../../../../radiant/jisp/ram_dp_w64_b8_d1440/rtl/ram_dp_w64_b8_d1440.v \
        ../../../../radiant/image_buffer/large_ram_dp_w32_d16k_q/rtl/large_ram_dp_w32_d16k_q.v \
        ../../../../radiant/pll_ip/rtl/pll_ip.v
endif

ifneq ($(SIM),verilator)
VERILOG_FILES += \
        dumper.v
endif


VERILOG_SOURCES += $(realpath $(VERILOG_FILES))
VERILOG_INCLUDE_DIRS += $(realpath ../.. ../../jisp  ../../jenc ../../jlib)

EXTRA_ARGS += +define+NO_MIPI_IP_SIM            # Simulate Bayer input
EXTRA_ARGS += +define+RADIANT
ifeq ($(SIM),verilator)
        EXTRA_ARGS += --trace --trace-structs
        EXTRA_ARGS += -Wall -Wno-fatal -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-ASCRANGE -Wno-PINCONNECTEMPTY
endif
ifeq ($(SIM),modelsim)
        EXTRA_ARGS += +define+USE_LATTICE_EBR
        EXTRA_ARGS += +define+COCOTB_MODELSIM
        EXTRA_ARGS += -suppress vlog-2244 
        EXTRA_ARGS += -L lifcl -L ovi_lifcl -L pmi_work 
        export COCOTB_RESOLVE_X=ZEROS       
endif

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL =  camera

# MODULE is the basename of the Python test file
MODULE = test_camera
export PYTHONPATH := $(realpath ../python_misc):$(realpath ../jcommon):$(realpath ../jed):$(PYTHONPATH)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

g gtkwave:
	gtkwave dump.vcd -a 1.gtkw
clean::
	rm -rf __pycache__ results.xml obj_dir
	rm -rf jpeg_out.jpg rgb_out.bmp ecs_out.bin dump.vcd
	rm -rf transcript modelsim.ini vsim.wlf vsim_stacktrace.vstf vish_stacktrace.vstf
