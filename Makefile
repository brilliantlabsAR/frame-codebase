#
# This file is part of the MicroPython for Frame project:
#      https://github.com/brilliantlabsAR/frame-micropython
#
# Authored by: Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
#              Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
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

# Use date and time as build version "vYY.DDD.HHMM". := forces evaluation once
BUILD_VERSION := $(shell TZ= date +v%y.%j.%H%M)
GIT_COMMIT := $(shell git rev-parse --short HEAD)

# C source files
APPLICATION_CORE_SOURCE_FILES += frame_application_core/main.c
APPLICATION_CORE_SOURCE_FILES += nrfx/drivers/src/nrfx_clock.c
APPLICATION_CORE_SOURCE_FILES += nrfx/drivers/src/nrfx_gpiote.c
APPLICATION_CORE_SOURCE_FILES += nrfx/mdk/gcc_startup_nrf5340_application.S
APPLICATION_CORE_SOURCE_FILES += nrfx/mdk/system_nrf5340_application.c

NETWORK_CORE_SOURCE_FILES += frame_network_core/main.c
NETWORK_CORE_SOURCE_FILES += nrfx/drivers/src/nrfx_rtc.c
NETWORK_CORE_SOURCE_FILES += nrfx/drivers/src/nrfx_spim.c
NETWORK_CORE_SOURCE_FILES += nrfx/drivers/src/nrfx_twim.c
NETWORK_CORE_SOURCE_FILES += nrfx/mdk/gcc_startup_nrf5340_network.S
NETWORK_CORE_SOURCE_FILES += nrfx/mdk/system_nrf5340_network.c

SHARED_SOURCE_FILES += error_helpers.c
SHARED_SOURCE_FILES += nrfx/helpers/nrfx_flag32_allocator.c
SHARED_SOURCE_FILES += segger/SEGGER_RTT_printf.c
SHARED_SOURCE_FILES += segger/SEGGER_RTT.c

# Header file paths
APPLICATION_CORE_FLAGS += -Iframe_application_core

NETWORK_CORE_FLAGS += -Iframe_network_core

SHARED_FLAGS += -I.
SHARED_FLAGS += -Icmsis/CMSIS/Core/Include
SHARED_FLAGS += -Inrfx
SHARED_FLAGS += -Inrfx/drivers
SHARED_FLAGS += -Inrfx/drivers/include
SHARED_FLAGS += -Inrfx/hal
SHARED_FLAGS += -Inrfx/helpers
SHARED_FLAGS += -Inrfx/mdk
SHARED_FLAGS += -Inrfx/soc
SHARED_FLAGS += -Isegger

# Warnings
SHARED_FLAGS += -Wall
SHARED_FLAGS += -Werror
SHARED_FLAGS += -Wdouble-promotion 
SHARED_FLAGS += -Wfloat-conversion

# Build options and optimizations
APPLICATION_CORE_FLAGS += -mcpu=cortex-m33
APPLICATION_CORE_FLAGS += -mfloat-abi=hard
APPLICATION_CORE_FLAGS += -mfpu=fpv4-sp-d16

NETWORK_CORE_FLAGS += -mcpu=cortex-m33+nodsp
NETWORK_CORE_FLAGS += -mfloat-abi=soft

SHARED_FLAGS += -falign-functions=16
SHARED_FLAGS += -fdata-sections 
SHARED_FLAGS += -ffunction-sections 
SHARED_FLAGS += -flto
SHARED_FLAGS += -fmax-errors=1
SHARED_FLAGS += -fno-common
SHARED_FLAGS += -fno-delete-null-pointer-checks
SHARED_FLAGS += -fno-strict-aliasing
SHARED_FLAGS += -fshort-enums
SHARED_FLAGS += -g
SHARED_FLAGS += -mabi=aapcs
SHARED_FLAGS += -mcmse
SHARED_FLAGS += -mthumb
SHARED_FLAGS += -Os
SHARED_FLAGS += -std=gnu17

# Preprocessor defines
APPLICATION_CORE_FLAGS += -DNRF5340_XXAA_APPLICATION

NETWORK_CORE_FLAGS += -DNRF5340_XXAA_NETWORK

SHARED_FLAGS += -DBUILD_VERSION='"$(BUILD_VERSION)"'
SHARED_FLAGS += -DGIT_COMMIT='"$(GIT_COMMIT)"'
SHARED_FLAGS += -DNDEBUG

# Linker options & linker script paths
APPLICATION_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_application.ld

NETWORK_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_network.ld

SHARED_FLAGS += --specs=nano.specs
SHARED_FLAGS += -Wl,--gc-sections

# Link required libraries
SHARED_FLAGS += -lm -lc -lnosys -lgcc

all: build/application-core.elf build/network-core.elf
	@arm-none-eabi-objcopy -O ihex build/application-core.elf build/application-core.hex
	@arm-none-eabi-objcopy -O ihex build/network-core.elf build/network-core.hex

build/application-core.elf: $(SHARED_SOURCE_FILES) $(APPLICATION_CORE_SOURCE_FILES)
	@mkdir -p build
	@arm-none-eabi-gcc $(SHARED_FLAGS) $(APPLICATION_CORE_FLAGS) -o $@ $^
	@arm-none-eabi-size $@

build/network-core.elf: $(SHARED_SOURCE_FILES) $(NETWORK_CORE_SOURCE_FILES)
	@mkdir -p build
	@arm-none-eabi-gcc $(SHARED_FLAGS) $(NETWORK_CORE_FLAGS) -o $@ $^
	@arm-none-eabi-size $@

flash: all
	nrfjprog -q --coprocessor CP_APPLICATION --program build/application-core.hex --sectorerase
	nrfjprog -q --coprocessor CP_NETWORK --program build/network-core.hex --sectorerase
	nrfjprog --reset

clean:
	rm -rf build/

recover:
	nrfjprog --recover

release:
