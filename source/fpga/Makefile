#
# This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
#
# Authored by: Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
#              Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
#              Uma S. Gupta / Techno Exponent (umasankar@technoexponent.com)
#
# ISC Licence
#
# Copyright © 2023 Brilliant Labs Ltd.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#

BUILD := ../../build
TOOLCHAIN ?= YOSYS
RADIANT_PATH ?= /opt/lscc/radiant/2023.1/bin/lin64

fpga_application.h: $(shell find . | egrep '.sv|.pdc')
	@mkdir -p $(BUILD)

	@if [ $(TOOLCHAIN) = YOSYS ]; then make yosys; else make radiant; fi

yosys:
	@iverilog \
		-Wall \
		-g2012 \
		-o /dev/null \
		-i top.sv

	@yosys \
		-p "synth_nexus \
		-json $(BUILD)/fpga_application.json" \
		top.sv \
			> $(BUILD)/yosys.log

	@nextpnr-nexus \
		--seed 12346 \
		--device LIFCL-17-7UWG72 \
		--pdc fpga_pinout.pdc \
		--json $(BUILD)/fpga_application.json \
		--fasm $(BUILD)/fpga_application.fasm

	@prjoxide \
		pack \
		$(BUILD)/fpga_application.fasm \
		$(BUILD)/fpga_application.bit
	
	@make package

radiant:
	@$(RADIANT_PATH)/radiantc radiant/run.tcl

	@mv ./radiant/frame/frame_frame.bit $(BUILD)/fpga_application.bit

	@make package

package:
	@lz4 -9 -f -B4096 $(BUILD)/fpga_application.bit $(BUILD)/fpga_application

	@cd $(BUILD) && \
        xxd \
            -include fpga_application \
            fpga_application_temp.h

	@sed '1s/^/const /' $(BUILD)/fpga_application_temp.h > fpga_application.h

clean:
	@rm -rf $(BUILD) fpga_application.h
	@echo Cleaned

.PHONY: yosys radiant package clean