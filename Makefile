#
# This file is a part https://github.com/brilliantlabsAR/frame-micropython
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

# Use date and time as build version "vYY.DDD.HHMM". := forces evaluation once
BUILD_VERSION := $(shell TZ= date +v%y.%j.%H%M)
GIT_COMMIT := $(shell git rev-parse --short HEAD)

# Source files
SHARED_C_FILES += error_helpers.c
SHARED_C_FILES += interprocessor_messaging.c
SHARED_C_FILES += nrfx/drivers/src/nrfx_ipc.c
SHARED_C_FILES += nrfx/helpers/nrfx_flag32_allocator.c

# Header file paths
SHARED_FLAGS += -I.
SHARED_FLAGS += -Icmsis/CMSIS/Core/Include
SHARED_FLAGS += -Inrfx
SHARED_FLAGS += -Inrfx/drivers/include
SHARED_FLAGS += -Inrfx/hal
SHARED_FLAGS += -Inrfx/mdk
SHARED_FLAGS += -Inrfx/soc
SHARED_FLAGS += -Isegger

# Warnings
SHARED_FLAGS += -Wall
SHARED_FLAGS += -Werror
SHARED_FLAGS += -Wdouble-promotion 
SHARED_FLAGS += -Wfloat-conversion

# Build options and optimizations
SHARED_FLAGS += -falign-functions=16
SHARED_FLAGS += -fdata-sections 
SHARED_FLAGS += -ffunction-sections 
SHARED_FLAGS += -flto
SHARED_FLAGS += -fmax-errors=1
SHARED_FLAGS += -fno-common
SHARED_FLAGS += -fno-delete-null-pointer-checks
SHARED_FLAGS += -fno-strict-aliasing
SHARED_FLAGS += -fshort-enums
SHARED_FLAGS += -g3
SHARED_FLAGS += -mabi=aapcs
SHARED_FLAGS += -mcmse
SHARED_FLAGS += -mthumb
SHARED_FLAGS += -Os
SHARED_FLAGS += -std=gnu17

# Preprocessor defines
SHARED_FLAGS += -DBUILD_VERSION='"$(BUILD_VERSION)"'
SHARED_FLAGS += -DGIT_COMMIT='"$(GIT_COMMIT)"'
SHARED_FLAGS += -DNDEBUG

# Linker options
SHARED_FLAGS += --specs=nano.specs
SHARED_FLAGS += -Wl,--gc-sections

# Link required libraries
SHARED_FLAGS += -lm -lc -lnosys -lgcc

all: build/application_core.elf build/network_core.elf
	@arm-none-eabi-objcopy -O ihex build/application_core.elf build/application_core.hex
	@arm-none-eabi-objcopy -O ihex build/network_core.elf build/network_core.hex

flash: all
	nrfjprog -q --coprocessor CP_APPLICATION --program build/application_core.hex --sectorerase
	nrfjprog -q --coprocessor CP_NETWORK --program build/network_core.hex --sectorerase
	nrfjprog --reset

clean:
	rm -rf build/
	rm -rf network_core/micropython_generated/

recover:
	nrfjprog --recover

release:
	@echo TODO

include network_core/network_core.mk

include application_core/application_core.mk