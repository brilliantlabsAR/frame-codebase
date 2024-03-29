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

camera:
	@mkdir -p simulation
	
	@iverilog -Wall \
			  -g2012 \
			  -I ../../.. \
			  -D TESTBENCH=1 \
			  -o simulation/camera_tb.out \
			  -i camera/camera_tb.sv
	exit
	@vvp simulation/camera_tb.out \
		 -fst

	@gtkwave simulation/camera_tb.fst \
			 camera/camera_tb.gtkw

debayer:
	@mkdir -p simulation
	
	@iverilog -Wall \
			  -g2012 \
			  -I ../../.. \
			  -o simulation/debayer_tb.out \
			  -i debayer/debayer_tb.sv
	exit
	@vvp simulation/debayer_tb.out \
		 -fst

	@gtkwave simulation/debayer_tb.fst \
			 debayer/debayer_tb.gtkw

image_buffer:
	@mkdir -p simulation
	
	@iverilog -Wall \
			  -g2012 \
			  -I ../../.. \
			  -o simulation/image_buffer_tb.out \
			  -i image_buffer/image_buffer_tb.sv
	exit
	@vvp simulation/image_buffer_tb.out \
		 -fst

	@gtkwave simulation/image_buffer_tb.fst \
			 image_buffer/image_buffer_tb.gtkw

clean:
	@rm -rf simulation
	@echo Cleaned

.PHONY: camera csi debayer image_buffer spi clean