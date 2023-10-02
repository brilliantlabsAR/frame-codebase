#
# This file is a part https://github.com/brilliantlabsAR/frame-codebase
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
	application_core/main.c \
	nrfx/drivers/src/nrfx_gpiote.c \
	nrfx/drivers/src/nrfx_qspi.c \
	nrfx/drivers/src/nrfx_rtc.c \
	nrfx/drivers/src/nrfx_spim.c \
	nrfx/drivers/src/nrfx_systick.c \
	nrfx/drivers/src/nrfx_twim.c \
	nrfx/mdk/gcc_startup_nrf5340_application.S \
	nrfx/mdk/system_nrf5340_application.c \
	segger/SEGGER_RTT_printf.c \
	segger/SEGGER_RTT.c \

NETWORK_CORE_C_FILES += \
	network_core/main.c \
	nrfx/mdk/gcc_startup_nrf5340_network.S \
	nrfx/mdk/system_nrf5340_network.c \

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
	-flto \
	-fmax-errors=1 \
	-fno-common \
	-fno-delete-null-pointer-checks \
	-fno-strict-aliasing \
	-fshort-enums \
	-g3 \
	-mabi=aapcs \
	-mcmse \
	-mthumb \
	-Os \
	-std=gnu17 \

APPLICATION_CORE_FLAGS += \
	-mcpu=cortex-m33 \
	-mfloat-abi=hard \
	-mfpu=fpv4-sp-d16 \

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
	--specs=nano.specs \
	-Wl,--gc-sections \

# Linker script paths
APPLICATION_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_application.ld

NETWORK_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_network.ld

# Link required libraries
SHARED_LIBS += \
	-lm \
	-lc \
	-lnosys \
	-lgcc


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