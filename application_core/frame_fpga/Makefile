SOURCE_FILES := $(shell find . -name '*.sv')

frame_fpga.h: build/frame_fpga.bit
	xxd -i $^ fpga_binfile_ram.h
	sed '1s/^/const /' fpga_binfile_ram.h > $@
	rm fpga_binfile_ram.h

build/frame_fpga.bit: build/frame_fpga.json
	nextpnr-nexus --device LIFCL-17-7UWG72 \
			      --pdc frame_fpga_pinout.pdc \
				  --json $^ \
				  --fasm build/frame_fpga.fasm
	prjoxide pack build/frame_fpga.fasm $@

# TODO remove this once we can no longer use the dev kit
build/lifcl_evn.bit: build/frame_fpga.json
	nextpnr-nexus --device LIFCL-40-8BG400 \
	              --pdc lifcl_evn_pinout.pdc \
				  --json $^ \
				  --fasm build/lifcl_evn.fasm
	prjoxide pack build/lifcl_evn.fasm $@

build/frame_fpga.json: $(SOURCE_FILES)
	mkdir -p build
	iverilog -Wall -g2012 -o build/frame_fpga.out -i top.sv
	yosys -p "synth_nexus -json $@" top.sv

# TODO remove this once we can no longer use the dev kit
flash_evn: build/lifcl_evn.bit
	openFPGALoader -m $^

clean:
	rm -rf build/