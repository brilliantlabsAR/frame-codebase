# TODO: Delete this file once it's no longer possible to use the devkit

MAKEFILE_PATH = $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

BUILD_FOLDER_PATH = $(MAKEFILE_PATH)/../../build

FPGA_RTL_SOURCE_FILES := $(shell find . -name '*.sv')

$(BUILD_FOLDER_PATH)/fpga_rtl_evn.bit: $(FPGA_RTL_SOURCE_FILES)
	mkdir -p $(BUILD_FOLDER_PATH)
	
	cd $(MAKEFILE_PATH) && \
		iverilog -Wall \
				 -g2012 \
				 -o /dev/null \
				 -i top.sv

	yosys -p "synth_nexus \
		  -json $(BUILD_FOLDER_PATH)/fpga_rtl_evn.json" \
		  $(MAKEFILE_PATH)/top.sv

	nextpnr-nexus --device LIFCL-40-8BG400 \
			      --pdc $(MAKEFILE_PATH)/evn_pinout.pdc \
				  --json $(BUILD_FOLDER_PATH)/fpga_rtl_evn.json \
				  --fasm $(BUILD_FOLDER_PATH)/fpga_rtl_evn.fasm

	prjoxide pack $(BUILD_FOLDER_PATH)/fpga_rtl_evn.fasm $@

flash_evn: $(BUILD_FOLDER_PATH)/fpga_rtl_evn.bit
	openFPGALoader -m $^

clean:
	rm -rf $(BUILD_FOLDER_PATH)