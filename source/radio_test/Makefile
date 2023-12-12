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

PRINT_USAGE := Usage is `make FREQUENCY=2402|2404|...|2478|2480 POWER=8|7|6|5|4|3|2|0|-4|-8|-12|-16`

$(if $(filter $(FREQUENCY), 2402 2404 2406 2408 2410 2412 2414 2416 2418 2420 2422 2424 2426 2428 2430 2432 2434 2436 2438 2440 2442 2444 2446 2448 2450 2452 2454 2456 2458 2460 2462 2464 2466 2468 2470 2472 2474 2476 2478 2480),,\
	$(error invalid value for FREQUENCY.\
	$(PRINT_USAGE)))

$(if $(filter $(POWER), 8 7 6 5 4 3 2 0 -4 -8 -12 -16),,\
	$(error invalid value for POWER.\
	$(PRINT_USAGE)))

# Source files
C_FILES += \
	main.c \
	radio_test.c \
	../error_logging.c \
	../i2c.c \
	../startup.c \
	../syscalls.c \
	$(LIBRARIES)/nrf5sdk/util/app_util_platform.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_gpiote.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_systick.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_timer.c \
	$(LIBRARIES)/nrfx/drivers/src/nrfx_twim.c \
	$(LIBRARIES)/nrfx/helpers/nrfx_flag32_allocator.c \
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
	-DTEST_FREQUENCY=$(FREQUENCY) \
	-DTEST_POWER=$(POWER) \

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

default:
	@rm -rf $(BUILD)
	@mkdir -p $(BUILD)
	@arm-none-eabi-gcc $(FLAGS) -o $(BUILD)/radio_test.elf $(C_FILES) $(LINKED_LIBRARIES)
	@arm-none-eabi-objcopy -O ihex $(BUILD)/radio_test.elf $(BUILD)/radio_test.hex
	@arm-none-eabi-size $(BUILD)/radio_test.elf

	@nrfutil settings generate \
		--family NRF52840 \
		--application $(BUILD)/radio_test.hex \
		--application-version 0 \
		--bootloader-version 0 \
		--bl-settings-version 2 \
		$(BUILD)/settings.hex

	@mergehex \
	    -m $(BUILD)/settings.hex \
		   $(BUILD)/radio_test.hex \
		   ../bootloader/*.hex \
		   ../../libraries/softdevice/*.hex \
		-o $(BUILD)/radio_test_$(FREQUENCY)Mhz_$(POWER)dBm.hex

	@nrfutil pkg generate \
		--hw-version 52 \
		--application-version 0 \
		--application $(BUILD)/radio_test.hex \
		--sd-req 0x0123 \
		--key-file ../bootloader/dfu_private_key.pem \
		$(BUILD)/radio_test_$(FREQUENCY)Mhz_$(POWER)dBm.zip

flash: default
	@nrfutil device program \
	--options reset=RESET_HARD \
	--firmware $(BUILD)/radio_test_*.hex