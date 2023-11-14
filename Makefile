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

all: 
	@make -C source/fpga
	@make -C source/application
	@make -C source/bootloader

clean:
	@rm -rf $(BUILD)

release:
	@rm -rf $(BUILD)

	@make

	@nrfutil settings generate \
		--family NRF52840 \
		--application $(BUILD)/application.hex \
		--application-version 0 \
		--bootloader-version 0 \
		--bl-settings-version 2 \
		$(BUILD)/settings.hex

	@mergehex \
	    -m $(BUILD)/settings.hex \
		   $(BUILD)/application.hex \
		   $(BUILD)/bootloader.hex \
		   libraries/softdevice/*.hex \
		-o $(BUILD)/frame-firmware-$(BUILD_VERSION).hex

	@nrfutil pkg generate \
		--hw-version 52 \
		--application-version 0 \
		--application $(BUILD)/application.hex \
		--sd-req 0x0123 \
		--key-file source/bootloader/dfu_private_key.pem \
		$(BUILD)/frame-firmware-$(BUILD_VERSION).zip

flash:
	@nrfutil device program \
		--options reset=RESET_HARD \
		--firmware $(BUILD)/frame-firmware-*.hex

recover:
	@nrfutil device recover

.PHONY: all clean release flash recover
