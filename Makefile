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

BUILD_VERSION := $(shell TZ= date +v%y.%j.%H%M) # := forces evaluation once
GIT_COMMIT := $(shell git rev-parse --short HEAD)

# Source files
C_FILES += \
	error_helpers.c \
	lua/lapi.c \
	lua/lauxlib.c \
	lua/lbaselib.c \
	lua/lcode.c \
	lua/lcorolib.c \
	lua/lctype.c \
	lua/ldblib.c \
	lua/ldebug.c \
	lua/ldo.c \
	lua/ldump.c \
	lua/lfunc.c \
	lua/lgc.c \
	lua/linit.c \
	lua/liolib.c \
	lua/llex.c \
	lua/lmathlib.c \
	lua/lmem.c \
	lua/loadlib.c \
	lua/lobject.c \
	lua/lopcodes.c \
	lua/loslib.c \
	lua/lparser.c \
	lua/lstate.c \
	lua/lstring.c \
	lua/lstrlib.c \
	lua/ltable.c \
	lua/ltablib.c \
	lua/ltm.c \
	lua/lundump.c \
	lua/lutf8lib.c \
	lua/lvm.c \
	lua/lzio.c \
	luaport.c \
	main.c \
	startup.c \
	stubs.c \
	nrfx/drivers/src/nrfx_gpiote.c \
	nrfx/drivers/src/nrfx_ipc.c \
	nrfx/drivers/src/nrfx_qspi.c \
	nrfx/drivers/src/nrfx_rtc.c \
	nrfx/drivers/src/nrfx_spim.c \
	nrfx/drivers/src/nrfx_systick.c \
	nrfx/drivers/src/nrfx_twim.c \
	nrfx/helpers/nrfx_flag32_allocator.c \
	nrfx/mdk/system_nrf52840.c \
	segger/SEGGER_RTT.c \

FPGA_RTL_SOURCE_FILES := $(shell find . -name '*.sv')

# Header file paths
FLAGS += \
	-I. \
	-Icmsis/CMSIS/Core/Include \
	-Ilua \
	-Inrfx \
	-Inrfx/drivers/include \
	-Inrfx/hal \
	-Inrfx/mdk \
	-Inrfx/soc \
	-Ipicolibc \
	-Isegger \

# Warnings
FLAGS += \
	-Wall \
	-Wdouble-promotion  \
	-Wfloat-conversion \

# Build options and optimizations
FLAGS += \
	-falign-functions=16 \
	-fdata-sections  \
	-ffunction-sections  \
	-fmax-errors=1 \
	-fno-delete-null-pointer-checks \
	-fno-strict-aliasing \
	-fshort-enums \
	-g \
	-mabi=aapcs \
	-mcpu=cortex-m4 \
	-mfloat-abi=hard \
	-mthumb \
	-nostdlib \
	-Os \
	-std=gnu17 \

# Preprocessor defines
FLAGS += \
	-DNRF52840_XXAA \
	-DBUILD_VERSION='"$(BUILD_VERSION)"' \
	-DGIT_COMMIT='"$(GIT_COMMIT)"' \
	-DNDEBUG \

# Linker options
FLAGS += \
	-Wl,--gc-sections \

# Linker script paths
FLAGS += \
	-T linker.ld \
	-Lpicolibc \

# Link required libraries
LIBS += \
	-lc \
	-lgcc \
	picolibc/libdummyhost.a \

build/frame.hex: $(C_FILES) | fpga_application.h

	@mkdir -p build
	@arm-none-eabi-gcc $(FLAGS) -o build/frame.elf $^ $(LIBS)
	@arm-none-eabi-objcopy -O ihex build/frame.elf $@
	@arm-none-eabi-size build/frame.elf


fpga_application.h: $(FPGA_RTL_SOURCE_FILES)
	
	@mkdir -p build

	@cd fpga_rtl && \
	    iverilog -Wall \
	             -g2012 \
	             -o /dev/null \
	             -i top.sv

	@yosys -p "synth_nexus \
	       -json build/fpga_rtl.json" \
	       fpga_rtl/top.sv

	@nextpnr-nexus --device LIFCL-17-7UWG72 \
	               --pdc fpga_rtl/fpga_pinout.pdc \
	               --json build/fpga_rtl.json \
	               --fasm build/fpga_rtl.fasm

	@prjoxide pack build/fpga_rtl.fasm build/fpga_rtl.bit
	
	@xxd -i build/fpga_rtl.bit build/fpga_binfile_ram.h
	@sed '1s/^/const /' build/fpga_binfile_ram.h > $@


release:
	@echo TODO

clean:
	rm -rf build/

flash: all
	nrfjprog -q --program build/frame.hex --sectorerase
	nrfjprog --reset

recover:
	nrfjprog --recover