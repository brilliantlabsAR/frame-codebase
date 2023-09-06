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

# Source files
APPLICATION_CORE_C_FILES += application_core/main.c
APPLICATION_CORE_C_FILES += nrfx/drivers/src/nrfx_gpiote.c
APPLICATION_CORE_C_FILES += nrfx/drivers/src/nrfx_qspi.c
APPLICATION_CORE_C_FILES += nrfx/drivers/src/nrfx_systick.c
APPLICATION_CORE_C_FILES += nrfx/mdk/gcc_startup_nrf5340_application.S
APPLICATION_CORE_C_FILES += nrfx/mdk/system_nrf5340_application.c

# Header file paths
APPLICATION_CORE_FLAGS += -Iapplication_core

# Build options and optimizations
APPLICATION_CORE_FLAGS += -mcpu=cortex-m33
APPLICATION_CORE_FLAGS += -mfloat-abi=hard
APPLICATION_CORE_FLAGS += -mfpu=fpv4-sp-d16

# Preprocessor defines
APPLICATION_CORE_FLAGS += -DNRF5340_XXAA_APPLICATION

# Linker script path
APPLICATION_CORE_FLAGS += -Lnrfx/mdk -T nrfx/mdk/nrf5340_xxaa_application.ld

build/application_core.elf: $(SHARED_C_FILES) $(APPLICATION_CORE_C_FILES)
	@mkdir -p build
	@arm-none-eabi-gcc $(SHARED_FLAGS) $(APPLICATION_CORE_FLAGS) -o $@ $^
	@arm-none-eabi-size $@