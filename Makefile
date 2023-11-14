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

all: $(BUILD)/application.hex \
	 $(BUILD)/bootloader.hex \
	 source/fpga/fpga_application.h

$(BUILD)/application.hex:
	@make -C source/application

$(BUILD)/bootloader.hex:
	@make -C source/bootloader

source/fpga/fpga_application.h:
	@make -C source/fpga

clean:
	@rm -rf $(BUILD)

release:
	@rm -rf $(BUILD)

	@make

	@nrfutil settings generate \
		--family NRF52 \
		--application build/application.hex \
		--application-version 0 \
		--bootloader-version 0 \
		--bl-settings-version 2 \
		build/settings.hex

	@mergehex \
		-m \
		build/settings.hex \
		build/application.hex \
		libraries/softdevice/*.hex \
		build/bootloader.hex \
		-o build/frame-firmware-$(BUILD_VERSION).hex

	@nrfutil pkg generate \
		--hw-version 52 \
		--application-version 0 \
		--application build/application.hex \
		--sd-req 0x0123 \
		--key-file bootloader/dfu_private_key.pem \
		build/frame-firmware-$(BUILD_VERSION).zip

flash:
	@make release
	nrfjprog -q --program build/frame-firmware-*.hex --chiperase
	nrfjprog --reset

recover:
	nrfjprog --recover

.PHONY: all clean release flash recover
