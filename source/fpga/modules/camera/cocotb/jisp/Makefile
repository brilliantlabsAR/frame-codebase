# defaults
SIM ?= verilator
TOPLEVEL_LANG ?= verilog

VERILOG_FILES = \
        ../../jisp/jisp.sv \
        ../../jisp/mcu_buffer.sv \
        ../../jisp/rgb2yuv.sv \
        ../../jisp/subsample.sv \
        ../../lib/dp_ram.sv

VERILOG_SOURCES += $(realpath $(VERILOG_FILES))
VERILOG_INCLUDE_DIRS += $(realpath ../../jisp ../../jlib)

ifeq ($(SIM),verilator)
        EXTRA_ARGS += --trace --trace-structs --timing
        EXTRA_ARGS += -Wall -Wno-fatal -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-ASCRANGE -Wno-PINCONNECTEMPTY
endif

TOPLEVEL =  jisp

# MODULE is the basename of the Python test file
MODULE = test_jisp
export PYTHONPATH := $(realpath ../../python):$(realpath ../jcommon):$(PYTHONPATH)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf __pycache__ results.xml obj_dir
