#
# Authored by: Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#

SHELL=/bin/bash
# defaults
SIM ?= modelsim
export SIM := $(SIM)
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES +=  \
        ./pll_tb.sv \
        ../../../modules/pll/pll_wrapper.sv

VERILOG_INCLUDE_DIRS += \
        . ../../common

MODULE := pll_test
TOPLEVEL := pll_tb

EXTRA_ARGS += \
        -L lifcl -L ovi_lifcl -L pmi_work \
        +DUMP

export COCOTB_RESOLVE_X=ZEROS

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf __pycache__ results.xml obj_dir
	rm -rf dump.vcd dump.vcd.fst dump.vcd.fst.hier 
	rm -rf dump.fst dump.fst.hier 
	rm -rf transcript modelsim.ini vsim.wlf vsim_stacktrace.vstf vish_stacktrace.vstf
	rm -rf frame_frame_vo.sdf_*.csd
	#make clean -C ../../testbenches/csi/source/csi/pll_sim_ip
	rm -rf f wlft*

# From README:
#
# $> conda create -n py3_32 # use 'sudo conda' to make this a global rather than local environment
# $> conda activate py3_32
# $> conda config --env --set subdir linux-32
# $> conda install python=3 gxx_linux-32
# $>
# $> pip install cocotb  # uses pip from 32-bit Python environment
# $>
# $> make clean
# $> make

ifneq ($(CONDA_DEFAULT_ENV),py3_32)
        $(error Make sure you are in a 32-bit Python environment)
endif 
