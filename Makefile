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
	libraries/lua/lapi.c \
	libraries/lua/lauxlib.c \
	libraries/lua/lbaselib.c \
	libraries/lua/lcode.c \
	libraries/lua/lcorolib.c \
	libraries/lua/lctype.c \
	libraries/lua/ldblib.c \
	libraries/lua/ldebug.c \
	libraries/lua/ldo.c \
	libraries/lua/ldump.c \
	libraries/lua/lfunc.c \
	libraries/lua/lgc.c \
	libraries/lua/linit.c \
	libraries/lua/liolib.c \
	libraries/lua/llex.c \
	libraries/lua/lmathlib.c \
	libraries/lua/lmem.c \
	libraries/lua/loadlib.c \
	libraries/lua/lobject.c \
	libraries/lua/lopcodes.c \
	libraries/lua/loslib.c \
	libraries/lua/lparser.c \
	libraries/lua/lstate.c \
	libraries/lua/lstring.c \
	libraries/lua/lstrlib.c \
	libraries/lua/ltable.c \
	libraries/lua/ltablib.c \
	libraries/lua/ltm.c \
	libraries/lua/lundump.c \
	libraries/lua/lutf8lib.c \
	libraries/lua/lvm.c \
	libraries/lua/lzio.c \
	libraries/nrfx/drivers/src/nrfx_gpiote.c \
	libraries/nrfx/drivers/src/nrfx_ipc.c \
	libraries/nrfx/drivers/src/nrfx_pdm.c \
	libraries/nrfx/drivers/src/nrfx_qspi.c \
	libraries/nrfx/drivers/src/nrfx_rtc.c \
	libraries/nrfx/drivers/src/nrfx_spim.c \
	libraries/nrfx/drivers/src/nrfx_systick.c \
	libraries/nrfx/drivers/src/nrfx_twim.c \
	libraries/nrfx/helpers/nrfx_flag32_allocator.c \
	libraries/nrfx/mdk/system_nrf52840.c \
	libraries/segger/SEGGER_RTT.c \
	source/bluetooth.c \
	source/error_logging.c \
	source/i2c.c \
	source/lua_libraries/microphone.c \
	source/luaport.c \
	source/main.c \
	source/spi.c \
	source/startup.c \
	source/syscalls.c \

FPGA_RTL_SOURCE_FILES := $(shell find fpga | egrep '.sv|.pdc')

# Header file paths
FLAGS += \
	-Ifpga \
	-Ilibraries/cmsis/CMSIS/Core/Include \
	-Ilibraries/lua \
	-Ilibraries/nrfx \
	-Ilibraries/nrfx/drivers/include \
	-Ilibraries/nrfx/hal \
	-Ilibraries/nrfx/mdk \
	-Ilibraries/nrfx/soc \
	-Ilibraries/picolibc \
	-Ilibraries/segger \
	-Ilibraries/softdevice/include \
	-Isource \
	-Isource/lua_libraries \

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
	-O2 \
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
	-Llibraries/picolibc \

# Link required libraries
LIBS += \
	-lc \
	-lgcc \

build/frame.hex: $(C_FILES) fpga/fpga_application.h

	@mkdir -p build
	@arm-none-eabi-gcc $(FLAGS) -o build/frame.elf $(C_FILES) $(LIBS)
	@arm-none-eabi-objcopy -O ihex build/frame.elf build/frame.hex
	@arm-none-eabi-size build/frame.elf


fpga/fpga_application.h: $(FPGA_RTL_SOURCE_FILES)
	
	@mkdir -p build

	@cd fpga && \
	 iverilog -Wall \
	          -g2012 \
	          -o /dev/null \
	          -i top.sv

	@yosys -p "synth_nexus \
	       -json build/fpga_application.json" \
	       fpga/top.sv

	@nextpnr-nexus --device LIFCL-17-7UWG72 \
	               --pdc fpga/fpga_pinout.pdc \
	               --json build/fpga_application.json \
	               --fasm build/fpga_application.fasm

	@prjoxide pack build/fpga_application.fasm build/fpga_application.bit
	
	@xxd -name fpga_application \
	     -include build/fpga_application.bit \
		 build/fpga_application_temp.h

	@sed '1s/^/const /' build/fpga_application_temp.h > fpga/fpga_application.h


release:
	@echo TODO

clean:
	rm -rf build/

flash: build/frame.hex
	nrfjprog -q --program libraries/softdevice/*.hex --chiperase
	nrfjprog -q --program build/frame.hex
	nrfjprog --reset

recover:
	nrfjprog --recover