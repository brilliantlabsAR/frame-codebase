#
# Authored by: Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#

SHELL=/bin/bash
# defaults
SIM ?= verilator
#SIM ?= modelsim
export SIM := $(SIM)
TOPLEVEL_LANG ?= verilog

# Paths relative to tests directory
FPGA_PATH       := $(realpath $(TEST_PATH)/../../../../fpga)
COMMONS_PATH    := $(realpath $(TEST_PATH)/../../common)
MODULES_PATH    := $(realpath $(TEST_PATH)/../../../modules)
CAMERA_PATH     := $(realpath $(TEST_PATH)/../../../modules/camera)
JPEG_PATH       := $(realpath $(TEST_PATH)/../../../modules/camera/jpeg_encoder)

# Sim control
GATE_SIM = 0
SDF_ANNO = 0
export GATE_SIM := $(GATE_SIM)

# gate level
FRAME_VO = frame_frame_vo.vo
FRAME_SDF = frame_frame_vo.sdf

# TB Top
VERILOG_FILES += \
        $(COMMONS_PATH)/tb_top.sv \
        $(MODULES_PATH)/reset/reset_sync.sv \
        $(MODULES_PATH)/reset/global_reset_sync.sv

ifeq ($(GATE_SIM),1)

# Gate level netlist
VERILOG_FILES += $(FRAME_VO)

else
# JISP
VERILOG_FILES += \
        $(JPEG_PATH)/jisp/jisp.sv \
        $(JPEG_PATH)/jisp/mcu_buffer.sv \
        $(JPEG_PATH)/jisp/rgb2yuv.sv \
        $(JPEG_PATH)/jisp/subsample.sv

# JENC
VERILOG_FILES += \
        $(JPEG_PATH)/jpeg_encoder.sv \
        $(JPEG_PATH)/jenc/jenc.sv \
        $(JPEG_PATH)/jenc/dct_1d_aan.sv \
        $(JPEG_PATH)/jenc/dct_2d.sv \
        $(JPEG_PATH)/jenc/transpose.sv \
        $(JPEG_PATH)/jenc/zigzag.sv \
        $(JPEG_PATH)/jenc/quant.sv \
        $(JPEG_PATH)/jenc/quant_tables.sv \
        $(JPEG_PATH)/jenc/entropy.sv \
        $(JPEG_PATH)/jenc/huff_tables.sv \
        $(JPEG_PATH)/jenc/bit_pack.sv \
        $(JPEG_PATH)/jenc/byte_pack.sv \
        $(JPEG_PATH)/jenc/ff00.sv \
        $(JPEG_PATH)/jlib/psync1.sv \
        $(JPEG_PATH)/jlib/afifo.v

#        $(JPEG_PATH)/jenc/quant_seq_mult_15x13_p4.sv

# Camera
VERILOG_FILES += \
        $(CAMERA_PATH)/image_buffer.sv \
        $(CAMERA_PATH)/spi_registers.sv \
        $(JPEG_PATH)/jenc_cdc.sv \
        $(CAMERA_PATH)/crop.sv \
        $(CAMERA_PATH)/debayer.sv \
        $(CAMERA_PATH)/metering.sv \
        $(CAMERA_PATH)/gamma_correction.sv \
        $(CAMERA_PATH)/camera.sv \

# Top
VERILOG_FILES += \
        $(FPGA_PATH)/top.sv \
        $(MODULES_PATH)/spi/spi_peripheral.sv \
        $(MODULES_PATH)/spi/spi_register.sv \
        $(MODULES_PATH)/pll/pll_csr.sv \
        $(MODULES_PATH)/graphics/color_palette.sv \
        $(MODULES_PATH)/graphics/display_buffers.sv \
        $(MODULES_PATH)/graphics/display_driver.sv \
        $(MODULES_PATH)/graphics/graphics.sv \
        $(MODULES_PATH)/graphics/sprite_engine.sv \

# inferrable RAM models
VERILOG_FILES += \
        $(JPEG_PATH)/jlib/dp_ram.sv
        
ifneq ($(SIM),modelsim)
VERILOG_FILES += \
        $(JPEG_PATH)/jlib/dp_ram_be.sv \
        $(MODULES_PATH)/pll/clkswitch.v
endif
endif

ifeq ($(SIM),modelsim)
# Lattice verif models
# CSI/Lattice IP requires license to generate - copy the .v from somewhere else
VERILOG_FILES += \
        $(MODULES_PATH)/pll/pll_wrapper.sv \
        $(CAMERA_PATH)/testbenches/csi/source/csi/csi2_transmitter_ip/rtl/csi2_transmitter_ip.v \
        $(CAMERA_PATH)/testbenches/csi/source/csi/pixel_to_byte_ip/rtl/pixel_to_byte_ip.v \
        $(CAMERA_PATH)/testbenches/csi/source/csi/pll_sim_ip/rtl/pll_sim_ip.v

# RAM/ROM as EBR
VERILOG_FILES += \
        $(JPEG_PATH)/jlib/huffman_codes_rom_EBR.sv \
        $(JPEG_PATH)/jlib/ram_dp_w32_b4_d64_EBR.sv \
        $(JPEG_PATH)/jlib/ram_dp_w64_b8_d1440_EBR.sv \
        $(JPEG_PATH)/jlib/ram_dp_w64_b8_d2880_EBR.sv 

# Lattice models
#VERILOG_FILES += \
#        $(FPGA_PATH)/radiant/huffman_codes_rom/ipgen/rtl/huffman_codes_rom.v \
#        $(FPGA_PATH)/radiant/jenc/ram_dp_w32_b4_d64/rtl/ram_dp_w32_b4_d64.v \
#        $(FPGA_PATH)/radiant/jisp/ram_dp_w18_d360/rtl/ram_dp_w18_d360.v \
#        $(FPGA_PATH)/radiant/jisp/ram_dp_w64_b8_d2880/rtl/ram_dp_w64_b8_d2880.v \
#        $(FPGA_PATH)/radiant/jisp/ram_dp_w64_b8_d1440/rtl/ram_dp_w64_b8_d1440.v \
#        $(FPGA_PATH)/radiant/image_buffer/large_ram_dp_w32_d16k_q/rtl/large_ram_dp_w32_d16k_q.v

# CSI/Lattice IP requires license to generate - copy the .v from somewhere else
VERILOG_FILES += \
	$(FPGA_PATH)/radiant/csi2_receiver_ip/rtl/csi2_receiver_ip.v \
	$(FPGA_PATH)/radiant/byte_to_pixel_ip/rtl/byte_to_pixel_ip.v \
	$(FPGA_PATH)/radiant/pll_ip/rtl/pll_ip.v
endif

VERILOG_SOURCES += $(realpath $(VERILOG_FILES))
VERILOG_INCLUDE_DIRS += $(COMMONS_PATH) $(JPEG_PATH) $(JPEG_PATH)/jisp $(JPEG_PATH)/jenc $(JPEG_PATH)/jlib

ifeq ($(SIM),icarus)
        COMPILE_ARGS += -DCOCOTB_SIM=1
        COMPILE_ARGS += -DRADIANT
        COMPILE_ARGS += -DTOP_SIM
        COMPILE_ARGS += -DCOCOTB_ICARUS
else # verilator + modelsim
        EXTRA_ARGS += +define+COCOTB_SIM=1
        EXTRA_ARGS += +define+RADIANT
        EXTRA_ARGS += +define+TOP_SIM
endif

ifeq ($(SIM),icarus)
        COMPILE_ARGS += -DINFER_HUFFMAN_CODES_ROM    # rtl version
        COMPILE_ARGS += -DINFER_QUANTIZATION_TABLES_ROM    # rtl version
        COMPILE_ARGS += -DNO_MIPI_IP_SIM          # Simulate Bayer input
        COMPILE_ARGS += -DNO_PLL_SIM              # Emulate PLL
        COMPILE_ARGS += -Wall
        COMPILE_ARGS += -v
        #COMPILE_ARGS += -g2005-sv
endif
ifeq ($(SIM),verilator)
        EXTRA_ARGS += +define+INFER_HUFFMAN_CODES_ROM    # rtl version
        EXTRA_ARGS += +define+INFER_QUANTIZATION_TABLES_ROM    # rtl version
        EXTRA_ARGS += +define+NO_MIPI_IP_SIM    # Simulate Bayer input
        EXTRA_ARGS += +define+NO_PLL_SIM        # Emulate PLL
        EXTRA_ARGS += --timing
        ifneq ($(WAVES),0)
                EXTRA_ARGS += --trace --trace-structs --trace-fst
        endif
        WNO = fatal WIDTHTRUNC WIDTHEXPAND ASCRANGE EOFNEWLINE PINCONNECTEMPTY DECLFILENAME GENUNNAMED VARHIDDEN UNUSEDPARAM
        EXTRA_ARGS += -Wall $(WNO:%=-Wno-%)
endif
ifeq ($(SIM),modelsim)
        #EXTRA_ARGS += +define+USE_LATTICE_LARGE_RAM     # RTL vs. memory models explicitely
        EXTRA_ARGS += +define+USE_LATTICE_EBR           # use EBR explicitely
        EXTRA_ARGS += +define+COCOTB_MODELSIM
        EXTRA_ARGS += -suppress vlog-2244 -suppress  vlog-13314
ifeq ($(GATE_SIM),1)
        EXTRA_ARGS += -suppress vsim-3620
endif    
        EXTRA_ARGS += -L lifcl -L ovi_lifcl -L pmi_work
        EXTRA_ARGS += +memory
        export COCOTB_RESOLVE_X=ZEROS

ifeq ($(WAVES),1)
        EXTRA_ARGS += +DUMP
endif
        
ifeq ($(GATE_SIM),1)
        EXTRA_ARGS += +define+GATE_SIM
ifeq ($(SDF_ANNO),1)
        SIM_ARGS += +nosdferror -sdfmax /tb_top/dut=$(FRAME_SDF)
        #SIM_ARGS += +no_notifier
        #SIM_ARGS += +notimingchecks
endif
endif
endif

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL =  tb_top

# MODULE is the basename of the Python test file
MODULE = $(TEST_TOP)

export PYTHONPATH := $(realpath .):$(COMMONS_PATH)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

# Build Lattice IP (CSI, PLL, EBR) as prerequisite
.PHONY: ip
ip:
	make -C $(CAMERA_PATH)/testbenches/csi/source/csi/pll_sim_ip
ifeq ($(SIM),modelsim)
sim: ip
endif

ifeq ($(SIM),icarus)
        DUMP := sim_build/tb_top.fst
else
ifeq ($(SIM),verilator)
        DUMP := dump.fst
else #modelsim
        DUMP := dump.vcd
endif
endif

g gtkwave:
	gtkwave $(DUMP) -o -a 1.gtkw

clean::
	rm -rf __pycache__ results.xml obj_dir
	rm -rf dump.vcd dump.vcd.fst dump.vcd.fst.hier 
	rm -rf dump.fst dump.fst.hier 
	rm -rf transcript modelsim.ini vsim.wlf vsim_stacktrace.vstf vish_stacktrace.vstf
	rm -rf frame_frame_vo.sdf_*.csd
	#make clean -C ../../testbenches/csi/source/csi/pll_sim_ip
