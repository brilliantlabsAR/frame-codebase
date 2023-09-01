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

#  for micropython 
# Include the core environment definitions
include frame_network_core/micropython/py/mkenv.mk
PY_SRC = frame_network_core/micropython/py

MICROPY_ROM_TEXT_COMPRESSION ?= 1
# Which python files to freeze into the firmware are listed in here
FROZEN_MANIFEST = frame_network_core/modules/frozen-manifest.py
# Include py core make definitions
include frame_network_core/micropython/py/py.mk


# Define the toolchain prefix for ARM GCC
CROSS_COMPILE = arm-none-eabi-

# C source files
APPLICATION_CORE_SOURCE_FILES += frame_application_core/main.c
APPLICATION_CORE_SOURCE_FILES += nrfx/drivers/src/nrfx_clock.c
APPLICATION_CORE_SOURCE_FILES += nrfx/drivers/src/nrfx_gpiote.c
APPLICATION_CORE_SOURCE_FILES += nrfx/mdk/gcc_startup_nrf5340_application.S
APPLICATION_CORE_SOURCE_FILES += nrfx/mdk/system_nrf5340_application.c

NETWORK_CORE_SOURCE_FILES += mphalport.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/shared/readline/readline.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/shared/runtime/gchelper_generic.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/shared/runtime/interrupt_char.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/shared/runtime/pyexec.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/shared/runtime/stdout_helpers.c
# NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/shared/runtime/sys_stdio_mphal.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/shared/timeutils/timeutils.c

NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/acoshf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/asinfacosf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/asinhf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/atan2f.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/atanf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/atanhf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/ef_rem_pio2.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/ef_sqrt.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/erf_lgamma.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/fmodf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/kf_cos.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/kf_rem_pio2.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/kf_sin.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/kf_tan.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/log1pf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/math.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/nearbyintf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/roundf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/sf_cos.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/sf_erf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/sf_frexp.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/sf_ldexp.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/sf_modf.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/sf_sin.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/sf_tan.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/wf_lgamma.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/libm/wf_tgamma.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/littlefs/lfs2_util.c
# NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/littlefs/lfs2.c
NETWORK_CORE_SOURCE_FILES += frame_network_core/micropython/lib/uzlib/crc32.c

NETWORK_CORE_SOURCE_FILES += frame_network_core/main.c
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
NETWORK_CORE_FLAGS += -Iframe_network_core/micropython
NETWORK_CORE_FLAGS += -Iframe_network_core/micropython/py
NETWORK_CORE_FLAGS += -Iframe_network_core/micropython/lib/cmsis/inc
NETWORK_CORE_FLAGS += -Iframe_network_core/micropython/shared/readline
NETWORK_CORE_FLAGS += -Iframe_network_core/modules
NETWORK_CORE_FLAGS += -Ibuild


SHARED_FLAGS += --specs=nano.specs
SHARED_FLAGS += -Wl,--gc-sections

# for micropython headers generation flags
# CFLAGS += $(SHARED_FLAGS)
CFLAGS += $(NETWORK_CORE_FLAGS)
CFLAGS += $(SHARED_FLAGS)
LDFLAGS += $(SHARED_FLAGS)
LDFLAGS += $(NETWORK_CORE_FLAGS)

SRC_QSTR = $(SRC_USERMOD_PATHFIX_C) $(SRC_USERMOD_PATHFIX_CXX)
SRC_QSTR += $(addprefix frame_network_core/micropython/,$(filter-out $(SRC_QSTR_IGNORE),$(PY_CORE_O_BASENAME:.o=.c)))
# PY_CORE_O_BASE_NAME files not sure this needed or not ()

NETWORK_CORE_SOURCE_FILES +=$(SRC_QSTR)  

# Micropython header making rules from py.mk and mkrules.mk
MICROPYTHON_HEADERS = $(HEADER_BUILD)/qstrdefs.generated.h $(HEADER_BUILD)/mpversion.h $(HEADER_BUILD)/moduledefs.h $(HEADER_BUILD)/root_pointers.h $(HEADER_BUILD)/compressed.data.h $(BUILD)/frozen_content.c

all:build/application-core.elf $(MICROPYTHON_HEADERS) build/network-core.elf
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

include frame_network_core/micropython/py/mkrules.mk