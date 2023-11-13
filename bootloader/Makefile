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

# Source files
C_FILES += \
	../libraries/nrf5sdk/atomic_fifo/nrf_atfifo.c \
	../libraries/nrf5sdk/atomic/nrf_atomic.c \
	../libraries/nrf5sdk/balloc/nrf_balloc.c \
	../libraries/nrf5sdk/ble/common/ble_srv_common.c \
	../libraries/nrf5sdk/bootloader/ble_dfu/nrf_dfu_ble.c \
	../libraries/nrf5sdk/bootloader/dfu/dfu-cc.pb.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_flash.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_handling_error.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_mbr.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_req_handler.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_settings_svci.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_settings.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_svci_handler.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_svci.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_transport.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_utils.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_validation.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu_ver_validation.c \
	../libraries/nrf5sdk/bootloader/dfu/nrf_dfu.c \
	../libraries/nrf5sdk/bootloader/nrf_bootloader_app_start_final.c \
	../libraries/nrf5sdk/bootloader/nrf_bootloader_app_start.c \
	../libraries/nrf5sdk/bootloader/nrf_bootloader_dfu_timers.c \
	../libraries/nrf5sdk/bootloader/nrf_bootloader_fw_activation.c \
	../libraries/nrf5sdk/bootloader/nrf_bootloader_info.c \
	../libraries/nrf5sdk/bootloader/nrf_bootloader_wdt.c \
	../libraries/nrf5sdk/bootloader/nrf_bootloader.c \
	../libraries/nrf5sdk/crc32/crc32.c \
	../libraries/nrf5sdk/crypto/backend/micro_ecc/micro_ecc_backend_ecc.c \
	../libraries/nrf5sdk/crypto/backend/micro_ecc/micro_ecc_backend_ecdsa.c \
	../libraries/nrf5sdk/crypto/backend/nrf_sw/nrf_sw_backend_hash.c \
	../libraries/nrf5sdk/crypto/nrf_crypto_ecc.c \
	../libraries/nrf5sdk/crypto/nrf_crypto_ecdsa.c \
	../libraries/nrf5sdk/crypto/nrf_crypto_hash.c \
	../libraries/nrf5sdk/crypto/nrf_crypto_init.c \
	../libraries/nrf5sdk/crypto/nrf_crypto_shared.c \
	../libraries/nrf5sdk/experimental_section_vars/nrf_section_iter.c \
	../libraries/nrf5sdk/fstorage/nrf_fstorage_nvmc.c \
	../libraries/nrf5sdk/fstorage/nrf_fstorage_sd.c \
	../libraries/nrf5sdk/fstorage/nrf_fstorage.c \
	../libraries/nrf5sdk/hal/nrf_nvmc.c \
	../libraries/nrf5sdk/mem_manager/mem_manager.c \
	../libraries/nrf5sdk/memobj/nrf_memobj.c \
	../libraries/nrf5sdk/nano-pb/pb_common.c \
	../libraries/nrf5sdk/nano-pb/pb_decode.c \
	../libraries/nrf5sdk/queue/nrf_queue.c \
	../libraries/nrf5sdk/ringbuf/nrf_ringbuf.c \
	../libraries/nrf5sdk/scheduler/app_scheduler.c \
	../libraries/nrf5sdk/sha256/sha256.c \
	../libraries/nrf5sdk/softdevice/common/nrf_sdh_ble.c \
	../libraries/nrf5sdk/softdevice/common/nrf_sdh_soc.c \
	../libraries/nrf5sdk/softdevice/common/nrf_sdh.c \
	../libraries/nrf5sdk/strerror/nrf_strerror.c \
	../libraries/nrf5sdk/svc/nrf_svc_handler.c \
	../libraries/nrf5sdk/util/app_error_weak.c \
	../libraries/nrf5sdk/util/app_util_platform.c \
	../libraries/nrf5sdk/util/nrf_assert.c \
	../libraries/nrfx/mdk/system_nrf52840.c \
	../libraries/nrfx/soc/nrfx_atomic.c \
	../libraries/segger/SEGGER_RTT.c \
	../source/error_logging.c \
	../source/startup.c \
	../source/syscalls.c \
	dfu_public_key.c \
	main.c \

# Header file paths
FLAGS += \
	-I. \
	-I../libraries/cmsis/CMSIS/Core/Include \
	-I../libraries/nrf5sdk/atomic \
	-I../libraries/nrf5sdk/atomic_fifo \
	-I../libraries/nrf5sdk/balloc \
	-I../libraries/nrf5sdk/ble/common \
	-I../libraries/nrf5sdk/boards \
	-I../libraries/nrf5sdk/bootloader \
	-I../libraries/nrf5sdk/bootloader/ble_dfu \
	-I../libraries/nrf5sdk/bootloader/dfu \
	-I../libraries/nrf5sdk/crc32 \
	-I../libraries/nrf5sdk/crypto \
	-I../libraries/nrf5sdk/crypto/backend/cc310 \
	-I../libraries/nrf5sdk/crypto/backend/cc310_bl \
	-I../libraries/nrf5sdk/crypto/backend/cifra \
	-I../libraries/nrf5sdk/crypto/backend/mbedtls \
	-I../libraries/nrf5sdk/crypto/backend/micro_ecc \
	-I../libraries/nrf5sdk/crypto/backend/nrf_hw \
	-I../libraries/nrf5sdk/crypto/backend/nrf_sw \
	-I../libraries/nrf5sdk/crypto/backend/oberon \
	-I../libraries/nrf5sdk/crypto/backend/optiga \
	-I../libraries/nrf5sdk/delay \
	-I../libraries/nrf5sdk/experimental_section_vars \
	-I../libraries/nrf5sdk/fstorage \
	-I../libraries/nrf5sdk/hal \
	-I../libraries/nrf5sdk/log \
	-I../libraries/nrf5sdk/log/src \
	-I../libraries/nrf5sdk/micro-ecc/micro-ecc \
	-I../libraries/nrf5sdk/mem_manager \
	-I../libraries/nrf5sdk/memobj \
	-I../libraries/nrf5sdk/mutex \
	-I../libraries/nrf5sdk/nano-pb \
	-I../libraries/nrf5sdk/queue \
	-I../libraries/nrf5sdk/ringbuf \
	-I../libraries/nrf5sdk/scheduler \
	-I../libraries/nrf5sdk/sha256 \
	-I../libraries/nrf5sdk/softdevice/common \
	-I../libraries/nrf5sdk/stack_info \
	-I../libraries/nrf5sdk/strerror \
	-I../libraries/nrf5sdk/svc \
	-I../libraries/nrf5sdk/util \
	-I../libraries/nrfx \
	-I../libraries/nrfx/drivers/include \
	-I../libraries/nrfx/hal \
	-I../libraries/nrfx/mdk \
	-I../libraries/nrfx/soc \
	-I../libraries/picolibc \
	-I../libraries/segger \
	-I../libraries/softdevice/include \
	-I../libraries/softdevice/include/nrf52 \
	-I../source \

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

# Linker options
FLAGS += \
	-Wl,--gc-sections \

# Linker script paths
FLAGS += \
	-T linker.ld \
	-L../libraries/picolibc \

# Link required libraries
LIBS += \
	-lc \
	-lgcc \
  	../libraries/nrf5sdk/micro-ecc/nrf52hf_armgcc/armgcc/micro_ecc_lib_nrf52.a \


../build/bootloader.hex: $(C_FILES)
	@mkdir -p ../build
	@arm-none-eabi-gcc $(FLAGS) -o ../build/bootloader.elf $(C_FILES) $(LIBS)
	@arm-none-eabi-objcopy -O ihex ../build/bootloader.elf ../build/bootloader.hex
	@arm-none-eabi-size ../build/bootloader.elf

regenerate_keys:
	nrfutil keys generate dfu_private_key.pem
	nrfutil keys display \
		--key pk \
		--format code \
		dfu_private_key.pem \
		--out_file dfu_public_key.c

clean:
	rm -rf ../build/