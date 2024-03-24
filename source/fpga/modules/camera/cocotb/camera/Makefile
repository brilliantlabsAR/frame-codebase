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

IMG16X16 = 1
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

EXTRA_ARGS += $(SENSOR_X_SIZE:%=+define+SENSOR_X_SIZE=%)
EXTRA_ARGS += $(SENSOR_Y_SIZE:%=+define+SENSOR_Y_SIZE=%)

# gate level
FRAME_VO = frame_frame_vo.vo
FRAME_SDF = frame_frame_vo.sdf

# TB Top
VERILOG_FILES += \
        tb_top.sv

ifeq ($(GATE_SIM),1)

# Gate level netlist
VERILOG_FILES += $(FRAME_VO)

else
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

# Camera
VERILOG_FILES += \
        ../../image_buffer.sv \
        ../../rgb_cdc.sv \
        ../../jenc_cdc.sv \
        ../../crop.sv \
        ../../debayer.sv \
        ../../metering.sv \
        ../../camera.sv \

# Top
VERILOG_FILES += \
        ../../../../top.sv \
        ../../../reset/reset_sync.sv \
        ../../../reset/reset_global.sv \
        ../../../spi/spi_peripheral.sv \
        ../../../spi/spi_register.sv \
        ../../../graphics/color_palette.sv \
        ../../../graphics/display_buffers.sv \
        ../../../graphics/display_driver.sv \
        ../../../graphics/graphics.sv \
        ../../../graphics/sprite_engine.sv \

endif

ifeq ($(SIM),verilator)
# inferrable RAM models
VERILOG_FILES += \
        ../../jlib/dp_ram.sv \
        ../../jlib/dp_ram_be.sv
endif

ifeq ($(SIM),modelsim)
# Lattice verif models
VERILOG_FILES += \
        ../../../reset/reset_sync.sv \
        ../../../../radiant/sim_only/pll_sim_ip/rtl/pll_sim_ip.v \
        ../../../../radiant/sim_only/pixel_to_byte_ip/rtl/pixel_to_byte_ip.v \
        ../../../../radiant/sim_only/csi2_transmitter_ip/rtl/csi2_transmitter_ip.v

# Lattice models
VERILOG_FILES += \
        ../../../../radiant/jenc/ram_dp_w32_b4_d64/rtl/ram_dp_w32_b4_d64.v \
        ../../../../radiant/jisp/ram_dp_w18_d360/rtl/ram_dp_w18_d360.v \
        ../../../../radiant/jisp/ram_dp_w64_b8_d2880/rtl/ram_dp_w64_b8_d2880.v \
        ../../../../radiant/jisp/ram_dp_w64_b8_d1440/rtl/ram_dp_w64_b8_d1440.v \
        ../../../../radiant/image_buffer/large_ram_dp_w32_d16k_q/rtl/large_ram_dp_w32_d16k_q.v \
        ../../../../radiant/csi2_receiver_ip/rtl/csi2_receiver_ip.v \
        ../../../../radiant/byte_to_pixel_ip/rtl/byte_to_pixel_ip.v \
        ../../../../radiant/pll_ip/rtl/pll_ip.v
endif

VERILOG_SOURCES += $(realpath $(VERILOG_FILES))
VERILOG_INCLUDE_DIRS += $(realpath ../.. ../../jisp  ../../jenc ../../jlib .)

EXTRA_ARGS += +define+RADIANT
EXTRA_ARGS += +define+TOP_SIM
ifeq ($(SIM),verilator)
        EXTRA_ARGS += +define+NO_MIPI_IP_SIM            # Simulate Bayer input
        EXTRA_ARGS += +define+NO_PLL_IP_SIM            # Emulate PLL
        EXTRA_ARGS += --timing
        EXTRA_ARGS += --trace --trace-structs
        WNO = fatal WIDTHTRUNC WIDTHEXPAND ASCRANGE EOFNEWLINE PINCONNECTEMPTY DECLFILENAME GENUNNAMED VARHIDDEN UNUSEDPARAM
        EXTRA_ARGS += -Wall $(WNO:%=-Wno-%)
endif
ifeq ($(SIM),modelsim)
        #EXTRA_ARGS += +define+INFER_LARGE_RAM           # RTL vs. memory models explicitely
        EXTRA_ARGS += +define+USE_LATTICE_EBR           # use EBR explicitely
        EXTRA_ARGS += +define+COCOTB_MODELSIM
        EXTRA_ARGS += -suppress vlog-2244 -suppress  vlog-13314
        EXTRA_ARGS += -L lifcl -L ovi_lifcl -L pmi_work 
        export COCOTB_RESOLVE_X=ZEROS    
        
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
export PYTHONPATH := $(realpath ../python_misc):$(realpath ../jcommon):$(realpath ../jed):$(PYTHONPATH)

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

g gtkwave:
	gtkwave dump.vcd -o -a 1.gtkw
clean::
	rm -rf __pycache__ results.xml obj_dir
	rm -rf jpeg_out.jpg rgb_out.bmp rgb_out.bmp.npy ecs_out.bin dump.vcd
	rm -rf dump.vcd.fst dump.vcd.fst.hier
	rm -rf transcript modelsim.ini vsim.wlf vsim_stacktrace.vstf vish_stacktrace.vstf

.PHONY: bmp
bmp: rgb_out.bmp
%.bmp: %.bmp.npy
	python npy2bmp.py $< $@
