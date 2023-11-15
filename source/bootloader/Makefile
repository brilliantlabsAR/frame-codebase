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
	dfu_public_key.c \
	../error_logging.c \
	../startup.c \
	../syscalls.c \
	$(LIBRARIES)/nrf5sdk/atomic_fifo/nrf_atfifo.c \
	$(LIBRARIES)/nrf5sdk/atomic/nrf_atomic.c \
	$(LIBRARIES)/nrf5sdk/balloc/nrf_balloc.c \
	$(LIBRARIES)/nrf5sdk/ble/common/ble_srv_common.c \
	$(LIBRARIES)/nrf5sdk/bootloader/ble_dfu/nrf_dfu_ble.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/dfu-cc.pb.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_flash.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_handling_error.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_mbr.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_req_handler.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_settings_svci.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_settings.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_svci_handler.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_svci.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_transport.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_utils.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_validation.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu_ver_validation.c \
	$(LIBRARIES)/nrf5sdk/bootloader/dfu/nrf_dfu.c \
	$(LIBRARIES)/nrf5sdk/bootloader/nrf_bootloader_app_start_final.c \
	$(LIBRARIES)/nrf5sdk/bootloader/nrf_bootloader_app_start.c \
	$(LIBRARIES)/nrf5sdk/bootloader/nrf_bootloader_dfu_timers.c \
	$(LIBRARIES)/nrf5sdk/bootloader/nrf_bootloader_fw_activation.c \
	$(LIBRARIES)/nrf5sdk/bootloader/nrf_bootloader_info.c \
	$(LIBRARIES)/nrf5sdk/bootloader/nrf_bootloader_wdt.c \
	$(LIBRARIES)/nrf5sdk/bootloader/nrf_bootloader.c \
	$(LIBRARIES)/nrf5sdk/crc32/crc32.c \
	$(LIBRARIES)/nrf5sdk/crypto/backend/micro_ecc/micro_ecc_backend_ecc.c \
	$(LIBRARIES)/nrf5sdk/crypto/backend/micro_ecc/micro_ecc_backend_ecdsa.c \
	$(LIBRARIES)/nrf5sdk/crypto/backend/nrf_sw/nrf_sw_backend_hash.c \
	$(LIBRARIES)/nrf5sdk/crypto/nrf_crypto_ecc.c \
	$(LIBRARIES)/nrf5sdk/crypto/nrf_crypto_ecdsa.c \
	$(LIBRARIES)/nrf5sdk/crypto/nrf_crypto_hash.c \
	$(LIBRARIES)/nrf5sdk/crypto/nrf_crypto_init.c \
	$(LIBRARIES)/nrf5sdk/crypto/nrf_crypto_shared.c \
	$(LIBRARIES)/nrf5sdk/experimental_section_vars/nrf_section_iter.c \
	$(LIBRARIES)/nrf5sdk/fstorage/nrf_fstorage_nvmc.c \
	$(LIBRARIES)/nrf5sdk/fstorage/nrf_fstorage_sd.c \
	$(LIBRARIES)/nrf5sdk/fstorage/nrf_fstorage.c \
	$(LIBRARIES)/nrf5sdk/hal/nrf_nvmc.c \
	$(LIBRARIES)/nrf5sdk/mem_manager/mem_manager.c \
	$(LIBRARIES)/nrf5sdk/memobj/nrf_memobj.c \
	$(LIBRARIES)/nrf5sdk/nano-pb/pb_common.c \
	$(LIBRARIES)/nrf5sdk/nano-pb/pb_decode.c \
	$(LIBRARIES)/nrf5sdk/queue/nrf_queue.c \
	$(LIBRARIES)/nrf5sdk/ringbuf/nrf_ringbuf.c \
	$(LIBRARIES)/nrf5sdk/scheduler/app_scheduler.c \
	$(LIBRARIES)/nrf5sdk/sha256/sha256.c \
	$(LIBRARIES)/nrf5sdk/softdevice/common/nrf_sdh_ble.c \
	$(LIBRARIES)/nrf5sdk/softdevice/common/nrf_sdh_soc.c \
	$(LIBRARIES)/nrf5sdk/softdevice/common/nrf_sdh.c \
	$(LIBRARIES)/nrf5sdk/strerror/nrf_strerror.c \
	$(LIBRARIES)/nrf5sdk/svc/nrf_svc_handler.c \
	$(LIBRARIES)/nrf5sdk/util/app_util_platform.c \
	$(LIBRARIES)/nrf5sdk/util/nrf_assert.c \
	$(LIBRARIES)/nrfx/mdk/system_nrf52840.c \
	$(LIBRARIES)/nrfx/soc/nrfx_atomic.c \
	$(LIBRARIES)/segger/SEGGER_RTT.c \

# Header file paths
FLAGS += \
	-I. \
	-I.. \
	-I$(LIBRARIES)/cmsis/CMSIS/Core/Include \
	-I$(LIBRARIES)/nrf5sdk/atomic \
	-I$(LIBRARIES)/nrf5sdk/atomic_fifo \
	-I$(LIBRARIES)/nrf5sdk/balloc \
	-I$(LIBRARIES)/nrf5sdk/ble/common \
	-I$(LIBRARIES)/nrf5sdk/boards \
	-I$(LIBRARIES)/nrf5sdk/bootloader \
	-I$(LIBRARIES)/nrf5sdk/bootloader/ble_dfu \
	-I$(LIBRARIES)/nrf5sdk/bootloader/dfu \
	-I$(LIBRARIES)/nrf5sdk/crc32 \
	-I$(LIBRARIES)/nrf5sdk/crypto \
	-I$(LIBRARIES)/nrf5sdk/crypto/backend/cc310 \
	-I$(LIBRARIES)/nrf5sdk/crypto/backend/cc310_bl \
	-I$(LIBRARIES)/nrf5sdk/crypto/backend/cifra \
	-I$(LIBRARIES)/nrf5sdk/crypto/backend/mbedtls \
	-I$(LIBRARIES)/nrf5sdk/crypto/backend/micro_ecc \
	-I$(LIBRARIES)/nrf5sdk/crypto/backend/nrf_hw \
	-I$(LIBRARIES)/nrf5sdk/crypto/backend/nrf_sw \
	-I$(LIBRARIES)/nrf5sdk/crypto/backend/oberon \
	-I$(LIBRARIES)/nrf5sdk/crypto/backend/optiga \
	-I$(LIBRARIES)/nrf5sdk/delay \
	-I$(LIBRARIES)/nrf5sdk/experimental_section_vars \
	-I$(LIBRARIES)/nrf5sdk/fstorage \
	-I$(LIBRARIES)/nrf5sdk/hal \
	-I$(LIBRARIES)/nrf5sdk/log \
	-I$(LIBRARIES)/nrf5sdk/log/src \
	-I$(LIBRARIES)/nrf5sdk/mem_manager \
	-I$(LIBRARIES)/nrf5sdk/memobj \
	-I$(LIBRARIES)/nrf5sdk/micro-ecc/micro-ecc \
	-I$(LIBRARIES)/nrf5sdk/mutex \
	-I$(LIBRARIES)/nrf5sdk/nano-pb \
	-I$(LIBRARIES)/nrf5sdk/queue \
	-I$(LIBRARIES)/nrf5sdk/ringbuf \
	-I$(LIBRARIES)/nrf5sdk/scheduler \
	-I$(LIBRARIES)/nrf5sdk/sha256 \
	-I$(LIBRARIES)/nrf5sdk/softdevice/common \
	-I$(LIBRARIES)/nrf5sdk/stack_info \
	-I$(LIBRARIES)/nrf5sdk/strerror \
	-I$(LIBRARIES)/nrf5sdk/svc \
	-I$(LIBRARIES)/nrf5sdk/util \
	-I$(LIBRARIES)/nrfx \
	-I$(LIBRARIES)/nrfx/drivers/include \
	-I$(LIBRARIES)/nrfx/hal \
	-I$(LIBRARIES)/nrfx/mdk \
	-I$(LIBRARIES)/nrfx/soc \
	-I$(LIBRARIES)/picolibc \
	-I$(LIBRARIES)/segger \
	-I$(LIBRARIES)/softdevice/include \
	-I$(LIBRARIES)/softdevice/include/nrf52 \

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
	-Os \
	-std=gnu17 \

# Preprocessor defines
FLAGS += \
	-DBLE_STACK_SUPPORT_REQD \
	-DBOARD_PCA10056 \
	-DBUILD_VERSION='"$(BUILD_VERSION)"' \
	-DGIT_COMMIT='"$(GIT_COMMIT)"' \
	-DNDEBUG \
	-DNRF_DFU_SETTINGS_VERSION=2 \
	-DNRF52840_XXAA \
	-DSOFTDEVICE_PRESENT \
	-DuECC_ENABLE_VLI_API=0 \
	-DuECC_OPTIMIZATION_LEVEL=3 \
	-DuECC_SQUARE_FUNC=0 \
	-DuECC_SUPPORT_COMPRESSED_POINT=0 \
	-DuECC_VLI_NATIVE_LITTLE_ENDIAN=1 \

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
  	$(LIBRARIES)/nrf5sdk/micro-ecc/nrf52hf_armgcc/armgcc/micro_ecc_lib_nrf52.a \

$(BUILD)/bootloader.hex: $(C_FILES)
	@mkdir -p $(BUILD)
	@arm-none-eabi-gcc $(FLAGS) -o $(BUILD)/bootloader.elf $(C_FILES) $(LINKED_LIBRARIES)
	@arm-none-eabi-objcopy -O ihex $(BUILD)/bootloader.elf $(BUILD)/bootloader.hex
	@arm-none-eabi-size $(BUILD)/bootloader.elf

regenerate_keys:
	@nrfutil keys generate dfu_private_key.pem
	@nrfutil keys display \
		--key pk \
		--format code \
		dfu_private_key.pem \
		--out_file dfu_public_key.c

.PHONY: regenerate_keys
