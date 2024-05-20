#
# Authored by: Robert Metchev / Chips & Scripts (rmetchev@ieee.org)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#

SHELL=/bin/bash
# defaults
#SIM ?= verilator
SIM ?= modelsim
export SIM := $(SIM)
TOPLEVEL_LANG ?= verilog

# Sim control
GATE_SIM = 0
SDF_ANNO = 0
JPEG_SEL = 1
export GATE_SIM := $(GATE_SIM)
export JPEG_SEL := $(JPEG_SEL)

ifeq ($(IMG16X16),1)
SENSOR_X_SIZE = 20
SENSOR_Y_SIZE = 20
IMAGE_X_SIZE = 16
IMAGE_Y_SIZE = 16
export SENSOR_X_SIZE := $(SENSOR_X_SIZE)
export SENSOR_Y_SIZE := $(SENSOR_Y_SIZE)
export IMAGE_X_SIZE := $(IMAGE_X_SIZE)
export IMAGE_Y_SIZE := $(IMAGE_Y_SIZE)
endif

ifeq ($(SIM),icarus)
COMPILE_ARGS += $(SENSOR_X_SIZE:%=-DSENSOR_X_SIZE=%) $(SENSOR_Y_SIZE:%=-DSENSOR_Y_SIZE=%)
COMPILE_ARGS += $(IMAGE_X_SIZE:%=-DIMAGE_X_SIZE=%) $(IMAGE_Y_SIZE:%=-DIMAGE_Y_SIZE=%)
COMPILE_ARGS += $(QF0:%=-DQF0=%) $(QF1:%=-DQF1=%) $(QF2:%=-DQF2=%) $(QF3:%=-DQF3=%)
else # verilator + modelsim
EXTRA_ARGS += $(SENSOR_X_SIZE:%=+define+SENSOR_X_SIZE=%) $(SENSOR_Y_SIZE:%=+define+SENSOR_Y_SIZE=%)
EXTRA_ARGS += $(IMAGE_X_SIZE:%=+define+IMAGE_X_SIZE=%) $(IMAGE_Y_SIZE:%=+define+IMAGE_Y_SIZE=%)
EXTRA_ARGS += $(QF0:%=+define+QF0=%) $(QF1:%=+define+QF1=%) $(QF2:%=+define+QF2=%) $(QF3:%=+define+QF3=%)
endif

# gate level
FRAME_VO = frame_frame_vo.vo
FRAME_SDF = frame_frame_vo.sdf

# TB Top
VERILOG_FILES += \
        tb_top.sv \
        ../../../reset/reset_sync.sv \
        ../../../reset/global_reset_sync.sv

ifeq ($(GATE_SIM),1)

# Gate level netlist
VERILOG_FILES += $(FRAME_VO)

else
# JISP
VERILOG_FILES += \
        ../../jpeg_encoder/jisp/jisp.sv \
        ../../jpeg_encoder/jisp/mcu_buffer.sv \
        ../../jpeg_encoder/jisp/rgb2yuv.sv \
        ../../jpeg_encoder/jisp/subsample.sv

# JENC
VERILOG_FILES += \
        ../../jpeg_encoder/jpeg_encoder.sv \
        ../../jpeg_encoder/jenc/jenc.sv \
        ../../jpeg_encoder/jenc/dct_1d_aan.sv \
        ../../jpeg_encoder/jenc/dct_2d.sv \
        ../../jpeg_encoder/jenc/transpose.sv \
        ../../jpeg_encoder/jenc/zigzag.sv \
        ../../jpeg_encoder/jenc/quant.sv \
        ../../jpeg_encoder/jenc/quant_tables.sv \
        ../../jpeg_encoder/jenc/entropy.sv \
        ../../jpeg_encoder/jenc/huff_tables.sv \
        ../../jpeg_encoder/jenc/bitpacker.sv \
        ../../jpeg_encoder/jenc/bytepacker.sv \
        ../../jpeg_encoder/jenc/pre_cdc.sv \
        ../../jpeg_encoder/jlib/afifo.v

#        ../../jpeg_encoder/jenc/quant_seq_mult_15x13_p4.sv

# Camera
VERILOG_FILES += \
        ../../image_buffer.sv \
        ../../spi_registers.sv \
        ../../jpeg_encoder/jenc_cdc.sv \
        ../../crop.sv \
        ../../debayer.sv \
        ../../metering.sv \
        ../../camera.sv \

# Top
VERILOG_FILES += \
        ../../../../top.sv \
        ../../../spi/spi_peripheral.sv \
        ../../../spi/spi_register.sv \
        ../../../pll/pll_wrapper.sv \
        ../../../graphics/color_palette.sv \
        ../../../graphics/display_buffers.sv \
        ../../../graphics/display_driver.sv \
        ../../../graphics/graphics.sv \
        ../../../graphics/sprite_engine.sv \

# inferrable RAM models
VERILOG_FILES += \
        ../../jpeg_encoder/jlib/dp_ram.sv

#        ../../jpeg_encoder/jlib/dp_ram_be.sv
endif

ifeq ($(SIM),modelsim)
# Lattice verif models
VERILOG_FILES += \
        ../../testbenches/csi/source/csi/csi2_transmitter_ip/rtl/csi2_transmitter_ip.v \
        ../../testbenches/csi/source/csi/pixel_to_byte_ip/rtl/pixel_to_byte_ip.v \
        ../../testbenches/csi/source/csi/pll_sim_ip/rtl/pll_sim_ip.v

# RAM/ROM as EBR
VERILOG_FILES += \
        ../../jpeg_encoder/jlib/huffman_codes_rom_EBR.sv \
        ../../jpeg_encoder/jlib/ram_dp_w32_b4_d64_EBR.sv \
        ../../jpeg_encoder/jlib/ram_dp_w64_b8_d1440_EBR.sv \
        ../../jpeg_encoder/jlib/ram_dp_w64_b8_d2880_EBR.sv 

# Lattice models
#VERILOG_FILES += \
#        ../../../../radiant/huffman_codes_rom/ipgen/rtl/huffman_codes_rom.v \
#        ../../../../radiant/jenc/ram_dp_w32_b4_d64/rtl/ram_dp_w32_b4_d64.v \
#        ../../../../radiant/jisp/ram_dp_w18_d360/rtl/ram_dp_w18_d360.v \
#        ../../../../radiant/jisp/ram_dp_w64_b8_d2880/rtl/ram_dp_w64_b8_d2880.v \
#        ../../../../radiant/jisp/ram_dp_w64_b8_d1440/rtl/ram_dp_w64_b8_d1440.v \
#        ../../../../radiant/image_buffer/large_ram_dp_w32_d16k_q/rtl/large_ram_dp_w32_d16k_q.v

VERILOG_FILES += \
        ../../../../radiant/csi2_receiver_ip/rtl/csi2_receiver_ip.v \
        ../../../../radiant/byte_to_pixel_ip/rtl/byte_to_pixel_ip.v \
        ../../../../radiant/pll_ip/rtl/pll_ip.v
endif

VERILOG_SOURCES += $(realpath $(VERILOG_FILES))
VERILOG_INCLUDE_DIRS += $(realpath ../.. ../../jpeg_encoder ../../jpeg_encoder/jisp  ../../jpeg_encoder/jenc ../../jpeg_encoder/jlib .)

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
MODULE = test_camera
export PYTHONPATH := $(realpath ../python_common):$(realpath ../jed):$(PYTHONPATH)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

# Build Lattice IP (CSI, PLL, EBR) as prerequisite
.PHONY: ip
ip:
	make -C ../../testbenches/csi/source/csi/pll_sim_ip
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
	rm -rf jpeg_out.jpg rgb_out.bmp rgb_out.bmp.npy ecs_out.bin rgb332_out.npy
	rm -rf dump.vcd dump.vcd.fst dump.vcd.fst.hier 
	rm -rf dump.fst dump.fst.hier 
	rm -rf transcript modelsim.ini vsim.wlf vsim_stacktrace.vstf vish_stacktrace.vstf
	rm -rf frame_frame_vo.sdf_*.csd
	#make clean -C ../../testbenches/csi/source/csi/pll_sim_ip

.PHONY: bmp
bmp: rgb_out.bmp
%.bmp: %.bmp.npy
	python npy2bmp.py $< $@
