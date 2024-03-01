# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

ifeq ($(SIM),verilator)
VERILOG_FILES += \
        ../../jlib/dp_ram.sv \
        ../../jlib/dp_ram_be.sv
endif

VERILOG_FILES += \
        ../../jisp/jisp.sv \
        ../../jisp/mcu_buffer.sv \
        ../../jisp/rgb2yuv.sv \
        ../../jisp/subsample.sv

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

VERILOG_FILES += \
        ../../image_buffer.sv \
        ../../rgb_cdc.sv \
        ../../jenc_cdc.sv \
        ../../../reset/reset_sync.sv \
        ./jenc_test_top.sv
 
VERILOG_SOURCES += $(realpath $(VERILOG_FILES))
VERILOG_INCLUDE_DIRS += $(realpath ../../jisp  ../../jenc ../../jlib)

ifeq ($(SIM),verilator)
        EXTRA_ARGS += +define+__JLIB_VH__ # ugly ugly
        EXTRA_ARGS += --trace --trace-structs
        EXTRA_ARGS += -Wall -Wno-fatal -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-ASCRANGE -Wno-PINCONNECTEMPTY
endif

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
# TOPLEVEL = dct_1d_aan
#TOPLEVEL =  jenc
#TOPLEVEL =  dct_2d
TOPLEVEL =  jenc_test_top

# MODULE is the basename of the Python test file
MODULE = test_jenc
export PYTHONPATH := $(realpath ../python_misc):$(realpath ../jcommon):$(realpath ../jed):$(PYTHONPATH)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf __pycache__ results.xml obj_dir
	rm -rf jpeg_out.jpg rgb_out.bmp ecs_out.bin
