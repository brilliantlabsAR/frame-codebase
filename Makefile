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
SHARED_C_FILES += \
	error_helpers.c \
	interprocessor_messaging.c \
	nrfx/drivers/src/nrfx_ipc.c \
	nrfx/helpers/nrfx_flag32_allocator.c \

APPLICATION_CORE_C_FILES += \
	application_core/lua/lapi.c \
	application_core/lua/lauxlib.c \
	application_core/lua/lbaselib.c \
	application_core/lua/lcode.c \
	application_core/lua/lcorolib.c \
	application_core/lua/lctype.c \
	application_core/lua/ldblib.c \
	application_core/lua/ldebug.c \
	application_core/lua/ldo.c \
	application_core/lua/ldump.c \
	application_core/lua/lfunc.c \
	application_core/lua/lgc.c \
	application_core/lua/linit.c \
	application_core/lua/liolib.c \
	application_core/lua/llex.c \
	application_core/lua/lmathlib.c \
	application_core/lua/lmem.c \
	application_core/lua/loadlib.c \
	application_core/lua/lobject.c \
	application_core/lua/lopcodes.c \
	application_core/lua/loslib.c \
	application_core/lua/lparser.c \
	application_core/lua/lstate.c \
	application_core/lua/lstring.c \
	application_core/lua/lstrlib.c \
	application_core/lua/ltable.c \
	application_core/lua/ltablib.c \
	application_core/lua/ltm.c \
	application_core/lua/lundump.c \
	application_core/lua/lutf8lib.c \
	application_core/lua/lvm.c \
	application_core/lua/lzio.c \
	application_core/luaport.c \
	application_core/main.c \
	nrfx/drivers/src/nrfx_gpiote.c \
	nrfx/drivers/src/nrfx_qspi.c \
	nrfx/drivers/src/nrfx_rtc.c \
	nrfx/drivers/src/nrfx_spim.c \
	nrfx/drivers/src/nrfx_systick.c \
	nrfx/drivers/src/nrfx_twim.c \
	nrfx/mdk/gcc_startup_nrf5340_application.S \
	nrfx/mdk/system_nrf5340_application.c \

NETWORK_CORE_C_FILES += \
	network_core/main.c \
	nrfx/mdk/gcc_startup_nrf5340_network.S \
	nrfx/mdk/system_nrf5340_network.c \
	segger/SEGGER_RTT_Syscalls_GCC.c \
	segger/SEGGER_RTT.c \

FPGA_RTL_SOURCE_FILES := $(shell find . -name '*.sv')

# Header file paths
SHARED_FLAGS += \
	-I. \
	-Icmsis/CMSIS/Core/Include \
	-Inrfx \
	-Inrfx/drivers/include \
	-Inrfx/hal \
	-Inrfx/mdk \
	-Inrfx/soc \
	-Isegger \

APPLICATION_CORE_FLAGS += \
	-Iapplication_core \
	-Iapplication_core/lua \

NETWORK_CORE_FLAGS += \
	-Inetwork_core \

# Warnings
SHARED_FLAGS += \
	-Wall \
	-Wdouble-promotion  \
	-Wfloat-conversion \

# Build options and optimizations
SHARED_FLAGS += \
	-falign-functions=16 \
	-fdata-sections  \
	-ffunction-sections  \
	-fmax-errors=1 \
	-fno-delete-null-pointer-checks \
	-fno-strict-aliasing \
	-fshort-enums \
	-g \
	-mabi=aapcs \
	-mcmse \
	-mthumb \
	-O2 \
	-std=gnu17 \

APPLICATION_CORE_FLAGS += \
	-mcpu=cortex-m33 \
	-mfloat-abi=hard \

NETWORK_CORE_FLAGS += \
	-mcpu=cortex-m33+nodsp \
	-mfloat-abi=soft \

# Preprocessor defines
SHARED_FLAGS += \
	-DBUILD_VERSION='"$(BUILD_VERSION)"' \
	-DGIT_COMMIT='"$(GIT_COMMIT)"' \
	-DNDEBUG \

APPLICATION_CORE_FLAGS += \
	-DNRF5340_XXAA_APPLICATION \

NETWORK_CORE_FLAGS += \
	-DNRF5340_XXAA_NETWORK \

# Linker options
SHARED_FLAGS += \
	-Wl,--gc-sections \

# Linker script paths
APPLICATION_CORE_FLAGS += \
	-T application_core/memory_layout.ld \

NETWORK_CORE_FLAGS += \
	-T network_core/memory_layout.ld \

SHARED_FLAGS += \
	-Lnrfx/mdk \

# Link required libraries
SHARED_LIBS += \
	-lc \
	-lm \
	-lnosys \

all: build/application_core.elf \
     build/network_core.elf

	@arm-none-eabi-objcopy -O ihex build/application_core.elf build/application_core.hex
	@arm-none-eabi-objcopy -O ihex build/network_core.elf build/network_core.hex
	@arm-none-eabi-size $^


build/application_core.elf: $(SHARED_C_FILES) \
                            $(APPLICATION_CORE_C_FILES) \
                            | application_core/fpga_application.h

	@mkdir -p build
	@arm-none-eabi-gcc $(SHARED_FLAGS) $(APPLICATION_CORE_FLAGS) -o $@ $^ $(SHARED_LIBS)


build/network_core.elf: $(SHARED_C_FILES) \
                        $(NETWORK_CORE_C_FILES)

	@mkdir -p build
	@arm-none-eabi-gcc $(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) -o $@ $^ $(SHARED_LIBS)


application_core/fpga_application.h: $(FPGA_RTL_SOURCE_FILES)
	
	@mkdir -p build

	@cd application_core/fpga_rtl && \
	    iverilog -Wall \
	             -g2012 \
	             -o /dev/null \
	             -i top.sv

	@yosys -p "synth_nexus \
	       -json build/fpga_rtl.json" \
	       application_core/fpga_rtl/top.sv

	@nextpnr-nexus --device LIFCL-17-7UWG72 \
	               --pdc application_core/fpga_rtl/fpga_pinout.pdc \
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
	nrfjprog -q --coprocessor CP_APPLICATION --program build/application_core.hex --sectorerase
	nrfjprog -q --coprocessor CP_NETWORK --program build/network_core.hex --sectorerase
	nrfjprog --reset

recover:
	nrfjprog --recover