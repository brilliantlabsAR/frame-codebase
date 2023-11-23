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
	radio_test.c \
	../error_logging.c \
	../startup.c \
	../syscalls.c \
	$(LIBRARIES)/nrf5sdk/util/app_util_platform.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_timer.c \
	$(LIBRARIES)/nrfx/mdk/system_nrf52840.c \
	$(LIBRARIES)/segger/SEGGER_RTT.c \

# Header file paths
FLAGS += \
	-I. \
	-I.. \
	-I$(LIBRARIES)/cmsis/CMSIS/Core/Include \
	-I$(LIBRARIES)/nrf5sdk/util \
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
	-DNDEBUG \
	-DNRF52840_XXAA \

# Linker options
FLAGS += \
	-Wl,--gc-sections \

# Linker script paths
FLAGS += \
	-T memory_layout.ld \
	-L$(LIBRARIES)/picolibc \

# Link required libraries
LINKED_LIBRARIES += \
	-lc \
	-lgcc \

$(BUILD)/radio_test.hex: $(C_FILES)
	@mkdir -p $(BUILD)
	@arm-none-eabi-gcc $(FLAGS) -o $(BUILD)/radio_test.elf $(C_FILES) $(LINKED_LIBRARIES)
	@arm-none-eabi-objcopy -O ihex $(BUILD)/radio_test.elf $(BUILD)/radio_test.hex
	@arm-none-eabi-size $(BUILD)/radio_test.elf

flash: $(BUILD)/radio_test.hex
	@nrfutil device program \
	--options reset=RESET_HARD \
	--firmware $(BUILD)/radio_test.hex