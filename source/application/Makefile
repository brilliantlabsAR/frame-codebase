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

BUILD_VERSION := $(shell TZ= date +v%y.%j.%H%M)
GIT_COMMIT := $(shell git rev-parse --short HEAD)

LIBRARIES := ../../libraries
BUILD := ../../build

# Source files
C_FILES += \
	main.c \
	bluetooth.c \
	flash.c \
	luaport.c \
	i2c.c \
	spi.c \
	lua_libraries/bluetooth.c \
	lua_libraries/camera.c \
	lua_libraries/display.c \
	lua_libraries/file.c \
	lua_libraries/microphone.c \
	lua_libraries/system.c \
	lua_libraries/time.c \
	lua_libraries/version.c \
	../error_logging.c \
	../startup.c \
	../syscalls.c \
	$(LIBRARIES)/littlefs/lfs_util.c \
	$(LIBRARIES)/littlefs/lfs.c \
	$(LIBRARIES)/lua/lapi.c \
	$(LIBRARIES)/lua/lauxlib.c \
	$(LIBRARIES)/lua/lbaselib.c \
	$(LIBRARIES)/lua/lcode.c \
	$(LIBRARIES)/lua/lcorolib.c \
	$(LIBRARIES)/lua/lctype.c \
	$(LIBRARIES)/lua/ldblib.c \
	$(LIBRARIES)/lua/ldebug.c \
	$(LIBRARIES)/lua/ldo.c \
	$(LIBRARIES)/lua/ldump.c \
	$(LIBRARIES)/lua/lfunc.c \
	$(LIBRARIES)/lua/lgc.c \
	$(LIBRARIES)/lua/linit.c \
	$(LIBRARIES)/lua/llex.c \
	$(LIBRARIES)/lua/lmathlib.c \
	$(LIBRARIES)/lua/lmem.c \
	$(LIBRARIES)/lua/loadlib.c \
	$(LIBRARIES)/lua/lobject.c \
	$(LIBRARIES)/lua/lopcodes.c \
	$(LIBRARIES)/lua/lparser.c \
	$(LIBRARIES)/lua/lstate.c \
	$(LIBRARIES)/lua/lstring.c \
	$(LIBRARIES)/lua/lstrlib.c \
	$(LIBRARIES)/lua/ltable.c \
	$(LIBRARIES)/lua/ltablib.c \
	$(LIBRARIES)/lua/ltm.c \
	$(LIBRARIES)/lua/lundump.c \
	$(LIBRARIES)/lua/lutf8lib.c \
	$(LIBRARIES)/lua/lvm.c \
	$(LIBRARIES)/lua/lzio.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_gpiote.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_pdm.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_rtc.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_saadc.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_spim.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_systick.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_twim.c \
	$(LIBRARIES)/nrfx/helpers/nrfx_flag32_allocator.c \
	$(LIBRARIES)/nrfx/mdk/system_nrf52840.c \
	$(LIBRARIES)/segger/SEGGER_RTT.c \

# Header file paths
FLAGS += \
	-I. \
	-I.. \
	-I../fpga \
	-Ilua_libraries \
	-I$(LIBRARIES)/cmsis/CMSIS/Core/Include \
	-I$(LIBRARIES)/littlefs \
	-I$(LIBRARIES)/lua \
	-I$(LIBRARIES)/nrfx \
	-I$(LIBRARIES)/nrfx/drivers/include \
	-I$(LIBRARIES)/nrfx/hal \
	-I$(LIBRARIES)/nrfx/mdk \
	-I$(LIBRARIES)/nrfx/soc \
	-I$(LIBRARIES)/picolibc \
	-I$(LIBRARIES)/segger \
	-I$(LIBRARIES)/softdevice/include \

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
	-DBUILD_VERSION='"$(BUILD_VERSION)"' \
	-DGIT_COMMIT='"$(GIT_COMMIT)"' \
	-DLFS_NO_DEBUG \
	-DLFS_NO_ERROR \
	-DLFS_NO_WARN \
	-DNDEBUG \
	-DNRF52840_XXAA \

# Linker options
FLAGS += \
	-Wl,--gc-sections \

# Linker script paths
FLAGS += \
	-T ../memory_layout.ld \
	-T section_layout.ld \
	-L$(LIBRARIES)/picolibc \

# Link required libraries
LINKED_LIBRARIES += \
	-lc \
	-lgcc \

$(BUILD)/application.hex: $(C_FILES) ../fpga/fpga_application.h
	@mkdir -p $(BUILD)
	@arm-none-eabi-gcc $(FLAGS) -o $(BUILD)/application.elf $(C_FILES) $(LINKED_LIBRARIES)
	@arm-none-eabi-objcopy -O ihex $(BUILD)/application.elf $(BUILD)/application.hex
	@arm-none-eabi-size $(BUILD)/application.elf