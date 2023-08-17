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

# C source files
# SOURCE_FILES += config/nrfx_glue.c
# SOURCE_FILES += nrfx/drivers/src/nrfx_clock.c
# SOURCE_FILES += nrfx/drivers/src/nrfx_gpiote.c
# SOURCE_FILES += nrfx/drivers/src/nrfx_nvmc.c
# SOURCE_FILES += nrfx/drivers/src/nrfx_rtc.c
# SOURCE_FILES += nrfx/drivers/src/nrfx_systick.c
# SOURCE_FILES += nrfx/drivers/src/nrfx_systick.c
# SOURCE_FILES += nrfx/drivers/src/nrfx_timer.c
# SOURCE_FILES += nrfx/drivers/src/prs/nrfx_prs.c
# SOURCE_FILES += nrfx/helpers/nrfx_flag32_allocator.c
# SOURCE_FILES += segger/SEGGER_RTT_printf.c
# SOURCE_FILES += segger/SEGGER_RTT_Syscalls_GCC.c
# SOURCE_FILES += segger/SEGGER_RTT.c

APPLICATION_CORE_SOURCE_FILES += application_core_main.c
APPLICATION_CORE_SOURCE_FILES += nrfx/mdk/system_nrf5340_application.c
APPLICATION_CORE_SOURCE_FILES += nrfx/mdk/gcc_startup_nrf5340_application.S

# NETWORK_CORE_SOURCE_FILES += net/main.c
# NETWORK_CORE_SOURCE_FILES += net/rng_helper.c
# NETWORK_CORE_SOURCE_FILES += nrfx/drivers/src/nrfx_rng.c
# NETWORK_CORE_SOURCE_FILES += nrfx/mdk/system_nrf5340_network.c
# NETWORK_CORE_SOURCE_FILES += nrfx/mdk/gcc_startup_nrf5340_network.S
# NETWORK_CORE_SOURCE_FILES += sdk-nrfxlib/mpsl/lib/cortex-m33+nodsp/soft-float/libmpsl.a
# NETWORK_CORE_SOURCE_FILES += sdk-nrfxlib/softdevice_controller/lib/cortex-m33+nodsp/soft-float/libsoftdevice_controller_multirole.a
# NETWORK_CORE_SOURCE_FILES += sdk-nrfxlib/mpsl/fem/common/lib/cortex-m33+nodsp/soft-float/libmpsl_fem_common.a

# Header file paths
# FLAGS += -Iconfig
# FLAGS += -Ibuild
# FLAGS += -Inrfx
# FLAGS += -Inrfx/drivers
# FLAGS += -Inrfx/drivers/include
# FLAGS += -Inrfx/drivers/src
# FLAGS += -Inrfx/hal
# FLAGS += -Inrfx/helpers
FLAGS += -Inrfx/mdk
# FLAGS += -Inrfx/soc
FLAGS += -Icmsis/CMSIS/Core/Include
# FLAGS += -Isegger

# APPLICATION_CORE_FLAGS += -Iapp

# NETWORK_CORE_FLAGS += -Inet
# NETWORK_CORE_FLAGS += -Isdk-nrfxlib/mpsl/include
# NETWORK_CORE_FLAGS += -Isdk-nrfxlib/softdevice_controller/include

# Warnings
FLAGS += -Wall 
FLAGS += -Werror 
FLAGS += -Wdouble-promotion 
FLAGS += -Wfloat-conversion

# Build options and optimizations
FLAGS += -mthumb 
FLAGS += -mabi=aapcs
FLAGS += -std=gnu17
FLAGS += -Og -g3
FLAGS += -fdata-sections -ffunction-sections 
FLAGS += -fshort-enums
FLAGS += -fno-strict-aliasing
FLAGS += -fno-common
FLAGS += -flto

APPLICATION_CORE_FLAGS += -mcpu=cortex-m33
APPLICATION_CORE_FLAGS += -mfloat-abi=hard
APPLICATION_CORE_FLAGS += -mfpu=fpv4-sp-d16
APPLICATION_CORE_FLAGS += -fsingle-precision-constant

NETWORK_CORE_FLAGS += -mcpu=cortex-m33+nodsp
NETWORK_CORE_FLAGS += -mfloat-abi=soft

# Preprocessor defines
FLAGS += -DBUILD_VERSION='"$(BUILD_VERSION)"'
# FLAGS += -DNRF_TRUSTZONE_NONSECURE
# FLAGS += -DNDEBUG

APPLICATION_CORE_FLAGS += -DNRF5340_XXAA_APPLICATION
APPLICATION_CORE_FLAGS += -DFLOAT_ABI_HARD

NETWORK_CORE_FLAGS += -DNRF5340_XXAA_NETWORK
NETWORK_CORE_FLAGS += -DNRF_MCU_NETWORK

# Linker options & linker script paths
FLAGS += -Wl,--gc-sections
# FLAGS += -Xlinker -Map=$(@:.elf=.map)
FLAGS += --specs=nano.specs

APPLICATION_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_application.ld

NETWORK_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_network.ld

# Link required libraries
FLAGS += -lm -lc -lnosys -lgcc

all: build/application-core.elf build/network-core.elf
	@arm-none-eabi-objcopy -O ihex build/application-core.elf build/application-core.hex
	@# arm-none-eabi-objcopy -O ihex build/network-core.elf build/network-core.hex

build/application-core.elf: $(SOURCE_FILES) $(APPLICATION_CORE_SOURCE_FILES)
	@mkdir -p build
	@arm-none-eabi-gcc $(FLAGS) $(APPLICATION_CORE_FLAGS) -o $@ $^
	@arm-none-eabi-size $@

build/network-core.elf: $(SOURCE_FILES) $(NETWORK_CORE_SOURCE_FILES)
	@mkdir -p build
	@# arm-none-eabi-gcc $(FLAGS) $(NETWORK_CORE_SOURCE_FILES) -o $@ $^
	@# arm-none-eabi-size $@

flash:

clean:
	rm -rf build/

erase-chip:
	nrfjprog --recover

release:
