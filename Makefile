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

BUILD := build

# Automatically assign Black Magic port depending if MacOS or Linux
ifeq ($(shell uname), Darwin)
	PORT = $(shell ls /dev/cu.usbmodem*1 2> /dev/null | grep "cu.")
else
	PORT = /dev/ttyACM0
endif

application: 
	@make -C source/application

bootloader:
	@make -C source/application
	@make -C source/bootloader
	@make settings-hex-zip

settings-hex-zip:
	@echo Building settings file...
	@rm -f $(BUILD)/frame-firmware-*

	@nrfutil settings generate \
		--family NRF52840 \
		--application $(BUILD)/application.hex \
		--application-version 0 \
		--bootloader-version 0 \
		--bl-settings-version 2 \
		$(BUILD)/settings.hex
	@echo Settings file built

	@echo Building DFU package...
	@mergehex \
	    -m $(BUILD)/settings.hex \
		   $(BUILD)/application.hex \
		   source/bootloader/*.hex \
		   libraries/softdevice/*.hex \
		-o $(BUILD)/frame-firmware-$(BUILD_VERSION).hex

	@nrfutil pkg generate \
		--hw-version 52 \
		--application-version 0 \
		--application $(BUILD)/application.hex \
		--sd-req 0x0123 \
		--key-file source/bootloader/dfu_private_key.pem \
		$(BUILD)/frame-firmware-$(BUILD_VERSION).zip
	@echo DFU package built

release:
	@echo Releasing...
	@make clean
	@make application
	@make settings-hex-zip
	@echo Released

clean:
	@rm -rf $(BUILD)
	@echo Cleaned

flash-jlink:
	@nrfutil device program \
		--options reset=RESET_HARD \
		--firmware $(BUILD)/frame-firmware-*.hex

flash-blackmagic:
	@echo Flashing...
	@arm-none-eabi-gdb -nx \
					   --batch-silent \
					   -ex "target extended-remote $(PORT)" \
					   -ex "monitor swd_scan" \
					   -ex "attach 1" \
					   -ex "monitor erase_mass" \
					   -ex "detach" \
					   -ex 'monitor swd_scan' \
					   -ex 'attach 1' \
					   -ex 'load' \
					   -ex 'compare-sections' \
					   -ex 'kill' \
					   $(BUILD)/frame-firmware-v*.hex \
					   2> /dev/null
	@echo Flashed

erase-jlink:
	@nrfutil device recover

erase-blackmagic:
	@arm-none-eabi-gdb -nx \
					   --batch-silent \
					   -ex "target extended-remote $(PORT)" \
					   -ex "monitor swd_scan" \
					   -ex "attach 1" \
					   -ex "monitor erase_mass" \
					   -ex "detach" \
					   -ex "monitor swd_scan" \
					   -ex "attach 1" \
					   -ex "monitor erase_mass" \
					   2> /dev/null
	@echo Erased

.PHONY: all clean release flash-jlink flash-blackmagic erase-jlink erase-blackmagic
