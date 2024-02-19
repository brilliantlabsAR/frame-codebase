# defaults
#SIM ?= verilator
#SIM ?= icarus
SIM ?= modelsim
TOPLEVEL_LANG ?= verilog

VERILOG_FILES += \
        ebr_tb.sv \
        ../../jlib/dp_ram.sv \
        ../../jlib/dp_ram_be.sv \

VERILOG_INCLUDE_DIRS += $(realpath ../../jisp ../../jlib)

VERILOG_FILES += \
        ../../../../radiant/jisp/ram_dp_w18_d360/rtl/ram_dp_w18_d360.v \
        ../../../../radiant/jisp/ram_dp_w64_b8_d2880/rtl/ram_dp_w64_b8_d2880.v \
        ../../../../radiant/jisp/ram_dp_w64_b8_d1440/rtl/ram_dp_w64_b8_d1440.v

VERILOG_FILES += \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/EBR_CORE.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/ebr_hw.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/fifo_new.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/ebr_polctl.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/ebr_cfg_in.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/ebr_fbuf.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/ebr_pwrup.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/ebr_tdp.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/ebr_inbuf.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/ebr_pwrsw_vcc.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/PDP16K.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl/PDP16K_MODE.v

VERILOG_FILES += \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/uaplatform/VHI.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/uaplatform/VLO.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/uaplatform/ebr_hw.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/uaplatform/GSR.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/uaplatform/GSR_CORE.v \
        $(LATTICE_ROOT)/cae_library/simulation/verilog/uaplatform/gsr_center.v

VERILOG_INCLUDE_DIRS += $(realpath $(LATTICE_ROOT)/cae_library/simulation/verilog/lifcl $(LATTICE_ROOT)/cae_library/simulation/verilog/uaplatform)

VERILOG_SOURCES += $(realpath $(VERILOG_FILES))

ifeq ($(SIM),verilator)
        EXTRA_ARGS += --trace --trace-structs --timing
        #EXTRA_ARGS += -Wno-BADSTDPRAGMA
        EXTRA_ARGS += -Wall -Wno-fatal -Wno-WIDTHTRUNC -Wno-WIDTHEXPAND -Wno-ASCRANGE -Wno-PINCONNECTEMPTY
endif
ifeq ($(SIM),modelsim)
        #EXTRA_ARGS += -32
        export COCOTB_RESOLVE_X=ZEROS
endif

TOPLEVEL = ebr_tb

# MODULE is the basename of the Python test file
MODULE = test_ebr
export PYTHONPATH := $(realpath ../jcommon):$(PYTHONPATH)

all: ../../../../radiant/jisp/ram_dp_w18_d360/rtl/ram_dp_w18_d360.v ../../../../radiant/jisp/ram_dp_w64_b8_d2880/rtl/ram_dp_w64_b8_d2880.v ../../../../radiant/jisp/ram_dp_w64_b8_d1440/rtl/ram_dp_w64_b8_d1440.v
%.v:
	make -C ../../../../radiant/jisp

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -rf __pycache__ results.xml obj_dir dump.vcd transcript modelsim.ini

